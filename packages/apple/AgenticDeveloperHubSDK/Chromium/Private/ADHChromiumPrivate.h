//
//  ADHChromiumPrivate.h
//  AgenticDeveloperHubSDKChromium
//
//  What the runtime and the browser views say to each other and nobody else
//  hears. A project header: it is not in the framework's module.
//

#import <AppKit/AppKit.h>

#import "ADHChromiumRuntime.h"

NS_ASSUME_NONNULL_BEGIN

/// Posted on the main thread when Chromium is about to shut down. Every
/// browser view closes its browser at once.
FOUNDATION_EXPORT NSNotificationName const ADHChromiumRuntimeWillShutdownNotification;

@interface ADHChromiumRuntime ()
/// A browser was created; `shutdown` waits for every one to close.
- (void)browserDidOpen;
- (void)browserDidClose;
@end

NS_ASSUME_NONNULL_END

#ifdef __cplusplus
#include "include/cef_request_context.h"

/// Writes `accepts` into `context` as its default cookie content
/// setting, which is what `document.cookie`, service workers and every other
/// cookie path consult; the per-request cookie filter covers only requests.
/// UI thread only.
void ADHApplyCookiePolicy(CefRefPtr<CefRequestContext> context, bool accepts);
#endif

NS_ASSUME_NONNULL_BEGIN

@class ADHChromiumBrowserView;

/// The pane whose Chrome window is `window`, or is an ancestor of it through
/// `parentWindow` (a bubble or menu the page opened); nil for any other
/// window. Filled in by the pane's window tracker.
FOUNDATION_EXPORT ADHChromiumBrowserView* _Nullable ADHBrowserViewOwningWindow(NSWindow* window);

/// Deletes the Chrome sessions saved in the profile at `profilePath`, once per
/// profile per launch and before Chromium opens it. Chrome style keeps
/// sessions, and on the next launch reopens them as Chrome windows of its
/// own, outside every pane; panes are the app's to restore. Main thread only.
FOUNDATION_EXPORT void ADHForgetChromeSessions(NSString* profilePath);

NS_ASSUME_NONNULL_END
