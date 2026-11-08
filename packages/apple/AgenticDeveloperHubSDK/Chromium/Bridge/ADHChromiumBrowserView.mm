//
//  ADHChromiumBrowserView.mm
//  AgenticDeveloperHubSDKChromium
//
//  One Chromium browser, parented to an NSView with CEF's Alloy windowed
//  style: Chromium makes a child view of this one and draws into it. The C++
//  client below is every CEF handler the pane needs, and it reports to the
//  view, which reports to its Objective-C delegate. Every handler but the
//  cookie filter and the resource filter runs on CEF's UI thread, which on
//  macOS is the main thread; those two run on the network thread and read
//  only atomics.
//

#import "ADHChromiumBrowserView.h"
#import "ADHChromiumPrivate.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <cmath>
#include <map>
#include <memory>
#include <mutex>
#include <string>

#include "include/cef_browser.h"
#include "include/cef_client.h"
#include "include/cef_devtools_message_observer.h"
#include "include/cef_request_context.h"
#include "include/cef_request_context_handler.h"

#import <objc/runtime.h>

namespace {

// MARK: Text input gate

/// The browser view holding `view`, if any.
ADHChromiumBrowserView* ADHOwningBrowserView(NSView* view) {
  for (NSView* ancestor = view.superview; ancestor; ancestor = ancestor.superview) {
    if ([ancestor isKindOfClass:[ADHChromiumBrowserView class]]) {
      return (ADHChromiumBrowserView*)ancestor;
    }
  }
  return nil;
}

/// Whether `view`'s pane lets `selector` through; a view outside any pane
/// (DevTools, say) always does.
bool ADHAllowsTextInput(NSView* view, SEL selector) {
  ADHChromiumBrowserView* owner = ADHOwningBrowserView(view);
  id<ADHChromiumBrowserViewDelegate> delegate = owner.delegate;
  if (!delegate) {
    return true;
  }
  return [delegate chromiumBrowserView:owner shouldPerformTextInput:NSStringFromSelector(selector)];
}

/// Wraps the text-input and editing methods of Chromium's page view, so the
/// keyboard gate holds what arrives without a key event — Dictation, the
/// Emoji & Symbols picker, an input method, an Edit menu item — and what the
/// main menu sends back when a refused Command key is passed on to it, on any
/// keyboard layout. The key monitor in front of the page cannot see any of
/// these. Done once, for the class; each call asks the pane it belongs to.
void ADHInstallTextInputGate(void) {
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    Class cls = NSClassFromString(@"RenderWidgetHostViewCocoa");
    if (!cls) {
      NSLog(@"Chromium: no RenderWidgetHostViewCocoa; text input outside key events is not gated");
      return;
    }
    auto wrapObject = ^(SEL selector) {
      Method method = class_getInstanceMethod(cls, selector);
      if (!method) {
        return;
      }
      typedef void (*IMP1)(id, SEL, id);
      IMP1 original = reinterpret_cast<IMP1>(method_getImplementation(method));
      IMP wrapped = imp_implementationWithBlock(^(NSView* view, id argument) {
        if (ADHAllowsTextInput(view, selector)) {
          original(view, selector, argument);
        }
      });
      class_replaceMethod(cls, selector, wrapped, method_getTypeEncoding(method));
    };
    for (NSString* name in @[ @"insertText:", @"paste:", @"pasteAndMatchStyle:", @"cut:", @"copy:",
                              @"selectAll:", @"undo:", @"redo:", @"delete:" ]) {
      wrapObject(NSSelectorFromString(name));
    }

    SEL insert = @selector(insertText:replacementRange:);
    if (Method method = class_getInstanceMethod(cls, insert)) {
      typedef void (*InsertIMP)(id, SEL, id, NSRange);
      InsertIMP original = reinterpret_cast<InsertIMP>(method_getImplementation(method));
      IMP wrapped = imp_implementationWithBlock(^(NSView* view, id text, NSRange replacement) {
        if (ADHAllowsTextInput(view, insert)) {
          original(view, insert, text, replacement);
        }
      });
      class_replaceMethod(cls, insert, wrapped, method_getTypeEncoding(method));
    }

    SEL mark = @selector(setMarkedText:selectedRange:replacementRange:);
    if (Method method = class_getInstanceMethod(cls, mark)) {
      typedef void (*MarkIMP)(id, SEL, id, NSRange, NSRange);
      MarkIMP original = reinterpret_cast<MarkIMP>(method_getImplementation(method));
      IMP wrapped = imp_implementationWithBlock(^(NSView* view, id text, NSRange selected, NSRange replacement) {
        if (ADHAllowsTextInput(view, mark)) {
          original(view, mark, text, selected, replacement);
        }
      });
      class_replaceMethod(cls, mark, wrapped, method_getTypeEncoding(method));
    }
  });
}

NSString* ADHString(const CefString& value) {
  std::string utf8 = value.ToString();
  return [[NSString alloc] initWithBytes:utf8.data() length:utf8.size() encoding:NSUTF8StringEncoding] ?: @"";
}

constexpr int kInspectElementCommand = MENU_ID_USER_FIRST;

/// The host of a URL, lowercased; empty when it has none.
std::string ADHHost(const std::string& url) {
  size_t start = url.find("://");
  if (start == std::string::npos) {
    return std::string();
  }
  start += 3;
  size_t end = url.find_first_of("/?#", start);
  std::string authority = url.substr(start, end == std::string::npos ? std::string::npos : end - start);
  size_t at = authority.rfind('@');
  if (at != std::string::npos) {
    authority = authority.substr(at + 1);
  }
  if (!authority.empty() && authority.front() == '[') {
    size_t close = authority.find(']');
    authority = authority.substr(0, close == std::string::npos ? std::string::npos : close + 1);
  } else {
    size_t colon = authority.find(':');
    if (colon != std::string::npos) {
      authority = authority.substr(0, colon);
    }
  }
  std::transform(authority.begin(), authority.end(), authority.begin(),
                 [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
  return authority;
}

/// Whether `host` belongs to `site`, a registrable domain as Chromium's own
/// public-suffix list reduced it (the host of a request's first party for
/// cookies): the site itself or any name under it. Exact, because the site
/// is already an eTLD+1, so a name ending in `.site` cannot belong to any
/// other; an IP literal matches only itself.
bool ADHHostIsInSite(const std::string& host, const std::string& site) {
  if (host == site) {
    return true;
  }
  if (site.empty() || host.size() <= site.size() + 1) {
    return false;
  }
  const size_t dot = host.size() - site.size() - 1;
  return host[dot] == '.' && host.compare(dot + 1, std::string::npos, site) == 0;
}

/// The Third-Party Content decision for one pane, shared by its client (the
/// requests a browser carries) and its request context's handler (worker
/// requests, which carry none). Called on CEF's IO thread.
class ADHThirdPartyFilter {
 public:
  explicit ADHThirdPartyFilter(ADHChromiumThirdPartyBlocking blocking) : blocking_(static_cast<int>(blocking)) {}

  void SetBlocking(ADHChromiumThirdPartyBlocking blocking) { blocking_.store(static_cast<int>(blocking)); }

  cef_return_value_t Decide(CefRefPtr<CefRequest> request) {
    const int blocking = blocking_.load();
    const cef_resource_type_t type = request->GetResourceType();
    // A document load is never refused, the way WebKit's rules never block
    // the page itself. Its site is remembered for the requests that arrive
    // with no first party of their own.
    if (type == RT_MAIN_FRAME) {
      std::string site = ADHHost(request->GetFirstPartyForCookies().ToString());
      if (site.empty()) {
        site = ADHHost(request->GetURL().ToString());
      }
      std::lock_guard<std::mutex> lock(mutex_);
      topSite_ = site;
      return RV_CONTINUE;
    }
    if (blocking == ADHChromiumThirdPartyBlockingNone || type == RT_NAVIGATION_PRELOAD_MAIN_FRAME) {
      return RV_CONTINUE;
    }
    if (blocking == ADHChromiumThirdPartyBlockingScripts && type != RT_SCRIPT && type != RT_WORKER &&
        type != RT_SHARED_WORKER && type != RT_SERVICE_WORKER) {
      return RV_CONTINUE;
    }
    const std::string resource = ADHHost(request->GetURL().ToString());
    if (resource.empty()) {
      return RV_CONTINUE;  // data:, blob: and the like come from the page itself
    }
    // The first party for cookies is already scheme plus eTLD+1, so the
    // resource is compared against it as it stands, never re-derived. A
    // cross-site or sandboxed frame's requests carry a null one; they are
    // judged against the top document's site, as WebKit judges every load
    // against the main document. With neither known, the load is refused:
    // a filter that cannot tell must not fail open.
    std::string page = ADHHost(request->GetFirstPartyForCookies().ToString());
    if (page.empty()) {
      std::lock_guard<std::mutex> lock(mutex_);
      page = topSite_;
    }
    if (!page.empty() && ADHHostIsInSite(resource, page)) {
      return RV_CONTINUE;
    }
    return RV_CANCEL;
  }

 private:
  std::atomic<int> blocking_;
  std::mutex mutex_;
  std::string topSite_;
};

/// A pane's request context handler. Worker requests (service and shared
/// workers) have no browser, so they never reach the client's resource
/// handler; they come here and meet the same filter. CEF gives such a request
/// to any handler among the contexts sharing its storage, so in a jar several
/// panes share, a worker is judged by one of those panes' settings.
class ADHRequestContextHandler : public CefRequestContextHandler, public CefResourceRequestHandler {
 public:
  explicit ADHRequestContextHandler(std::shared_ptr<ADHThirdPartyFilter> filter) : filter_(std::move(filter)) {}

  CefRefPtr<CefResourceRequestHandler> GetResourceRequestHandler(CefRefPtr<CefBrowser> browser,
                                                                 CefRefPtr<CefFrame> /*frame*/,
                                                                 CefRefPtr<CefRequest> /*request*/,
                                                                 bool /*is_navigation*/,
                                                                 bool /*is_download*/,
                                                                 const CefString& /*request_initiator*/,
                                                                 bool& /*disable_default_handling*/) override {
    // A request with a browser is the client's; it never gets here anyway.
    return browser ? nullptr : this;
  }

  ReturnValue OnBeforeResourceLoad(CefRefPtr<CefBrowser> /*browser*/,
                                   CefRefPtr<CefFrame> /*frame*/,
                                   CefRefPtr<CefRequest> request,
                                   CefRefPtr<CefCallback> /*callback*/) override {
    return filter_->Decide(request);
  }

 private:
  std::shared_ptr<ADHThirdPartyFilter> filter_;
  IMPLEMENT_REFCOUNTING(ADHRequestContextHandler);
};

}  // namespace

/// What the client hands back to the view. Declared here, not in the
/// header: these are the C++ side's calls, not the view's API.
@interface ADHChromiumBrowserView ()
- (void)browserDidOpen:(CefRefPtr<CefBrowser>)browser;
- (void)browserDidClose;
- (void)addressDidChange:(NSString*)address;
- (void)titleDidChange:(NSString*)title;
- (void)loadingStateDidChange:(BOOL)isLoading canGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward;
- (void)mainFrameDidStartLoad;
- (void)mainFrameDidFinishLoad;
- (void)mainFrameDidFailWithMessage:(NSString*)message address:(NSString*)address;
- (void)consoleText:(NSString*)text level:(NSString*)level;
- (void)dialog:(ADHChromiumDialogKind)kind message:(NSString*)message;
- (void)popupForAddress:(NSString*)address userGesture:(BOOL)userGesture;
- (BOOL)destinationForDownloadNamed:(NSString*)name completion:(void (^)(NSString* _Nullable path))completion;
- (BOOL)mediaCaptureForHost:(NSString*)host
                     camera:(BOOL)camera
                 microphone:(BOOL)microphone
                 completion:(void (^)(NSNumber* _Nullable allowed))completion;
- (void)devToolsResult:(int)messageID success:(BOOL)success payload:(NSData*)payload;
- (void)devToolsResult:(int)messageID success:(BOOL)success body:(NSDictionary*)body;
- (void)devToolsEvent:(NSString*)method params:(NSDictionary*)params sessionId:(nullable NSString*)sessionId;
- (void)showDevToolsAtX:(int)x y:(int)y;
@end

// MARK: - The CEF client

namespace {

class ADHBrowserClient : public CefClient,
                         public CefDisplayHandler,
                         public CefLoadHandler,
                         public CefLifeSpanHandler,
                         public CefJSDialogHandler,
                         public CefPermissionHandler,
                         public CefDownloadHandler,
                         public CefContextMenuHandler,
                         public CefRequestHandler,
                         public CefResourceRequestHandler,
                         public CefCookieAccessFilter,
                         public CefDragHandler,
                         public CefDevToolsMessageObserver {
 public:
  ADHBrowserClient(ADHChromiumBrowserView* view, bool acceptsCookies, ADHChromiumThirdPartyBlocking thirdParty)
      : view_(view), acceptsCookies_(acceptsCookies), thirdParty_(std::make_shared<ADHThirdPartyFilter>(thirdParty)) {}

  void SetAcceptsCookies(bool accepts) { acceptsCookies_.store(accepts); }
  void SetThirdPartyBlocking(ADHChromiumThirdPartyBlocking blocking) { thirdParty_->SetBlocking(blocking); }
  /// The filter, for the pane's request context handler to share.
  std::shared_ptr<ADHThirdPartyFilter> ThirdPartyFilter() const { return thirdParty_; }

  /// Drops the view, so a callback still in flight after `close` reports to
  /// nobody.
  void Detach() { view_ = nil; }

  CefRefPtr<CefDisplayHandler> GetDisplayHandler() override { return this; }
  CefRefPtr<CefLoadHandler> GetLoadHandler() override { return this; }
  CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() override { return this; }
  CefRefPtr<CefJSDialogHandler> GetJSDialogHandler() override { return this; }
  CefRefPtr<CefPermissionHandler> GetPermissionHandler() override { return this; }
  CefRefPtr<CefDownloadHandler> GetDownloadHandler() override { return this; }
  CefRefPtr<CefContextMenuHandler> GetContextMenuHandler() override { return this; }
  CefRefPtr<CefRequestHandler> GetRequestHandler() override { return this; }
  CefRefPtr<CefDragHandler> GetDragHandler() override { return this; }

  // MARK: Drag and drop

  bool OnDragEnter(CefRefPtr<CefBrowser> /*browser*/,
                   CefRefPtr<CefDragData> /*dragData*/,
                   DragOperationsMask /*mask*/) override {
    ADHChromiumBrowserView* view = view_;
    id<ADHChromiumBrowserViewDelegate> delegate = view.delegate;
    // True cancels the drag; with no one to ask, the page takes it.
    return delegate ? ![delegate chromiumBrowserViewShouldAcceptDrag:view] : false;
  }

  // MARK: Life span

  void OnAfterCreated(CefRefPtr<CefBrowser> browser) override {
    ADHChromiumBrowserView* view = view_;
    if (!view) {
      // The pane went away while Chromium was still making its browser.
      browser->GetHost()->CloseBrowser(true);
      return;
    }
    [view browserDidOpen:browser];
  }

  /// A pane's browser is a child of the project window. Returning false would
  /// send `performClose:` to that window and close every pane in it, so the
  /// close is finished here instead: taking CEF's child view out of the view
  /// hierarchy is the tear-down CEF waits for before `OnBeforeClose`.
  bool DoClose(CefRefPtr<CefBrowser> browser) override {
    NSView* child = (__bridge NSView*)browser->GetHost()->GetWindowHandle();
    [child removeFromSuperview];
    return true;
  }

  void OnBeforeClose(CefRefPtr<CefBrowser> /*browser*/) override {
    [view_ browserDidClose];
    [ADHChromiumRuntime.shared browserDidClose];
  }

  bool OnBeforePopup(CefRefPtr<CefBrowser> /*browser*/,
                     CefRefPtr<CefFrame> /*frame*/,
                     int /*popup_id*/,
                     const CefString& target_url,
                     const CefString& /*target_frame_name*/,
                     WindowOpenDisposition /*target_disposition*/,
                     bool user_gesture,
                     const CefPopupFeatures& /*popupFeatures*/,
                     CefWindowInfo& /*windowInfo*/,
                     CefRefPtr<CefClient>& /*client*/,
                     CefBrowserSettings& /*settings*/,
                     CefRefPtr<CefDictionaryValue>& /*extra_info*/,
                     bool* /*no_javascript_access*/) override {
    // A pane is one page: no new window opens. The delegate decides whether
    // the address loads in place, the way the Safari pane treats one.
    [view_ popupForAddress:ADHString(target_url) userGesture:user_gesture];
    return true;
  }

  // MARK: Display

  void OnAddressChange(CefRefPtr<CefBrowser> /*browser*/, CefRefPtr<CefFrame> frame, const CefString& url) override {
    if (frame->IsMain()) {
      [view_ addressDidChange:ADHString(url)];
    }
  }

  void OnTitleChange(CefRefPtr<CefBrowser> /*browser*/, const CefString& title) override {
    [view_ titleDidChange:ADHString(title)];
  }

  bool OnConsoleMessage(CefRefPtr<CefBrowser> /*browser*/,
                        cef_log_severity_t level,
                        const CefString& message,
                        const CefString& /*source*/,
                        int /*line*/) override {
    NSString* name = @"log";
    switch (level) {
      case LOGSEVERITY_VERBOSE: name = @"debug"; break;
      case LOGSEVERITY_WARNING: name = @"warn"; break;
      case LOGSEVERITY_ERROR:
      case LOGSEVERITY_FATAL: name = @"error"; break;
      default: break;
    }
    [view_ consoleText:ADHString(message) level:name];
    return true;
  }

  // MARK: Load

  void OnLoadingStateChange(CefRefPtr<CefBrowser> /*browser*/,
                            bool isLoading,
                            bool canGoBack,
                            bool canGoForward) override {
    [view_ loadingStateDidChange:isLoading canGoBack:canGoBack canGoForward:canGoForward];
  }

  void OnLoadStart(CefRefPtr<CefBrowser> /*browser*/, CefRefPtr<CefFrame> frame, TransitionType /*type*/) override {
    if (frame->IsMain()) {
      [view_ mainFrameDidStartLoad];
    }
  }

  void OnLoadEnd(CefRefPtr<CefBrowser> /*browser*/, CefRefPtr<CefFrame> frame, int /*httpStatusCode*/) override {
    if (frame->IsMain()) {
      [view_ mainFrameDidFinishLoad];
    }
  }

  void OnLoadError(CefRefPtr<CefBrowser> /*browser*/,
                   CefRefPtr<CefFrame> frame,
                   ErrorCode errorCode,
                   const CefString& errorText,
                   const CefString& failedUrl) override {
    // ERR_ABORTED is a load the user or the next navigation stopped.
    if (frame->IsMain() && errorCode != ERR_ABORTED) {
      [view_ mainFrameDidFailWithMessage:ADHString(errorText) address:ADHString(failedUrl)];
    }
  }

  // MARK: JavaScript dialogs

  bool OnJSDialog(CefRefPtr<CefBrowser> /*browser*/,
                  const CefString& /*origin_url*/,
                  JSDialogType dialog_type,
                  const CefString& message_text,
                  const CefString& /*default_prompt_text*/,
                  CefRefPtr<CefJSDialogCallback> /*callback*/,
                  bool& suppress_message) override {
    // Suppressed and reported, as the Safari pane does: a page's alert never
    // stops the pane, and a model driving it reads what it said.
    ADHChromiumDialogKind kind = ADHChromiumDialogKindAlert;
    if (dialog_type == JSDIALOGTYPE_CONFIRM) {
      kind = ADHChromiumDialogKindConfirm;
    } else if (dialog_type == JSDIALOGTYPE_PROMPT) {
      kind = ADHChromiumDialogKindPrompt;
    }
    [view_ dialog:kind message:ADHString(message_text)];
    suppress_message = true;
    return false;
  }

  bool OnBeforeUnloadDialog(CefRefPtr<CefBrowser> /*browser*/,
                            const CefString& /*message_text*/,
                            bool /*is_reload*/,
                            CefRefPtr<CefJSDialogCallback> callback) override {
    callback->Continue(true, CefString());
    return true;
  }

  // MARK: Permissions

  bool OnRequestMediaAccessPermission(CefRefPtr<CefBrowser> /*browser*/,
                                      CefRefPtr<CefFrame> /*frame*/,
                                      const CefString& requesting_origin,
                                      uint32_t requested_permissions,
                                      CefRefPtr<CefMediaAccessCallback> callback) override {
    const uint32_t capture = CEF_MEDIA_PERMISSION_DEVICE_AUDIO_CAPTURE | CEF_MEDIA_PERMISSION_DEVICE_VIDEO_CAPTURE;
    const uint32_t wanted = requested_permissions & capture;
    if (wanted == 0) {
      return false;
    }
    NSString* host = [NSURL URLWithString:ADHString(requesting_origin)].host ?: ADHString(requesting_origin);
    return [view_ mediaCaptureForHost:host
                               camera:(wanted & CEF_MEDIA_PERMISSION_DEVICE_VIDEO_CAPTURE) != 0
                           microphone:(wanted & CEF_MEDIA_PERMISSION_DEVICE_AUDIO_CAPTURE) != 0
                           completion:^(NSNumber* allowed) {
                             callback->Continue(allowed.boolValue ? wanted : CEF_MEDIA_PERMISSION_NONE);
                           }];
  }

  // MARK: Downloads

  bool OnBeforeDownload(CefRefPtr<CefBrowser> /*browser*/,
                        CefRefPtr<CefDownloadItem> /*download_item*/,
                        const CefString& suggested_name,
                        CefRefPtr<CefBeforeDownloadCallback> callback) override {
    // A callback dropped without being run cancels the download, which is
    // what a refused one should do.
    __block CefRefPtr<CefBeforeDownloadCallback> pending = callback;
    return [view_ destinationForDownloadNamed:ADHString(suggested_name)
                                   completion:^(NSString* path) {
                                     if (path) {
                                       pending->Continue(path.UTF8String, false);
                                     }
                                     pending = nullptr;
                                   }];
  }

  // MARK: Context menu

  void OnBeforeContextMenu(CefRefPtr<CefBrowser> /*browser*/,
                           CefRefPtr<CefFrame> /*frame*/,
                           CefRefPtr<CefContextMenuParams> /*params*/,
                           CefRefPtr<CefMenuModel> model) override {
    if (view_.allowsDevTools) {
      if (model->GetCount() > 0) {
        model->AddSeparator();
      }
      model->AddItem(kInspectElementCommand, "Inspect Element");
    }
  }

  bool OnContextMenuCommand(CefRefPtr<CefBrowser> /*browser*/,
                            CefRefPtr<CefFrame> /*frame*/,
                            CefRefPtr<CefContextMenuParams> params,
                            int command_id,
                            EventFlags /*event_flags*/) override {
    if (command_id != kInspectElementCommand) {
      return false;
    }
    [view_ showDevToolsAtX:params->GetXCoord() y:params->GetYCoord()];
    return true;
  }

  // MARK: Third-party content

  ReturnValue OnBeforeResourceLoad(CefRefPtr<CefBrowser> /*browser*/,
                                   CefRefPtr<CefFrame> /*frame*/,
                                   CefRefPtr<CefRequest> request,
                                   CefRefPtr<CefCallback> /*callback*/) override {
    return thirdParty_->Decide(request);
  }

  // MARK: Cookies

  CefRefPtr<CefResourceRequestHandler> GetResourceRequestHandler(CefRefPtr<CefBrowser> /*browser*/,
                                                                 CefRefPtr<CefFrame> /*frame*/,
                                                                 CefRefPtr<CefRequest> /*request*/,
                                                                 bool /*is_navigation*/,
                                                                 bool /*is_download*/,
                                                                 const CefString& /*request_initiator*/,
                                                                 bool& /*disable_default_handling*/) override {
    return this;
  }

  CefRefPtr<CefCookieAccessFilter> GetCookieAccessFilter(CefRefPtr<CefBrowser> /*browser*/,
                                                         CefRefPtr<CefFrame> /*frame*/,
                                                         CefRefPtr<CefRequest> /*request*/) override {
    return this;
  }

  bool CanSendCookie(CefRefPtr<CefBrowser> /*browser*/,
                     CefRefPtr<CefFrame> /*frame*/,
                     CefRefPtr<CefRequest> /*request*/,
                     const CefCookie& /*cookie*/) override {
    return acceptsCookies_.load();
  }

  bool CanSaveCookie(CefRefPtr<CefBrowser> /*browser*/,
                     CefRefPtr<CefFrame> /*frame*/,
                     CefRefPtr<CefRequest> /*request*/,
                     CefRefPtr<CefResponse> /*response*/,
                     const CefCookie& /*cookie*/) override {
    return acceptsCookies_.load();
  }

  // MARK: DevTools protocol

  /// Every message, read here once so an event keeps its `sessionId`, which
  /// `OnDevToolsEvent` drops: an attached frame's events carry it at the top
  /// level. A message that does not parse is left to CEF.
  bool OnDevToolsMessage(CefRefPtr<CefBrowser> /*browser*/, const void* message, size_t message_size) override {
    NSData* data = [NSData dataWithBytesNoCopy:const_cast<void*>(message) length:message_size freeWhenDone:NO];
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![object isKindOfClass:NSDictionary.class]) {
      return false;
    }
    NSDictionary* body = object;
    NSString* session = [body[@"sessionId"] isKindOfClass:NSString.class] ? body[@"sessionId"] : nil;
    if ([body[@"id"] isKindOfClass:NSNumber.class]) {
      NSDictionary* error = [body[@"error"] isKindOfClass:NSDictionary.class] ? body[@"error"] : nil;
      NSDictionary* result = [body[@"result"] isKindOfClass:NSDictionary.class] ? body[@"result"] : @{};
      [view_ devToolsResult:[body[@"id"] intValue] success:error == nil body:error ?: result];
      return true;
    }
    if ([body[@"method"] isKindOfClass:NSString.class]) {
      NSDictionary* params = [body[@"params"] isKindOfClass:NSDictionary.class] ? body[@"params"] : @{};
      [view_ devToolsEvent:body[@"method"] params:params sessionId:session];
      return true;
    }
    return false;
  }

  void OnDevToolsMethodResult(CefRefPtr<CefBrowser> /*browser*/,
                              int message_id,
                              bool success,
                              const void* result,
                              size_t result_size) override {
    NSData* payload = [NSData dataWithBytes:result length:result_size];
    [view_ devToolsResult:message_id success:success payload:payload];
  }

 private:
  __weak ADHChromiumBrowserView* view_;
  std::atomic<bool> acceptsCookies_;
  std::shared_ptr<ADHThirdPartyFilter> thirdParty_;
  IMPLEMENT_REFCOUNTING(ADHBrowserClient);
};

}  // namespace

// MARK: - Options

@implementation ADHChromiumBrowserOptions
@end

// MARK: - The view

typedef void (^ADHDevToolsCompletion)(NSDictionary<NSString*, id>* _Nullable, NSError* _Nullable);

@implementation ADHChromiumBrowserView {
  ADHChromiumBrowserOptions* _options;
  CefRefPtr<ADHBrowserClient> _client;
  CefRefPtr<CefBrowser> _browser;
  CefRefPtr<CefRegistration> _devToolsRegistration;
  NSString* _pendingAddress;
  /// DevTools messages sent before the browser existed, in order.
  NSMutableArray<NSData*>* _queuedMessages;
  NSMutableDictionary<NSNumber*, ADHDevToolsCompletion>* _completions;
  int _nextMessageID;
  double _zoomFactor;
  BOOL _creating;
  BOOL _closed;
  /// Self, held while Chromium creates the browser: `SetAsChild` takes the
  /// parent unretained, and creation finishes on a later turn of the loop,
  /// so a pane closed in between would otherwise hand CEF a freed view.
  ADHChromiumBrowserView* _retainedWhileCreating;
  /// The view was made first responder before its browser existed; the
  /// focus goes to the page when it arrives.
  BOOL _wantsFocus;
}

- (instancetype)initWithFrame:(NSRect)frame options:(ADHChromiumBrowserOptions*)options {
  if ((self = [super initWithFrame:frame])) {
    _options = options;
    _acceptsCookies = options.acceptsCookies;
    _queuedMessages = [NSMutableArray array];
    _completions = [NSMutableDictionary dictionary];
    _nextMessageID = 1;
    _zoomFactor = 1.0;
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(runtimeWillShutdown:)
                                               name:ADHChromiumRuntimeWillShutdownNotification
                                             object:nil];
  }
  return self;
}

- (void)dealloc {
  [NSNotificationCenter.defaultCenter removeObserver:self];
  [self close];
}

- (BOOL)isFlipped {
  return YES;
}

- (BOOL)hasBrowser {
  return _browser != nullptr;
}

// MARK: Focus

/// The view the page draws into, and takes keys in: CEF's child of this one.
- (nullable NSView*)pageView {
  return _browser ? (__bridge NSView*)_browser->GetHost()->GetWindowHandle() : nil;
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

/// A host that focuses this view means the page: the focus is passed on to
/// CEF's child view, on the next turn so this one finishes becoming first
/// responder first, or held until the browser exists.
- (BOOL)becomeFirstResponder {
  if (!self.pageView) {
    _wantsFocus = YES;
    return YES;
  }
  dispatch_async(dispatch_get_main_queue(), ^{ [self focusPageIfFirstResponder]; });
  return YES;
}

- (void)focusPageIfFirstResponder {
  _wantsFocus = NO;
  NSView* page = self.pageView;
  if (!page || self.window.firstResponder != self) {
    return;
  }
  [self.window makeFirstResponder:page];
  _browser->GetHost()->SetFocus(true);
}

// MARK: Creation

- (void)viewDidMoveToWindow {
  [super viewDidMoveToWindow];
  [self createBrowserIfReady];
}

- (void)createBrowserIfReady {
  if (!self.window || _browser || _creating || _closed || !ADHChromiumRuntime.shared.isRunning) {
    return;
  }
  _creating = YES;
  _retainedWhileCreating = self;
  _client = new ADHBrowserClient(self, _acceptsCookies, _thirdPartyBlocking);

  NSRect bounds = self.bounds;
  CefWindowInfo windowInfo;
  windowInfo.SetAsChild((__bridge CefWindowHandle)self,
                        CefRect(0, 0, static_cast<int>(NSWidth(bounds)), static_cast<int>(NSHeight(bounds))));

  CefBrowserSettings settings;
  if (_options.minimumFontSize > 0) {
    settings.minimum_font_size = static_cast<int>(_options.minimumFontSize);
  }
  NSColor* background = [_options.backgroundColor colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
  if (background) {
    auto channel = [](CGFloat value) { return static_cast<int>(std::lround(std::clamp(value, 0.0, 1.0) * 255)); };
    settings.background_color =
        CefColorSetARGB(255, channel(background.redComponent), channel(background.greenComponent),
                        channel(background.blueComponent));
  }

  // nil shares the global context's storage; an empty cache path keeps
  // everything in memory, gone with the context; a path is a profile of the
  // pane's own. Every pane gets a context of its own all the same, carrying
  // the handler that filters its worker requests.
  CefRefPtr<CefRequestContextHandler> contextHandler = new ADHRequestContextHandler(_client->ThirdPartyFilter());
  CefRefPtr<CefRequestContext> context;
  if (_options.cachePath) {
    CefRequestContextSettings contextSettings;
    if (_options.cachePath.length > 0) {
      [NSFileManager.defaultManager createDirectoryAtPath:_options.cachePath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
      CefString(&contextSettings.cache_path) = _options.cachePath.UTF8String;
      contextSettings.persist_session_cookies = true;
    }
    context = CefRequestContext::CreateContext(contextSettings, contextHandler);
  } else {
    context = CefRequestContext::CreateContext(CefRequestContext::GetGlobalContext(), contextHandler);
  }
  ADHApplyCookiePolicy(context, _acceptsCookies);

  [ADHChromiumRuntime.shared browserDidOpen];
  if (!CefBrowserHost::CreateBrowser(windowInfo, _client, CefString(), settings, nullptr, context)) {
    [ADHChromiumRuntime.shared browserDidClose];
    _creating = NO;
    _retainedWhileCreating = nil;
    _client = nullptr;
    [self failPendingWithDescription:@"Chromium could not create a browser"];
  }
}

- (void)browserDidOpen:(CefRefPtr<CefBrowser>)browser {
  _creating = NO;
  // Released at the end of this method, not here: the view may be closing.
  ADHChromiumBrowserView* retained = _retainedWhileCreating;
  _retainedWhileCreating = nil;
  (void)retained;
  if (_closed) {
    browser->GetHost()->CloseBrowser(true);
    _client->Detach();
    return;
  }
  _browser = browser;
  ADHInstallTextInputGate();
  NSView* child = (__bridge NSView*)browser->GetHost()->GetWindowHandle();
  child.frame = self.bounds;
  child.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;

  _devToolsRegistration = browser->GetHost()->AddDevToolsMessageObserver(_client);
  NSArray<NSData*>* queued = [_queuedMessages copy];
  [_queuedMessages removeAllObjects];
  for (NSData* message in queued) {
    [self sendDevToolsMessage:message];
  }
  [self applyZoom];
  if (_wantsFocus) {
    [self focusPageIfFirstResponder];
  }
  if (_pendingAddress) {
    NSString* address = _pendingAddress;
    _pendingAddress = nil;
    browser->GetMainFrame()->LoadURL(address.UTF8String);
  }
}

- (void)browserDidClose {
  _devToolsRegistration = nullptr;
  _browser = nullptr;
  _creating = NO;
  _retainedWhileCreating = nil;
  [self failPendingWithDescription:@"The Chrome pane closed"];
}

// MARK: Privacy

- (void)setAcceptsCookies:(BOOL)acceptsCookies {
  _acceptsCookies = acceptsCookies;
  if (_client) {
    _client->SetAcceptsCookies(acceptsCookies);
  }
  if (_browser) {
    ADHApplyCookiePolicy(_browser->GetHost()->GetRequestContext(), acceptsCookies);
  }
}

- (void)setThirdPartyBlocking:(ADHChromiumThirdPartyBlocking)thirdPartyBlocking {
  _thirdPartyBlocking = thirdPartyBlocking;
  if (_client) {
    _client->SetThirdPartyBlocking(thirdPartyBlocking);
  }
}

// MARK: Navigation

- (void)loadAddress:(NSString*)address {
  if (_browser) {
    _browser->GetMainFrame()->LoadURL(address.UTF8String);
  } else {
    _pendingAddress = [address copy];
    [self createBrowserIfReady];
  }
}

- (void)goBack {
  if (_browser) {
    _browser->GoBack();
  }
}

- (void)goForward {
  if (_browser) {
    _browser->GoForward();
  }
}

- (void)reload {
  if (_browser) {
    _browser->Reload();
  }
}

- (void)stopLoading {
  if (_browser) {
    _browser->StopLoad();
  }
}

- (void)setZoomFactor:(double)factor {
  _zoomFactor = factor > 0 ? factor : 1.0;
  [self applyZoom];
}

/// Chromium's zoom level is a power of 1.2: level 1 is 120%.
- (void)applyZoom {
  if (_browser) {
    _browser->GetHost()->SetZoomLevel(std::log(_zoomFactor) / std::log(1.2));
  }
}

// MARK: DevTools

- (void)showDevTools {
  [self showDevToolsAtX:0 y:0];
}

- (void)showDevToolsAtX:(int)x y:(int)y {
  if (!_browser) {
    return;
  }
  CefWindowInfo windowInfo;
  _browser->GetHost()->ShowDevTools(windowInfo, nullptr, CefBrowserSettings(), CefPoint(x, y));
}

- (void)sendDevToolsMethod:(NSString*)method
                    params:(NSDictionary<NSString*, id>*)params
                completion:(ADHDevToolsCompletion)completion {
  [self sendDevToolsMethod:method params:params sessionId:nil completion:completion];
}

- (void)sendDevToolsMethod:(NSString*)method
                    params:(NSDictionary<NSString*, id>*)params
                 sessionId:(NSString*)sessionId
                completion:(ADHDevToolsCompletion)completion {
  if (_closed) {
    completion(nil, [self errorWithDescription:@"The Chrome pane closed"]);
    return;
  }
  int messageID = _nextMessageID++;
  NSMutableDictionary* message =
      [@{@"id" : @(messageID), @"method" : method, @"params" : params ?: @{}} mutableCopy];
  if (sessionId) {
    message[@"sessionId"] = sessionId;
  }
  NSError* encodingError;
  NSData* data = [NSJSONSerialization dataWithJSONObject:message options:0 error:&encodingError];
  if (!data) {
    completion(nil, encodingError);
    return;
  }
  _completions[@(messageID)] = [completion copy];
  if (_browser) {
    [self sendDevToolsMessage:data];
  } else {
    [_queuedMessages addObject:data];
    [self createBrowserIfReady];
  }
}

- (void)sendDevToolsMessage:(NSData*)data {
  if (_browser->GetHost()->SendDevToolsMessage(data.bytes, data.length)) {
    return;
  }
  NSDictionary* message = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
  NSNumber* messageID = message[@"id"];
  ADHDevToolsCompletion completion = _completions[messageID];
  [_completions removeObjectForKey:messageID];
  if (completion) {
    completion(nil, [self errorWithDescription:@"Chromium refused the DevTools message"]);
  }
}

- (void)devToolsResult:(int)messageID success:(BOOL)success payload:(NSData*)payload {
  id object = payload.length > 0 ? [NSJSONSerialization JSONObjectWithData:payload options:0 error:nil] : @{};
  [self devToolsResult:messageID success:success body:[object isKindOfClass:NSDictionary.class] ? object : @{}];
}

- (void)devToolsEvent:(NSString*)method params:(NSDictionary*)params sessionId:(NSString*)sessionId {
  [_delegate chromiumBrowserView:self didReceiveDevToolsEvent:method params:params sessionId:sessionId];
}

- (void)devToolsResult:(int)messageID success:(BOOL)success body:(NSDictionary*)body {
  ADHDevToolsCompletion completion = _completions[@(messageID)];
  if (!completion) {
    return;
  }
  [_completions removeObjectForKey:@(messageID)];
  if (success) {
    completion(body, nil);
  } else {
    NSString* text = [body[@"message"] isKindOfClass:NSString.class] ? body[@"message"] : @"DevTools method failed";
    completion(nil, [self errorWithDescription:text]);
  }
}

- (NSError*)errorWithDescription:(NSString*)description {
  return [NSError errorWithDomain:ADHChromiumErrorDomain code:2 userInfo:@{NSLocalizedDescriptionKey : description}];
}

- (void)failPendingWithDescription:(NSString*)description {
  NSDictionary<NSNumber*, ADHDevToolsCompletion>* pending = [_completions copy];
  [_completions removeAllObjects];
  [_queuedMessages removeAllObjects];
  NSError* error = [self errorWithDescription:description];
  for (NSNumber* key in pending) {
    pending[key](nil, error);
  }
}

// MARK: Closing

- (void)runtimeWillShutdown:(NSNotification*)notification {
  [self close];
}

- (void)close {
  if (_closed) {
    return;
  }
  _closed = YES;
  _delegate = nil;
  [self failPendingWithDescription:@"The Chrome pane closed"];
  CefRefPtr<CefBrowser> browser = _browser;
  _devToolsRegistration = nullptr;
  if (browser) {
    browser->GetHost()->CloseBrowser(true);
  }
  // A browser still being created is closed when it arrives, in
  // `browserDidOpen:`; the client stays attached until then.
  if (!_creating && _client) {
    _client->Detach();
  }
}

// MARK: Reports from the client

- (void)addressDidChange:(NSString*)address {
  _address = [address copy];
  [_delegate chromiumBrowserViewAddressDidChange:self];
}

- (void)titleDidChange:(NSString*)title {
  _pageTitle = [title copy];
  [_delegate chromiumBrowserViewTitleDidChange:self];
}

- (void)loadingStateDidChange:(BOOL)isLoading canGoBack:(BOOL)canGoBack canGoForward:(BOOL)canGoForward {
  _isLoading = isLoading;
  _canGoBack = canGoBack;
  _canGoForward = canGoForward;
  [_delegate chromiumBrowserViewLoadingStateDidChange:self];
}

- (void)mainFrameDidStartLoad {
  // Chromium keeps zoom per host; this pane keeps one zoom for every page.
  [self applyZoom];
  [_delegate chromiumBrowserViewDidStartMainFrameLoad:self];
}

- (void)mainFrameDidFinishLoad {
  [_delegate chromiumBrowserViewDidFinishMainFrameLoad:self];
}

- (void)mainFrameDidFailWithMessage:(NSString*)message address:(NSString*)address {
  [_delegate chromiumBrowserView:self didFailLoadWithMessage:message address:address];
}

- (void)consoleText:(NSString*)text level:(NSString*)level {
  [_delegate chromiumBrowserView:self didLogConsoleText:text level:level];
}

- (void)dialog:(ADHChromiumDialogKind)kind message:(NSString*)message {
  [_delegate chromiumBrowserView:self didRaiseDialog:kind message:message];
}

- (void)popupForAddress:(NSString*)address userGesture:(BOOL)userGesture {
  [_delegate chromiumBrowserView:self didRequestPopupForAddress:address userGesture:userGesture];
}

- (BOOL)destinationForDownloadNamed:(NSString*)name completion:(void (^)(NSString* _Nullable))completion {
  id<ADHChromiumBrowserViewDelegate> delegate = _delegate;
  if (!delegate) {
    return NO;
  }
  [delegate chromiumBrowserView:self destinationForDownloadNamed:name completion:completion];
  return YES;
}

- (BOOL)mediaCaptureForHost:(NSString*)host
                     camera:(BOOL)camera
                 microphone:(BOOL)microphone
                 completion:(void (^)(NSNumber* _Nullable))completion {
  id<ADHChromiumBrowserViewDelegate> delegate = _delegate;
  if (!delegate) {
    return NO;
  }
  [delegate chromiumBrowserView:self
      allowsMediaCaptureForHost:host
                         camera:camera
                     microphone:microphone
                     completion:completion];
  return YES;
}

@end
