//
//  ADHChromiumBrowserView.mm
//  AgenticDeveloperHubSDKChromium
//
//  One Chrome-style Chromium browser, in a frameless CEF Views window that a
//  tracker keeps over this view as a child of its window (Alloy style, the
//  only kind CEF parents to an NSView, has no Chrome toolbar and no
//  extensions). The C++ client below is every CEF handler the pane needs, and it reports to the
//  view, which reports to its Objective-C delegate. Every handler but the
//  cookie filter and the resource filter runs on CEF's UI thread, which on
//  macOS is the main thread; those two run on the network thread and read
//  only atomics.
//

#import "ADHChromiumBrowserView.h"
#import "ADHChromiumPrivate.h"
#import "ADHChromeViewsHost.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <cmath>
#include <functional>
#include <map>
#include <memory>
#include <mutex>
#include <string>

#include "include/cef_browser.h"
#include "include/cef_client.h"
#include "include/cef_command_handler.h"
#include "include/cef_command_ids.h"
#include "include/cef_keyboard_handler.h"
#include "include/cef_devtools_message_observer.h"
#include "include/cef_request_context.h"
#include "include/cef_request_context_handler.h"

#import <objc/runtime.h>

namespace {

// MARK: Text input gate

/// The browser view holding `view`, if any: an ancestor, or the pane whose
/// Chrome window `view` is in.
ADHChromiumBrowserView* ADHOwningBrowserView(NSView* view) {
  for (NSView* ancestor = view.superview; ancestor; ancestor = ancestor.superview) {
    if ([ancestor isKindOfClass:[ADHChromiumBrowserView class]]) {
      return (ADHChromiumBrowserView*)ancestor;
    }
  }
  NSWindow* window = view.window;
  return window ? ADHBrowserViewOwningWindow(window) : nil;
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

/// Wraps the text-input and editing methods of `cls`, so the keyboard gate
/// holds what arrives without a key event. Each call asks the pane the view
/// belongs to.
void ADHGateTextInputOfClass(Class cls) {
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
}

/// Gates the text-input and editing methods of Chromium's page view, so the
/// keyboard gate holds what arrives without a key event — Dictation, the
/// Emoji & Symbols picker, an input method, an Edit menu item — and what the
/// main menu sends back when a refused Command key is passed on to it, on any
/// keyboard layout. The key monitor in front of the page cannot see any of
/// these. Only the page is gated: Chrome's toolbar and omnibox (the Views
/// content view, `BridgedContentView`) are the pane's address bar and chrome,
/// which the pane keeps working while it is paused. Done once per class.
void ADHInstallTextInputGate(void) {
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    for (NSString* name in @[ @"RenderWidgetHostViewCocoa" ]) {
      Class cls = NSClassFromString(name);
      if (!cls) {
        NSLog(@"Chromium: no %@; its text input outside key events is not gated", name);
        continue;
      }
      ADHGateTextInputOfClass(cls);
    }
  });
}

NSString* ADHString(const CefString& value) {
  std::string utf8 = value.ToString();
  return [[NSString alloc] initWithBytes:utf8.data() length:utf8.size() encoding:NSUTF8StringEncoding] ?: @"";
}

constexpr int kInspectElementCommand = MENU_ID_USER_FIRST;

/// Chrome's commands that open DevTools, from its menus, its context menu
/// and its shortcuts. The pane's Allow developer tools setting gates them.
bool ADHIsDevToolsCommand(int command_id) {
  switch (command_id) {
    case IDC_DEV_TOOLS:
    case IDC_DEV_TOOLS_CONSOLE:
    case IDC_DEV_TOOLS_DEVICES:
    case IDC_DEV_TOOLS_INSPECT:
    case IDC_DEV_TOOLS_TOGGLE:
    case IDC_CONTENT_CONTEXT_INSPECTELEMENT:
    case IDC_CONTENT_CONTEXT_INSPECTELEMENT_WITH_DEVTOOLS:
    case IDC_CONTENT_CONTEXT_INSPECTBACKGROUNDPAGE:
      return true;
    default:
      return false;
  }
}

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
  using Initialized = std::function<void(CefRefPtr<CefRequestContext>)>;

  ADHRequestContextHandler(std::shared_ptr<ADHThirdPartyFilter> filter, Initialized initialized)
      : filter_(std::move(filter)), initialized_(std::move(initialized)) {}

  /// A Chrome browser view can be created only in an initialized context,
  /// and a new context finishes initializing on a later turn of the loop.
  void OnRequestContextInitialized(CefRefPtr<CefRequestContext> request_context) override {
    Initialized initialized = std::move(initialized_);
    initialized_ = nullptr;
    if (initialized) {
      initialized(request_context);
    }
  }

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
  Initialized initialized_;
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
- (CefRefPtr<CefClient>)openPopupForAddress:(NSString*)address
                                 userGesture:(BOOL)userGesture
                                    settings:(CefBrowserSettings&)settings;
- (BOOL)isCreatingBrowser;
- (void)popupCreationDidAbort;
- (void)popupDidAbort:(ADHChromiumBrowserView*)popup;
- (BOOL)destinationForDownloadNamed:(NSString*)name completion:(void (^)(NSString* _Nullable path))completion;
- (BOOL)mediaCaptureForHost:(NSString*)host
                     camera:(BOOL)camera
                 microphone:(BOOL)microphone
                 completion:(void (^)(NSNumber* _Nullable allowed))completion;
- (void)devToolsResult:(int)messageID success:(BOOL)success payload:(NSData*)payload;
- (void)devToolsResult:(int)messageID success:(BOOL)success body:(NSDictionary*)body;
- (void)devToolsEvent:(NSString*)method params:(NSDictionary*)params sessionId:(nullable NSString*)sessionId;
- (void)showDevToolsAtX:(int)x y:(int)y;
- (nullable NSString*)refusalForNavigationTo:(NSString*)address;
- (void)openTabForAddress:(NSString*)address
             offTheRecord:(BOOL)offTheRecord
               background:(BOOL)background
              userGesture:(BOOL)userGesture;
@end

// MARK: - The CEF client

namespace {

/// Command-T, -N, -Shift-N, -W, -Q and -comma: Chrome's new tab, new window,
/// new incognito window, close tab, quit and settings, each of which is the
/// Kitchen's in a pane. Matched on the key's character with modifiers
/// ignored, so a layout that moves the key still matches the menu's reading.
///
/// Only a key-down can be one. Chromium reports a modifier pressed on its
/// own (an `NSEventTypeFlagsChanged` event) as a raw key-down too, and
/// `charactersIgnoringModifiers` throws on any event that is not a key
/// event, which took the app down.
bool ADHIsKitchenShortcut(NSEvent* event) {
  if (event.type != NSEventTypeKeyDown) {
    return false;
  }
  const NSEventModifierFlags flags =
      event.modifierFlags & (NSEventModifierFlagCommand | NSEventModifierFlagShift | NSEventModifierFlagOption |
                             NSEventModifierFlagControl);
  NSString* key = event.charactersIgnoringModifiers.lowercaseString;
  if (flags == NSEventModifierFlagCommand) {
    return [@[ @"t", @"n", @"w", @"q", @"," ] containsObject:key];
  }
  return flags == (NSEventModifierFlagCommand | NSEventModifierFlagShift) && [key isEqualToString:@"n"];
}

}  // namespace

namespace {

/// The client of a pane's DevTools browser, however it was opened (the
/// Kitchen's Inspect Element, Chrome's menu, its context menu or its
/// shortcut). CEF would otherwise give DevTools the inspected page's client,
/// whose `OnAfterCreated` makes the view adopt DevTools as its page and whose
/// `OnBeforeClose` closes the tab when DevTools closes. This one only counts
/// the browser while it lives, so shutdown waits for it; DevTools stays in
/// the default Chrome window CEF makes for it.
class ADHDevToolsClient : public CefClient, public CefLifeSpanHandler {
 public:
  CefRefPtr<CefLifeSpanHandler> GetLifeSpanHandler() override { return this; }

  void OnAfterCreated(CefRefPtr<CefBrowser> /*browser*/) override { [ADHChromiumRuntime.shared browserDidOpen]; }

  bool DoClose(CefRefPtr<CefBrowser> /*browser*/) override { return false; }

  void OnBeforeClose(CefRefPtr<CefBrowser> /*browser*/) override { [ADHChromiumRuntime.shared browserDidClose]; }

 private:
  IMPLEMENT_REFCOUNTING(ADHDevToolsClient);
};

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
                         public CefCommandHandler,
                         public CefKeyboardHandler,
                         public CefDevToolsMessageObserver {
 public:
  ADHBrowserClient(ADHChromiumBrowserView* view,
                   bool acceptsCookies,
                   ADHChromiumThirdPartyBlocking thirdParty,
                   bool isPrivate)
      : view_(view),
        acceptsCookies_(acceptsCookies),
        thirdParty_(std::make_shared<ADHThirdPartyFilter>(thirdParty)),
        isPrivate_(isPrivate),
        pendingPopups_([NSMapTable strongToWeakObjectsMapTable]) {}

  /// The view this client reports to; nil once detached.
  ADHChromiumBrowserView* View() const { return view_; }

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
  CefRefPtr<CefCommandHandler> GetCommandHandler() override { return this; }
  CefRefPtr<CefKeyboardHandler> GetKeyboardHandler() override { return this; }

  // MARK: Chrome's menu

  /// The app-menu items a pane does not have: a pane is one page, so no new
  /// tab or window; its settings, history, downloads and passwords are the
  /// Kitchen's; it is never signed in to a Google profile; and quitting or
  /// closing is the Kitchen's to do. A private pane has no extensions, and
  /// DevTools is there only while the pane allows developer tools.
  bool IsHiddenCommand(int command_id) const {
    if (ADHIsDevToolsCommand(command_id)) {
      return !view_.allowsDevTools;
    }
    switch (command_id) {
      case IDC_NEW_TAB:
      case IDC_NEW_WINDOW:
      case IDC_NEW_INCOGNITO_WINDOW:
      case IDC_NEW_TAB_TO_RIGHT:
      case IDC_NEW_SPLIT_TAB:
      case IDC_RESTORE_TAB:
      case IDC_RECENT_TABS_MENU:
      case IDC_OPTIONS:
      case IDC_SHOW_HISTORY:
      case IDC_HISTORY_MENU:
      case IDC_SHOW_HISTORY_SIDE_PANEL:
      case IDC_SHOW_DOWNLOADS:
      case IDC_SHOW_PASSWORD_MANAGER:
      case IDC_CLEAR_BROWSING_DATA:
      case IDC_IMPORT_SETTINGS:
      case IDC_EXIT:
      case IDC_CLOSE_TAB:
      case IDC_CLOSE_WINDOW:
      case IDC_PROFILE_MENU_IN_APP_MENU:
      case IDC_PROFILE_MAIN_MENU:
      case IDC_SHOW_AVATAR_MENU:
      case IDC_MANAGE_CHROME_PROFILES:
      case IDC_MANAGE_GOOGLE_ACCOUNT:
      case IDC_SHOW_SIGNIN:
      case IDC_SHOW_SIGNIN_WHEN_PAUSED:
      case IDC_TURN_ON_SYNC:
      case IDC_SHOW_SYNC_SETTINGS:
      case IDC_SHOW_SYNC_PASSPHRASE_DIALOG:
        return true;
      case IDC_EXTENSIONS_SUBMENU:
      case IDC_MANAGE_EXTENSIONS:
      case IDC_EXTENSIONS_SUBMENU_MANAGE_EXTENSIONS:
      case IDC_EXTENSIONS_SUBMENU_VISIT_CHROME_WEB_STORE:
      case IDC_FIND_EXTENSIONS:
        return isPrivate_;
      default:
        return false;
    }
  }

  bool IsChromeAppMenuItemVisible(CefRefPtr<CefBrowser> /*browser*/, int command_id) override {
    return !IsHiddenCommand(command_id);
  }

  /// True handles the command, which here means refusing it: a hidden item
  /// can still be reached by its accelerator.
  bool OnChromeCommand(CefRefPtr<CefBrowser> /*browser*/,
                       int command_id,
                       cef_window_open_disposition_t /*disposition*/) override {
    return IsHiddenCommand(command_id);
  }

  // MARK: Keyboard

  /// Chrome's own shortcuts for the commands a pane does not have go to the
  /// Kitchen's menu instead, so Command-W closes the pane, not Chrome's tab.
  bool OnPreKeyEvent(CefRefPtr<CefBrowser> /*browser*/,
                     const CefKeyEvent& event,
                     CefEventHandle os_event,
                     bool* /*is_keyboard_shortcut*/) override {
    NSEvent* keyEvent = (__bridge NSEvent*)os_event;
    if (event.type != KEYEVENT_RAWKEYDOWN || !keyEvent || !ADHIsKitchenShortcut(keyEvent)) {
      return false;
    }
    [view_ forwardShortcutToMenu:keyEvent];
    return true;
  }

  // MARK: Navigation

  bool OnBeforeBrowse(CefRefPtr<CefBrowser> /*browser*/,
                      CefRefPtr<CefFrame> frame,
                      CefRefPtr<CefRequest> request,
                      bool /*user_gesture*/,
                      bool /*is_redirect*/) override {
    if (!frame->IsMain()) {
      return false;
    }
    // The delegate shows the refusal; true cancels the navigation.
    return [view_ refusalForNavigationTo:ADHString(request->GetURL())] != nil;
  }

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

  /// A pane's browser lives in a CEF window of its own, never the project
  /// window, so the default is right: CEF closes that window, which the
  /// window delegate allows once the pane is closing, and `OnBeforeClose`
  /// follows.
  bool DoClose(CefRefPtr<CefBrowser> /*browser*/) override { return false; }

  void OnBeforeClose(CefRefPtr<CefBrowser> /*browser*/) override {
    [view_ browserDidClose];
    [ADHChromiumRuntime.shared browserDidClose];
  }

  /// DevTools is never the pane's page: it gets a client of its own.
  void OnBeforeDevToolsPopup(CefRefPtr<CefBrowser> /*browser*/,
                             CefWindowInfo& /*windowInfo*/,
                             CefRefPtr<CefClient>& client,
                             CefBrowserSettings& /*settings*/,
                             CefRefPtr<CefDictionaryValue>& /*extra_info*/,
                             bool* /*use_default_window*/) override {
    client = new ADHDevToolsClient();
  }

  /// Chromium allowed a popup in `OnBeforePopup` and then failed to create it
  /// (the opener closed or navigated mid-creation, or creation failed), so
  /// the popup's own client never hears of it. This is called on the opener's
  /// client: the pending popup view is found by `popup_id` and told to undo
  /// what adopting it did, and the opener (if still there) stops waiting for
  /// its browser view. It can arrive after the opener's `OnBeforeClose`, so
  /// it reads this client's own table, never more of the opener than `view_`.
  void OnBeforePopupAborted(CefRefPtr<CefBrowser> /*browser*/, int popup_id) override {
    NSNumber* key = @(popup_id);
    ADHChromiumBrowserView* popup = [pendingPopups_ objectForKey:key];
    [pendingPopups_ removeObjectForKey:key];
    [view_ popupDidAbort:popup];
    [popup popupCreationDidAbort];
  }

  bool OnBeforePopup(CefRefPtr<CefBrowser> /*browser*/,
                     CefRefPtr<CefFrame> /*frame*/,
                     int popup_id,
                     const CefString& target_url,
                     const CefString& /*target_frame_name*/,
                     WindowOpenDisposition /*target_disposition*/,
                     bool user_gesture,
                     const CefPopupFeatures& /*popupFeatures*/,
                     CefWindowInfo& /*windowInfo*/,
                     CefRefPtr<CefClient>& client,
                     CefBrowserSettings& settings,
                     CefRefPtr<CefDictionaryValue>& /*extra_info*/,
                     bool* /*no_javascript_access*/) override {
    // The host puts the popup in a tab: a view of its own, whose Chrome
    // window Chromium's popup browser view is put in (the browser view
    // delegate's `OnPopupBrowserViewCreated`). Returning false lets Chromium
    // go ahead, so the popup keeps its opener and the opener's request
    // context — what a sign-in or 2FA window needs to post its answer back.
    CefRefPtr<CefClient> adopted = [view_ openPopupForAddress:ADHString(target_url)
                                                  userGesture:user_gesture
                                                     settings:settings];
    if (!adopted) {
      return true;
    }
    // Dead entries (popups that were created, or whose view went away) are
    // dropped here, so the table stays the size of the popups in flight.
    for (NSNumber* key in pendingPopups_.keyEnumerator.allObjects) {
      if (![[pendingPopups_ objectForKey:key] isCreatingBrowser]) {
        [pendingPopups_ removeObjectForKey:key];
      }
    }
    ADHChromiumBrowserView* popup = static_cast<ADHBrowserClient*>(adopted.get())->View();
    if (popup) {
      [pendingPopups_ setObject:popup forKey:@(popup_id)];
    }
    client = adopted;
    return false;
  }

  /// A link opened anywhere but this page — Chrome's Open Link in New Tab,
  /// New Window or Incognito Window, a middle- or Command-click — which
  /// Chrome would open into a browser of its own, outside every pane. It
  /// goes to the pane as a tab instead, and Chrome makes nothing.
  bool OnOpenURLFromTab(CefRefPtr<CefBrowser> /*browser*/,
                        CefRefPtr<CefFrame> /*frame*/,
                        const CefString& target_url,
                        WindowOpenDisposition target_disposition,
                        bool user_gesture) override {
    switch (target_disposition) {
      case CEF_WOD_UNKNOWN:
      case CEF_WOD_CURRENT_TAB:
      case CEF_WOD_SAVE_TO_DISK:
      case CEF_WOD_IGNORE_ACTION:
        return false;
      default:
        break;
    }
    [view_ openTabForAddress:ADHString(target_url)
                offTheRecord:target_disposition == CEF_WOD_OFF_THE_RECORD
                  background:target_disposition == CEF_WOD_NEW_BACKGROUND_TAB
                 userGesture:user_gesture];
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
    // Open Link in Incognito Window would need a private tab, which only a
    // private pane has; in any other pane the item goes.
    if (!isPrivate_) {
      const int index = model->GetIndexOf(IDC_CONTENT_CONTEXT_OPENLINKOFFTHERECORD);
      if (index >= 0) {
        model->RemoveAt(static_cast<size_t>(index));
        TrimSeparators(model);
      }
    }
    // Chrome's own Inspect items follow the setting; the Kitchen's item is
    // added only when Chrome's menu has no Inspect of its own, so the menu
    // never shows two.
    const bool allowed = view_.allowsDevTools;
    bool chromeInspects = false;
    bool removed = false;
    for (size_t index = model->GetCount(); index > 0; --index) {
      if (!ADHIsDevToolsCommand(model->GetCommandIdAt(index - 1))) {
        continue;
      }
      if (allowed) {
        chromeInspects = true;
      } else {
        model->RemoveAt(index - 1);
        removed = true;
      }
    }
    if (!allowed) {
      if (removed) {
        TrimSeparators(model);
      }
      return;
    }
    if (!chromeInspects) {
      if (model->GetCount() > 0) {
        model->AddSeparator();
      }
      model->AddItem(kInspectElementCommand, "Inspect Element");
    }
  }

  /// Drops the separators a removed item left leading, trailing or doubled.
  static void TrimSeparators(CefRefPtr<CefMenuModel> model) {
    bool previousIsSeparator = true;
    for (size_t index = 0; index < model->GetCount();) {
      const bool isSeparator = model->GetTypeAt(index) == MENUITEMTYPE_SEPARATOR;
      if (isSeparator && previousIsSeparator) {
        model->RemoveAt(index);
        continue;
      }
      previousIsSeparator = isSeparator;
      ++index;
    }
    while (model->GetCount() > 0 && model->GetTypeAt(model->GetCount() - 1) == MENUITEMTYPE_SEPARATOR) {
      model->RemoveAt(model->GetCount() - 1);
    }
  }

  bool OnContextMenuCommand(CefRefPtr<CefBrowser> /*browser*/,
                            CefRefPtr<CefFrame> /*frame*/,
                            CefRefPtr<CefContextMenuParams> params,
                            int command_id,
                            EventFlags /*event_flags*/) override {
    if (ADHIsDevToolsCommand(command_id)) {
      // True handles the command, which refuses a hidden Inspect.
      return !view_.allowsDevTools;
    }
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
  const bool isPrivate_;
  /// Popup views adopted in `OnBeforePopup` and not yet created, by popup id,
  /// held weakly: the view's own self-retain keeps it alive while it waits.
  NSMapTable<NSNumber*, ADHChromiumBrowserView*>* pendingPopups_;
  IMPLEMENT_REFCOUNTING(ADHBrowserClient);
};

}  // namespace

// MARK: - Options

@implementation ADHChromiumBrowserOptions

- (instancetype)init {
  if ((self = [super init])) {
    _showsToolbar = YES;
  }
  return self;
}

@end

// MARK: - A shared in-memory session

@implementation ADHChromiumEphemeralSession {
  CefRefPtr<CefRequestContext> _base;
}

- (instancetype)init {
  if ((self = [super init])) {
    // A context must not outlive CefShutdown.
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(runtimeWillShutdown:)
                                               name:ADHChromiumRuntimeWillShutdownNotification
                                             object:nil];
  }
  return self;
}

- (void)dealloc {
  [NSNotificationCenter.defaultCenter removeObserver:self];
}

/// The context holding the session's storage: no cache path, so in memory.
/// Each browser gets a context of its own over it (for its own request
/// handler), and CEF shares storage between a context and the one it was
/// made from.
- (CefRefPtr<CefRequestContext>)baseContext {
  if (!_base) {
    CefRequestContextSettings settings;
    _base = CefRequestContext::CreateContext(settings, nullptr);
  }
  return _base;
}

- (void)runtimeWillShutdown:(NSNotification*)notification {
  _base = nullptr;
}

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
  /// Self, held while Chromium creates the browser: creation finishes on a
  /// later turn of the loop, and the client reports to this view.
  ADHChromiumBrowserView* _retainedWhileCreating;
  /// The Chrome window the browser draws in, and what may close it.
  CefRefPtr<CefWindow> _cefWindow;
  CefRefPtr<ADHWindowDelegate> _windowDelegate;
  /// Keeps `browserWindow` over this view; nil for a hidden browser.
  ADHChromeWindowTracker* _tracker;
  /// The view was made first responder before its page could take the
  /// focus (no browser yet, or no Chrome window on screen for it); the page
  /// takes it when it can.
  BOOL _wantsFocus;
  /// The focus asked for is Chrome's address bar, not the page
  /// (`focusLocationBar`).
  BOOL _wantsLocationBar;
  /// A popup's view, waiting for Chromium to create its browser
  /// (`adoptPopupWithSettings:`); it makes none of its own.
  BOOL _awaitingPopup;
  /// What this view's browser view asks about Chrome style, its toolbar and
  /// its page's popups: made with the view, so a popup's tab has one ready
  /// before Chromium asks for it.
  CefRefPtr<ADHBrowserViewDelegate> _browserViewDelegate;
  /// The tab this page's popup is going to, from `OnBeforePopup` until
  /// Chromium hands over the popup's browser view.
  ADHChromiumBrowserView* _pendingPopup;
  /// The poll `acceptNextDialogWithin:` armed, until it presses its dialog,
  /// runs out of time or is stopped (`stopAcceptingDialogs`).
  NSTimer* _dialogAcceptor;
}

- (instancetype)initWithFrame:(NSRect)frame options:(ADHChromiumBrowserOptions*)options {
  if ((self = [super initWithFrame:frame])) {
    _options = options;
    _acceptsCookies = options.acceptsCookies;
    _queuedMessages = [NSMutableArray array];
    _completions = [NSMutableDictionary dictionary];
    _nextMessageID = 1;
    _zoomFactor = 1.0;
    _browserViewDelegate = [self makeBrowserViewDelegate];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(runtimeWillShutdown:)
                                               name:ADHChromiumRuntimeWillShutdownNotification
                                             object:nil];
  }
  return self;
}

/// The browser view delegate for this view's page. It holds the view
/// weakly, so a popup decided after the view is gone goes nowhere.
- (CefRefPtr<ADHBrowserViewDelegate>)makeBrowserViewDelegate {
  __weak ADHChromiumBrowserView* weakSelf = self;
  ADHBrowserViewDelegate::PopupHost host;
  host.delegateForPopup = [weakSelf]() -> CefRefPtr<CefBrowserViewDelegate> {
    ADHChromiumBrowserView* strongSelf = weakSelf;
    return strongSelf ? [strongSelf pendingPopupDelegate] : nullptr;
  };
  host.adoptPopup = [weakSelf](CefRefPtr<CefBrowserView> browserView) -> bool {
    ADHChromiumBrowserView* strongSelf = weakSelf;
    return strongSelf && [strongSelf adoptPendingPopupBrowserView:browserView];
  };
  return new ADHBrowserViewDelegate(_options.showsToolbar, std::move(host));
}

- (instancetype)initPopupWithFrame:(NSRect)frame options:(ADHChromiumBrowserOptions*)options {
  if ((self = [self initWithFrame:frame options:options])) {
    _awaitingPopup = YES;
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

- (nullable NSWindow*)browserWindow {
  if (!_cefWindow) {
    return nil;
  }
  NSView* content = (__bridge NSView*)_cefWindow->GetWindowHandle();
  return content.window;
}

/// The first view under `view`, breadth first, whose class is `name`.
static NSView* _Nullable ADHFindView(NSView* view, NSString* name) {
  NSMutableArray<NSView*>* queue = [NSMutableArray arrayWithObject:view];
  while (queue.count > 0) {
    NSView* next = queue.firstObject;
    [queue removeObjectAtIndex:0];
    if ([NSStringFromClass(next.class) isEqualToString:name]) {
      return next;
    }
    [queue addObjectsFromArray:next.subviews];
  }
  return nil;
}

- (nullable NSView*)pageView {
  NSWindow* window = _browser ? self.browserWindow : nil;
  NSView* content = window.contentView;
  return content ? ADHFindView(content, @"RenderWidgetHostViewCocoa") : nil;
}

- (CGFloat)toolbarHeight {
  NSView* page = self.pageView;
  NSView* content = page.window.contentView;
  if (!page || !content) {
    return 0;
  }
  NSRect inContent = [page convertRect:page.bounds toView:content];
  CGFloat top = content.isFlipped ? NSMinY(inContent) : NSHeight(content.bounds) - NSMaxY(inContent);
  return MAX(0, top);
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

/// A host that focuses this view means the page: the focus is passed on to
/// the page on the next turn, so this view finishes becoming first
/// responder first, or held until the page can take it.
- (BOOL)becomeFirstResponder {
  _wantsFocus = YES;
  dispatch_async(dispatch_get_main_queue(), ^{ [self focusPageIfFirstResponder]; });
  return YES;
}

/// This view being the project window's first responder is what focusing
/// the pane means, and the page has the keys only while its own window is
/// the key window. So the focus is passed on by making the page window key
/// (`makeKeyWindow`, which neither activates the app nor orders a window
/// forward) with the page its first responder. Only while the app is
/// active and the project window, or a page window over it, is key: a pane
/// focused in a background window, or in an app in the background, does
/// not pull keys out of the window in front, and the project window
/// becoming key later hands them on (`projectWindowDidBecomeKey:`). Held
/// while there is no page, or its window is not on screen yet.
- (void)focusPageIfFirstResponder {
  NSWindow* window = self.window;
  if (!window || window.firstResponder != self) {
    _wantsFocus = NO;
    _wantsLocationBar = NO;
    return;
  }
  NSView* page = self.pageView;
  NSWindow* pageWindow = page.window;
  if (!page || !pageWindow.isVisible) {
    _wantsFocus = YES;
    return;
  }
  _wantsFocus = NO;
  BOOL locationBar = _wantsLocationBar;
  _wantsLocationBar = NO;
  // Already key: the keys are in Chrome's window, wherever Chrome put them
  // (the page, the omnibox, a toolbar button), and the focus stays there.
  if (pageWindow.isKeyWindow && !locationBar) {
    return;
  }
  NSWindow* key = NSApp.keyWindow;
  if (!NSApp.isActive || (key != window && key.parentWindow != window)) {
    return;
  }
  if (!pageWindow.isKeyWindow) {
    [pageWindow makeKeyWindow];
  }
  if (locationBar) {
    _browser->GetHost()->ExecuteChromeCommand(IDC_FOCUS_LOCATION, CEF_WOD_CURRENT_TAB);
    return;
  }
  [pageWindow makeFirstResponder:page];
  _browser->GetHost()->SetFocus(true);
}

- (void)focusLocationBar {
  NSWindow* window = self.window;
  if (!window) {
    return;
  }
  _wantsLocationBar = YES;
  if (window.firstResponder == self) {
    [self focusPageIfFirstResponder];
  } else {
    [window makeFirstResponder:self];
  }
}

/// The project window became key with this view still its first
/// responder — by the keyboard, the Window menu, another window closing or
/// the app coming back — so the page takes the keys again. Not for a click:
/// the click decides where the focus goes, and it has not landed yet.
- (void)projectWindowDidBecomeKey:(NSNotification*)notification {
  switch (NSApp.currentEvent.type) {
    case NSEventTypeLeftMouseDown:
    case NSEventTypeRightMouseDown:
    case NSEventTypeOtherMouseDown:
      return;
    default:
      break;
  }
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.window.isKeyWindow) {
      [self focusPageIfFirstResponder];
    }
  });
}

// MARK: Creation

- (void)viewWillMoveToWindow:(nullable NSWindow*)newWindow {
  [super viewWillMoveToWindow:newWindow];
  NSNotificationCenter* center = NSNotificationCenter.defaultCenter;
  if (self.window) {
    [center removeObserver:self name:NSWindowDidBecomeKeyNotification object:self.window];
  }
  if (newWindow) {
    [center addObserver:self
               selector:@selector(projectWindowDidBecomeKey:)
                   name:NSWindowDidBecomeKeyNotification
                 object:newWindow];
  }
}

- (void)viewDidMoveToWindow {
  [super viewDidMoveToWindow];
  [_tracker anchorDidMove];
  [self createBrowserIfReady];
}

- (void)viewDidMoveToSuperview {
  [super viewDidMoveToSuperview];
  [_tracker anchorDidMove];
}

// MARK: Keeping the Chrome window over the view

- (void)setFrameSize:(NSSize)newSize {
  [super setFrameSize:newSize];
  [_tracker update];
}

- (void)setFrameOrigin:(NSPoint)newOrigin {
  [super setFrameOrigin:newOrigin];
  [_tracker update];
}

- (void)layout {
  [super layout];
  [_tracker update];
}

- (void)viewDidHide {
  [super viewDidHide];
  [_tracker update];
}

- (void)viewDidUnhide {
  [super viewDidUnhide];
  [_tracker update];
  if (_wantsFocus) {
    [self focusPageIfFirstResponder];
  }
}

/// Where the Chrome window starts, in CEF's screen coordinates (DIPs, from
/// the primary display's top left). The tracker moves it over the view as
/// soon as the browser exists; a hidden browser stays here, off every
/// display.
- (CefRect)initialCefBounds {
  NSRect frame = [ADHChromeWindowTracker screenFrameOfView:self];
  if (_options.hidden || NSIsEmptyRect(frame)) {
    return CefRect(-20000, -20000, 1024, 768);
  }
  CGFloat primaryHeight = NSHeight(NSScreen.screens.firstObject.frame);
  return CefRect(static_cast<int>(NSMinX(frame)), static_cast<int>(primaryHeight - NSMaxY(frame)),
                 static_cast<int>(NSWidth(frame)), static_cast<int>(NSHeight(frame)));
}

- (void)createBrowserIfReady {
  if ((!self.window && !_options.hidden) || _browser || _creating || _closed || _awaitingPopup ||
      !ADHChromiumRuntime.shared.isRunning) {
    return;
  }
  _creating = YES;
  _retainedWhileCreating = self;
  _client = new ADHBrowserClient(self, _acceptsCookies, _thirdPartyBlocking, _options.isPrivate);

  // nil shares the global context's storage; an empty cache path keeps
  // everything in memory — the ephemeral session's, shared with the pane's
  // other tabs, else the context's own and gone with it; a path is a profile
  // of the pane's own. Every browser gets a context of its own all the same,
  // carrying the handler that filters its worker requests. The browser is
  // made once the context is initialized, which Chrome style requires.
  __weak ADHChromiumBrowserView* weakSelf = self;
  CefRefPtr<CefRequestContextHandler> contextHandler = new ADHRequestContextHandler(
      _client->ThirdPartyFilter(),
      [weakSelf](CefRefPtr<CefRequestContext> context) { [weakSelf createBrowserInContext:context]; });
  CefRefPtr<CefRequestContext> context;
  if (_options.cachePath && _options.cachePath.length == 0 && _options.ephemeralSession) {
    context = CefRequestContext::CreateContext([_options.ephemeralSession baseContext], contextHandler);
  } else if (_options.cachePath) {
    CefRequestContextSettings contextSettings;
    if (_options.cachePath.length > 0) {
      [NSFileManager.defaultManager createDirectoryAtPath:_options.cachePath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
      ADHForgetChromeSessions(_options.cachePath);
      CefString(&contextSettings.cache_path) = _options.cachePath.UTF8String;
      contextSettings.persist_session_cookies = true;
    }
    context = CefRequestContext::CreateContext(contextSettings, contextHandler);
  } else {
    context = CefRequestContext::CreateContext(CefRequestContext::GetGlobalContext(), contextHandler);
  }
  [ADHChromiumRuntime.shared browserDidOpen];
  if (!context) {
    [self failCreating:@"request context"];
  }
}

/// Starts keeping the Chrome window over this view, once the browser and
/// its window both exist; a hidden browser is never tracked.
- (void)attachTrackerIfReady {
  NSWindow* browserWindow = self.browserWindow;
  if (_tracker || !_browser || !browserWindow || _options.hidden || _closed) {
    return;
  }
  _tracker = [[ADHChromeWindowTracker alloc] initWithAnchor:self child:browserWindow];
  // The tracker has put the page window on screen: a focus asked for while
  // the browser was being made goes to the page now.
  if (_wantsFocus) {
    [self focusPageIfFirstResponder];
  }
}

- (void)failCreating:(NSString*)what {
  NSLog(@"Chromium: could not create a %@", what);
  [ADHChromiumRuntime.shared browserDidClose];
  _creating = NO;
  _retainedWhileCreating = nil;
  _client = nullptr;
  _windowDelegate = nullptr;
  [self failPendingWithDescription:@"Chromium could not create a browser"];
}

- (void)createBrowserInContext:(CefRefPtr<CefRequestContext>)context {
  if (!_creating) {
    return;
  }
  if (_closed) {
    // Closed while the context initialized: nothing was made, so nothing
    // will report back.
    [ADHChromiumRuntime.shared browserDidClose];
    _client->Detach();
    _client = nullptr;
    _creating = NO;
    _retainedWhileCreating = nil;
    return;
  }
  // A hidden browser shares a profile it does not own (the extensions
  // manager's sits on the global profile or a jar's), so it never writes
  // that profile's store-wide cookie default: the panes on the profile and
  // the Settings switch own it. Its own requests still go through its
  // client's cookie filter.
  if (!_options.hidden) {
    ADHApplyCookiePolicy(context, _acceptsCookies);
  }

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

  CefRefPtr<CefBrowserView> browserView = CefBrowserView::CreateBrowserView(
      _client, CefString(), settings, nullptr, context, _browserViewDelegate);
  if (browserView) {
    [self makeWindowForBrowserView:browserView];
  }
  if (!_cefWindow) {
    [self failCreating:browserView ? @"Chrome window" : @"browser view"];
  }
}

/// Puts `browserView` in a frameless Chrome window of this view's and starts
/// keeping it over the view.
- (void)makeWindowForBrowserView:(CefRefPtr<CefBrowserView>)browserView {
  _windowDelegate = new ADHWindowDelegate(browserView, [self initialCefBounds]);
  if (_closed) {
    _windowDelegate->SetClosing();
  }
  // Created hidden and never shown with `Show()`, which would make the
  // window key and activate the app; the tracker orders it in beside its
  // parent instead.
  _cefWindow = CefWindow::CreateTopLevelWindow(_windowDelegate);
  // Adding the browser view to the window creates the browser at once,
  // so `browserDidOpen:` has usually run by now, without the window.
  [self attachTrackerIfReady];
}

// MARK: Popups

/// Asks the host for a tab for a popup of this page and readies that tab's
/// view for it; nullptr refuses the popup. The tab is pending until
/// Chromium hands over the popup's browser view.
- (CefRefPtr<CefClient>)openPopupForAddress:(NSString*)address
                                 userGesture:(BOOL)userGesture
                                    settings:(CefBrowserSettings&)settings {
  if (_closed || _pendingPopup) {
    return nullptr;
  }
  ADHChromiumBrowserView* popup = [_delegate chromiumBrowserView:self
                                             popupViewForAddress:address
                                                     userGesture:userGesture];
  CefRefPtr<CefClient> adopted = popup ? [popup adoptPopupWithSettings:settings] : nullptr;
  if (adopted) {
    _pendingPopup = popup;
  }
  return adopted;
}

/// A private pane's tabs are all private, so an incognito link is one more
/// of them; any other pane has no private tab to give it, and drops it.
- (void)openTabForAddress:(NSString*)address
             offTheRecord:(BOOL)offTheRecord
               background:(BOOL)background
              userGesture:(BOOL)userGesture {
  if (_closed || (offTheRecord && !_options.isPrivate)) {
    return;
  }
  [_delegate chromiumBrowserView:self openTabForAddress:address background:background userGesture:userGesture];
}

/// The pending tab's browser view delegate, which Chromium gives the
/// popup's browser view; nullptr when no popup is pending.
- (CefRefPtr<CefBrowserViewDelegate>)pendingPopupDelegate {
  return _pendingPopup ? CefRefPtr<CefBrowserViewDelegate>(_pendingPopup->_browserViewDelegate) : nullptr;
}

/// Chromium made the pending popup's browser view: the tab takes it.
- (BOOL)adoptPendingPopupBrowserView:(CefRefPtr<CefBrowserView>)browserView {
  ADHChromiumBrowserView* popup = _pendingPopup;
  _pendingPopup = nil;
  return popup && [popup attachPopupBrowserView:browserView];
}

/// Chromium is about to create a popup's browser for this view: it gets this
/// view's client and settings, and the view waits for it as it would for a
/// browser of its own. The request context stays the opener's, which is
/// what shares the session. nullptr when the view cannot take it (closed,
/// or not a popup's view).
- (CefRefPtr<CefClient>)adoptPopupWithSettings:(CefBrowserSettings&)settings {
  if (!_awaitingPopup || _closed || _browser || _creating) {
    return nullptr;
  }
  _awaitingPopup = NO;
  _creating = YES;
  _retainedWhileCreating = self;
  _client = new ADHBrowserClient(self, _acceptsCookies, _thirdPartyBlocking, _options.isPrivate);
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
  [ADHChromiumRuntime.shared browserDidOpen];
  return _client;
}

- (BOOL)isCreatingBrowser {
  return _creating;
}

/// The opener's half of an aborted popup: it stops waiting for a browser
/// view that will never come, so its next popup is not refused.
- (void)popupDidAbort:(ADHChromiumBrowserView*)popup {
  if (popup && _pendingPopup == popup) {
    _pendingPopup = nil;
  }
}

/// Chromium aborted the popup it was creating for this view, so
/// `browserDidOpen:` and `browserDidClose` will never run: undo what adoption
/// did (the creating flag, the self-retain, the runtime's open count) and, as
/// with a page that closes itself, tell the host so the tab goes away.
- (void)popupCreationDidAbort {
  if (!_creating || _browser) {
    return;
  }
  // Released at the end of this method, not here: it may be the last owner.
  ADHChromiumBrowserView* retained = _retainedWhileCreating;
  _creating = NO;
  _retainedWhileCreating = nil;
  [ADHChromiumRuntime.shared browserDidClose];
  if (_client) {
    _client->Detach();
  }
  [self failPendingWithDescription:@"Chromium could not create the popup"];
  if (!_closed) {
    _closed = YES;
    id<ADHChromiumBrowserViewDelegate> delegate = _delegate;
    _delegate = nil;
    [delegate chromiumBrowserViewDidClose:self];
  }
  (void)retained;
}

/// The popup's browser view, handed over by the opener: it goes in a Chrome
/// window of this view's, as a pane's own page does.
- (BOOL)attachPopupBrowserView:(CefRefPtr<CefBrowserView>)browserView {
  if (!browserView || _cefWindow) {
    return NO;
  }
  [self makeWindowForBrowserView:browserView];
  return _cefWindow != nullptr;
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
  [self attachTrackerIfReady];

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
  BOOL closedByPage = !_closed && _browser != nullptr;
  [_tracker detach];
  _tracker = nil;
  _cefWindow = nullptr;
  _windowDelegate = nullptr;
  _pendingPopup = nil;
  _devToolsRegistration = nullptr;
  _browser = nullptr;
  _creating = NO;
  _retainedWhileCreating = nil;
  [self failPendingWithDescription:@"The Chrome pane closed"];
  if (closedByPage) {
    // `window.close()`: nobody asked, so the host is told and lets the view go.
    _closed = YES;
    id<ADHChromiumBrowserViewDelegate> delegate = _delegate;
    _delegate = nil;
    if (_client) {
      _client->Detach();
    }
    [delegate chromiumBrowserViewDidClose:self];
  }
}

// MARK: Privacy

- (void)setAcceptsCookies:(BOOL)acceptsCookies {
  _acceptsCookies = acceptsCookies;
  if (_client) {
    _client->SetAcceptsCookies(acceptsCookies);
  }
  if (_browser && !_options.hidden) {
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

// MARK: Dialogs

/// Whether `window` is a dialog Chrome opened over `browserWindow`. Chrome
/// builds its dialogs (the uninstall confirmation among them) as views
/// widgets, and over a hidden browser it neither orders one on screen nor
/// makes it a child of the browser's window: what ties the two together is
/// the widget's class and its frame, which Chrome centres inside the
/// browser's.
static BOOL ADHIsDialogOf(NSWindow* window, NSWindow* browserWindow) {
  for (NSWindow* up = window.parentWindow ?: window.sheetParent; up;
       up = up.parentWindow ?: up.sheetParent) {
    if (up == browserWindow) {
      return YES;
    }
  }
  return [NSStringFromClass(window.class) isEqualToString:@"NativeWidgetMacNSWindow"] &&
         NSContainsRect(browserWindow.frame, window.frame);
}

static BOOL ADHPressAcceptButton(NSWindow* window);

- (void)acceptNextDialogWithin:(NSTimeInterval)timeout {
  NSAssert(_options.hidden, @"Only a hidden browser's dialogs are answered for the person");
  if (!_options.hidden) {
    return;
  }
  NSHashTable<NSWindow*>* existing = [NSHashTable weakObjectsHashTable];
  for (NSWindow* window in NSApp.windows) {
    [existing addObject:window];
  }
  NSDate* deadline = [NSDate dateWithTimeIntervalSinceNow:timeout];
  __weak ADHChromiumBrowserView* weakSelf = self;
  // One acceptor at a time, armed for one dialog: an earlier one still
  // polling would press whatever opens next.
  [self stopAcceptingDialogs];
  // Polled: AppKit posts nothing when a window is created, and Chrome's
  // dialog over a hidden window is never ordered on screen. A dialog whose
  // buttons are not there yet is tried again on the next tick.
  _dialogAcceptor = [NSTimer
      scheduledTimerWithTimeInterval:0.05
                             repeats:YES
                               block:^(NSTimer* timer) {
                                 ADHChromiumBrowserView* view = weakSelf;
                                 NSWindow* browserWindow = view.browserWindow;
                                 if (!view || view->_closed || !browserWindow ||
                                     deadline.timeIntervalSinceNow < 0) {
                                   [view stopAcceptingDialogs];
                                   [timer invalidate];
                                   return;
                                 }
                                 for (NSWindow* window in NSApp.windows) {
                                   if ([existing containsObject:window] ||
                                       !ADHIsDialogOf(window, browserWindow)) {
                                     continue;
                                   }
                                   if (ADHPressAcceptButton(window)) {
                                     [view stopAcceptingDialogs];
                                     [timer invalidate];
                                     return;
                                   }
                                 }
                               }];
}

- (void)stopAcceptingDialogs {
  [_dialogAcceptor invalidate];
  _dialogAcceptor = nil;
}

/// Every accessibility element under `element` whose role is button.
static void ADHCollectButtons(id element, NSMutableArray* buttons) {
  if (![element respondsToSelector:@selector(accessibilityRole)]) {
    return;
  }
  if ([[element accessibilityRole] isEqualToString:NSAccessibilityButtonRole]) {
    [buttons addObject:element];
  }
  if ([element respondsToSelector:@selector(accessibilityChildren)]) {
    for (id child in [element accessibilityChildren]) {
      ADHCollectButtons(child, buttons);
    }
  }
}

/// Presses the accept button of a Chrome confirmation dialog through
/// accessibility, which is how a never-shown views dialog takes a press: it
/// ignores keys, Return included, until it has been on screen. The dialog
/// has two buttons, Cancel and the accept button, and on macOS Chrome puts
/// the accept button trailing (`PlatformStyle::kIsOkButtonLeading` is
/// false), so it is the right-hand one; telling them apart by title would
/// need Chrome's own strings in every language. Anything other than exactly
/// two buttons is not pressed. Returns whether a button was pressed.
static BOOL ADHPressAcceptButton(NSWindow* window) {
  NSMutableArray* buttons = [NSMutableArray array];
  ADHCollectButtons(window, buttons);
  if (buttons.count != 2 || ![buttons[0] respondsToSelector:@selector(accessibilityFrame)] ||
      ![buttons[1] respondsToSelector:@selector(accessibilityFrame)] ||
      ![buttons[0] respondsToSelector:@selector(accessibilityPerformPress)] ||
      ![buttons[1] respondsToSelector:@selector(accessibilityPerformPress)]) {
    return NO;
  }
  id accept = NSMinX([buttons[0] accessibilityFrame]) > NSMinX([buttons[1] accessibilityFrame])
                  ? buttons[0]
                  : buttons[1];
  return [accept accessibilityPerformPress];
}

// MARK: Covered

+ (void)setPagesCovered:(BOOL)covered inWindow:(NSWindow*)window {
  [ADHChromeWindowTracker setPagesCovered:covered inWindow:window];
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
  _pendingPopup = nil;
  [self stopAcceptingDialogs];
  [self failPendingWithDescription:@"The Chrome pane closed"];
  CefRefPtr<CefBrowser> browser = _browser;
  _devToolsRegistration = nullptr;
  [_tracker detach];
  if (_windowDelegate) {
    _windowDelegate->SetClosing();
  }
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

- (nullable NSString*)refusalForNavigationTo:(NSString*)address {
  return [_delegate chromiumBrowserView:self refusalForNavigationTo:address];
}

/// The project window takes the key first: the Kitchen's menu items that
/// target the responder chain (Close Pane and the like) must find the pane's
/// window there, not Chrome's.
- (void)forwardShortcutToMenu:(NSEvent*)event {
  NSWindow* parent = self.window;
  if (parent && !parent.isKeyWindow) {
    [parent makeKeyWindow];
  }
  [NSApp.mainMenu performKeyEquivalent:event];
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
