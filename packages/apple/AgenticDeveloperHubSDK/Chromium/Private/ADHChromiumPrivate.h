//
//  ADHChromiumPrivate.h
//  AgenticDeveloperHubSDKChromium
//
//  What the runtime and the browser views say to each other and nobody else
//  hears. A project header: it is not in the framework's module.
//

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

/// Writes `acceptsCookies` into `context` as its default cookie content
/// setting, which is what `document.cookie`, service workers and every other
/// cookie path consult; the per-request cookie filter covers only requests.
/// UI thread only.
void ADHApplyCookiePolicy(CefRefPtr<CefRequestContext> context);
#endif

NS_ASSUME_NONNULL_BEGIN

NS_ASSUME_NONNULL_END
