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
