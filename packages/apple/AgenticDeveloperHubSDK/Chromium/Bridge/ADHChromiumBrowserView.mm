//
//  ADHChromiumBrowserView.mm
//  AgenticDeveloperHubSDKChromium
//
//  One Chromium browser, parented to an NSView with CEF's Alloy windowed
//  style: Chromium makes a child view of this one and draws into it. The C++
//  client below is every CEF handler the pane needs, and it reports to the
//  view, which reports to its Objective-C delegate. Every handler but the
//  cookie filter runs on CEF's UI thread, which on macOS is the main thread;
//  the cookie filter runs on the network thread and reads only an atomic.
//

#import "ADHChromiumBrowserView.h"
#import "ADHChromiumPrivate.h"

#include <algorithm>
#include <cmath>
#include <map>

#include "include/cef_browser.h"
#include "include/cef_client.h"
#include "include/cef_devtools_message_observer.h"
#include "include/cef_request_context.h"
#include "include/cef_request_context_handler.h"

namespace {

NSString* ADHString(const CefString& value) {
  std::string utf8 = value.ToString();
  return [[NSString alloc] initWithBytes:utf8.data() length:utf8.size() encoding:NSUTF8StringEncoding] ?: @"";
}

constexpr int kInspectElementCommand = MENU_ID_USER_FIRST;

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
                         public CefDevToolsMessageObserver {
 public:
  explicit ADHBrowserClient(ADHChromiumBrowserView* view) : view_(view) {}

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
    return ADHChromiumRuntime.shared.acceptsCookies;
  }

  bool CanSaveCookie(CefRefPtr<CefBrowser> /*browser*/,
                     CefRefPtr<CefFrame> /*frame*/,
                     CefRefPtr<CefRequest> /*request*/,
                     CefRefPtr<CefResponse> /*response*/,
                     const CefCookie& /*cookie*/) override {
    return ADHChromiumRuntime.shared.acceptsCookies;
  }

  // MARK: DevTools protocol

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
}

- (instancetype)initWithFrame:(NSRect)frame options:(ADHChromiumBrowserOptions*)options {
  if ((self = [super initWithFrame:frame])) {
    _options = options;
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
  _client = new ADHBrowserClient(self);

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

  CefRefPtr<CefRequestContext> context;
  if (_options.privateBrowsing) {
    // An empty cache path keeps everything in memory, gone with the context.
    CefRequestContextSettings contextSettings;
    context = CefRequestContext::CreateContext(contextSettings, nullptr);
  }

  [ADHChromiumRuntime.shared browserDidOpen];
  if (!CefBrowserHost::CreateBrowser(windowInfo, _client, CefString(), settings, nullptr, context)) {
    [ADHChromiumRuntime.shared browserDidClose];
    _creating = NO;
    _client = nullptr;
    [self failPendingWithDescription:@"Chromium could not create a browser"];
  }
}

- (void)browserDidOpen:(CefRefPtr<CefBrowser>)browser {
  _creating = NO;
  if (_closed) {
    browser->GetHost()->CloseBrowser(true);
    return;
  }
  _browser = browser;
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
  [self failPendingWithDescription:@"The Chrome pane closed"];
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
  if (_closed) {
    completion(nil, [self errorWithDescription:@"The Chrome pane closed"]);
    return;
  }
  int messageID = _nextMessageID++;
  NSDictionary* message = @{@"id" : @(messageID), @"method" : method, @"params" : params ?: @{}};
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
  ADHDevToolsCompletion completion = _completions[@(messageID)];
  if (!completion) {
    return;
  }
  [_completions removeObjectForKey:@(messageID)];
  id object = payload.length > 0 ? [NSJSONSerialization JSONObjectWithData:payload options:0 error:nil] : @{};
  NSDictionary* body = [object isKindOfClass:NSDictionary.class] ? object : @{};
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
