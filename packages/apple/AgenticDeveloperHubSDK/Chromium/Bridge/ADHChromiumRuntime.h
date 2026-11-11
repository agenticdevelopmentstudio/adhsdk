//
//  ADHChromiumRuntime.h
//  AgenticDeveloperHubSDKChromium
//
//  The Objective-C face of the Chromium Embedded Framework (CEF), for Swift.
//  Nothing in this header names a C++ type: CEF's API is C++ and stays in
//  the .mm files, so the framework's module is plain Objective-C.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// What Chromium reads once, when it starts. A change to any of it applies
/// the next time the app opens, because CEF can be initialised once per
/// process.
NS_SWIFT_NAME(ChromiumRuntimeConfiguration)
@interface ADHChromiumRuntimeConfiguration : NSObject

/// The profile directory every non-private Chrome pane shares.
@property (nonatomic, copy) NSString *cachePath;
/// The base helper executable, `<App> Helper.app/Contents/MacOS/<App> Helper`.
/// CEF finds the (GPU), (Renderer), (Plugin) and (Alerts) variants beside it
/// by name.
@property (nonatomic, copy) NSString *helperPath;
/// `Chromium Embedded Framework.framework` inside the app.
@property (nonatomic, copy) NSString *frameworkPath;
/// 0 is off.
@property (nonatomic) NSInteger remoteDebuggingPort;
@property (nonatomic) BOOL hardwareAcceleration;
/// Seconds between Chrome's checks for extension updates; 0 leaves Chrome's default.
@property (nonatomic) NSInteger extensionUpdateFrequency;
/// Chromium's `--autoplay-policy` value; empty keeps Chromium's default.
@property (nonatomic, copy) NSString *autoplayPolicy;
/// Debug builds: keep painting and running timers in a window the window
/// server reports occluded, which every quietly presented window is, and
/// use a mock keychain so a development build never asks for the login
/// keychain.
@property (nonatomic) BOOL developmentMode;

@end

/// The one Chromium of this process.
NS_SWIFT_NAME(ChromiumRuntime) NS_SWIFT_UI_ACTOR
@interface ADHChromiumRuntime : NSObject

@property (class, readonly) ADHChromiumRuntime *shared;

/// The CEF and Chromium versions this framework was compiled against.
@property (class, readonly) NSString *cefVersion;
@property (class, readonly) NSString *chromiumVersion;

@property (nonatomic, readonly) BOOL isRunning;

/// Loads the framework, installs what CEF needs on `NSApp` and initialises
/// Chromium. Idempotent once it has succeeded; after a failure it fails again
/// with the same error, since CEF cannot be initialised twice in a process.
/// Main thread only.
- (BOOL)startWithConfiguration:(ADHChromiumRuntimeConfiguration *)configuration
                         error:(NSError *_Nullable *_Nullable)error;

/// Closes every browser and shuts Chromium down. Called on its own when the
/// app terminates.
- (void)shutdown;

/// Whether sites may read and write cookies in every Chrome pane. Setting it
/// writes the profile's default cookie setting, which covers script and
/// service-worker access as well as requests, and every request's cookie
/// filter reads it too, so it applies at once. Main thread only.
@property (atomic) BOOL acceptsCookies;

/// Removes every cookie of the shared profile.
- (void)deleteAllCookiesWithCompletion:(void (^)(void))completion;

/// The domains the jar profile at `path` holds cookies for, each without its
/// leading dot, in no order. Read through a request context on that cache
/// path, which shares the storage of any pane open on it. Empty when Chromium
/// is not running or the profile does not exist, which is never created here.
- (void)cookieDomainsInProfileAtPath:(NSString *)path
                          completion:(void (^)(NSArray<NSString *> *domains))completion
    NS_SWIFT_NAME(cookieDomains(inProfileAtPath:completion:));

/// Removes the cookies of one site from the jar profile at `path` — its
/// domain and every domain under it — or, when `site` is nil, every cookie,
/// the HTTP cache and saved HTTP sign-ins. Does nothing when Chromium is not
/// running or the profile does not exist.
- (void)deleteSiteData:(nullable NSString *)site
       inProfileAtPath:(NSString *)path
            completion:(void (^)(void))completion
    NS_SWIFT_NAME(deleteSiteData(_:inProfileAtPath:completion:));

@end

/// The error domain of `startWithConfiguration:error:`.
FOUNDATION_EXPORT NSErrorDomain const ADHChromiumErrorDomain NS_SWIFT_NAME(ChromiumErrorDomain);

NS_ASSUME_NONNULL_END
