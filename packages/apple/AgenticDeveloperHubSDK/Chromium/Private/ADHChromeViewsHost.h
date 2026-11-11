//
//  ADHChromeViewsHost.h
//  AgenticDeveloperHubSDKChromium
//
//  What hosts a Chrome-style browser for a pane. CEF on macOS runs Chrome
//  style (Chrome's toolbar, extensions) only inside its own Views window, so a
//  pane's browser lives in a frameless top-level CEF window that a tracker
//  keeps glued over the pane: a child window of the project window, framed to
//  the pane's rectangle on screen, ordered out whenever the pane cannot be
//  seen. A project header: it is not in the framework's module.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Keeps `child` exactly over `anchor` and in its window's child list while
/// the anchor can be seen, and out of the window list while it cannot. It
/// never makes the child key, never activates the app and never orders the
/// child anywhere but next to its parent. It also watches the child, which
/// Chrome shows, moves and makes key on its own: each is re-checked against
/// the pane, the project window stays main while the page is key, with the
/// anchor as its first responder, and the
/// child's window-level actions (Close, Minimize, Zoom, full screen, tabs)
/// go to the project window. Chrome's own request to take the child full
/// screen (page full screen) is refused as a failed transition.
@interface ADHChromeWindowTracker : NSObject

/// Starts tracking; the child is attached on the first `update`.
- (instancetype)initWithAnchor:(NSView*)anchor child:(NSWindow*)child NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

/// Recomputes the child's frame and whether it is shown. Cheap when nothing
/// changed; the anchor calls it from every geometry and visibility hook.
- (void)update;

/// Re-reads the anchor's ancestors, whose frame changes move the anchor
/// without telling it. Called when the anchor changes superview or window.
- (void)anchorDidMove;

/// Takes the child out of its parent and the window list, and stops
/// watching. The tracker does nothing after this.
- (void)detach;

/// The part of `view` that shows — what its clipping ancestors and its
/// window's content leave of it — in screen coordinates; empty when none of
/// it shows or it has no window.
+ (NSRect)screenFrameOfView:(NSView*)view;

/// Whether something the project window draws over its panes — Arrange
/// mode's scrim and toolbar — covers them. A child window is always above
/// its parent's content, so no overlay in the parent can be drawn over a
/// page: while `window`'s panes are covered, every page window over them is
/// ordered out. Main thread only.
+ (BOOL)pagesAreCoveredInWindow:(NSWindow*)window;
+ (void)setPagesCovered:(BOOL)covered inWindow:(NSWindow*)window;

@end

NS_ASSUME_NONNULL_END

#ifdef __cplusplus
#include "include/views/cef_box_layout.h"
#include "include/views/cef_browser_view.h"
#include "include/views/cef_browser_view_delegate.h"
#include "include/views/cef_window.h"
#include "include/views/cef_window_delegate.h"

#include <functional>

/// The browser view's side: Chrome style, Chrome's toolbar or none, and the
/// page's popups handed to the pane that took them.
///
/// `OnBeforePopup` decides a popup: when the host gives it a tab, the
/// opener's view records that tab's view as pending and Chromium goes on to
/// create the popup's browser view, asking this delegate first for the
/// popup view's delegate and then telling it the view exists. `popup` answers
/// both from the pending tab: the delegate the tab made for its own page,
/// and whether the tab took the view into a Chrome window of its own. A tab
/// that did not leaves the popup to Chromium's default window, which never
/// happens while the pending tab is alive.
class ADHBrowserViewDelegate : public CefBrowserViewDelegate {
 public:
  struct PopupHost {
    /// The pending tab's delegate, or nullptr for none.
    std::function<CefRefPtr<CefBrowserViewDelegate>()> delegateForPopup;
    /// Hands the popup's browser view to the pending tab; true if it took it.
    std::function<bool(CefRefPtr<CefBrowserView>)> adoptPopup;
  };

  ADHBrowserViewDelegate(bool showsToolbar, PopupHost popupHost)
      : showsToolbar_(showsToolbar), popupHost_(std::move(popupHost)) {}

  cef_runtime_style_t GetBrowserRuntimeStyle() override { return CEF_RUNTIME_STYLE_CHROME; }

  ChromeToolbarType GetChromeToolbarType(CefRefPtr<CefBrowserView> /*browser_view*/) override {
    return showsToolbar_ ? CEF_CTT_NORMAL : CEF_CTT_NONE;
  }

  CefRefPtr<CefBrowserViewDelegate> GetDelegateForPopupBrowserView(CefRefPtr<CefBrowserView> /*browser_view*/,
                                                                   const CefBrowserSettings& /*settings*/,
                                                                   CefRefPtr<CefClient> /*client*/,
                                                                   bool is_devtools) override {
    if (!is_devtools && popupHost_.delegateForPopup) {
      if (CefRefPtr<CefBrowserViewDelegate> delegate = popupHost_.delegateForPopup()) {
        return delegate;
      }
    }
    return this;
  }

  bool OnPopupBrowserViewCreated(CefRefPtr<CefBrowserView> /*browser_view*/,
                                 CefRefPtr<CefBrowserView> popup_browser_view,
                                 bool is_devtools) override {
    return !is_devtools && popupHost_.adoptPopup && popupHost_.adoptPopup(popup_browser_view);
  }

 private:
  const bool showsToolbar_;
  const PopupHost popupHost_;
  IMPLEMENT_REFCOUNTING(ADHBrowserViewDelegate);
};

/// The window's side: a frameless, hidden, Chrome-style window holding one
/// browser view, which only the pane may close.
class ADHWindowDelegate : public CefWindowDelegate {
 public:
  ADHWindowDelegate(CefRefPtr<CefBrowserView> browserView, CefRect initialBounds)
      : browserView_(browserView), initialBounds_(initialBounds) {}

  /// The pane is closing its browser: the window may now close.
  void SetClosing() { closing_ = true; }

  /// Adds the page, then Chrome's toolbar above it. Chrome style creates the
  /// toolbar view but leaves the rest to the embedder, as CEF's `cefclient`
  /// does it: the view arrives hidden and outside the window, so with the
  /// window's default fill layout and only the browser view added, no toolbar
  /// shows at any size. Adding the browser view runs its `OnWindowChanged`,
  /// which is what makes `GetChromeToolbar()` answer; it answers null when the
  /// delegate asked for `CEF_CTT_NONE`, and the window keeps its fill layout.
  void OnWindowCreated(CefRefPtr<CefWindow> window) override {
    window->AddChildView(browserView_);
    CefRefPtr<CefView> toolbar = browserView_->GetChromeToolbar();
    if (!toolbar) {
      return;
    }
    CefBoxLayoutSettings settings;
    settings.horizontal = false;
    CefRefPtr<CefBoxLayout> layout = window->SetToBoxLayout(settings);
    window->AddChildViewAt(toolbar, 0);
    toolbar->SetVisible(true);
    layout->SetFlexForView(browserView_, 1);
  }
  void OnWindowDestroyed(CefRefPtr<CefWindow> /*window*/) override { browserView_ = nullptr; }

  cef_runtime_style_t GetWindowRuntimeStyle() override { return CEF_RUNTIME_STYLE_CHROME; }
  CefRect GetInitialBounds(CefRefPtr<CefWindow> /*window*/) override { return initialBounds_; }
  cef_show_state_t GetInitialShowState(CefRefPtr<CefWindow> /*window*/) override { return CEF_SHOW_STATE_HIDDEN; }
  bool IsFrameless(CefRefPtr<CefWindow> /*window*/) override { return true; }
  bool WithStandardWindowButtons(CefRefPtr<CefWindow> /*window*/) override { return false; }
  cef_state_t AcceptsFirstMouse(CefRefPtr<CefWindow> /*window*/) override { return STATE_ENABLED; }
  bool CanResize(CefRefPtr<CefWindow> /*window*/) override { return true; }
  bool CanMaximize(CefRefPtr<CefWindow> /*window*/) override { return false; }
  bool CanMinimize(CefRefPtr<CefWindow> /*window*/) override { return false; }
  /// Nothing but the pane, or the page itself, closes the window: it has no
  /// close button, and a Command-W meant for the project window must not
  /// take the page with it. A close already under way in the browser — the
  /// page's own `window.close()`, which Chrome treats as mandatory — is let
  /// through: refused, it would leave the browser half closed, its page gone
  /// and `OnBeforeClose` never sent, so the tab would keep a dead page.
  bool CanClose(CefRefPtr<CefWindow> /*window*/) override {
    if (closing_) {
      return true;
    }
    CefRefPtr<CefBrowser> browser = browserView_ ? browserView_->GetBrowser() : nullptr;
    return browser && browser->GetHost()->IsReadyToBeClosed();
  }

 private:
  CefRefPtr<CefBrowserView> browserView_;
  const CefRect initialBounds_;
  bool closing_ = false;
  IMPLEMENT_REFCOUNTING(ADHWindowDelegate);
};
#endif
