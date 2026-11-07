//
//  ADHChromiumRuntime.mm
//  AgenticDeveloperHubSDKChromium
//
//  Chromium's start, its message pump and its end, for an app that is already
//  running when the first Chrome pane opens.
//
//  Three things CEF expects of a Cocoa host are supplied here rather than by
//  the app:
//
//  - **NSApp speaks CefAppProtocol.** Chromium asks the application whether
//    it is inside `-sendEvent:` so nested run loops behave. The app's
//    NSApplication is not a CEF subclass, so the protocols and the two
//    methods are added to its class at runtime, and `-sendEvent:` is wrapped
//    to keep the flag true while it runs.
//  - **The message pump is the app's run loop.** `external_message_pump`
//    makes Chromium ask, through `OnScheduleMessagePumpWork`, for its work to
//    be done on the main thread; a 30 Hz timer in the common modes covers
//    work it never asks for, as CEF's own documentation recommends.
//  - **The framework is loaded by path,** since the app does not link it:
//    `cef_load_library` binds the C API the wrapper calls into.
//

#import "ADHChromiumRuntime.h"
#import "ADHChromiumPrivate.h"

#import <AppKit/AppKit.h>
#import <crt_externs.h>
#import <objc/runtime.h>

#include <atomic>

#include "include/cef_app.h"
#include "include/cef_application_mac.h"
#include "include/cef_cookie.h"
#include "include/cef_version.h"
#include "include/wrapper/cef_library_loader.h"

NSErrorDomain const ADHChromiumErrorDomain = @"ADHChromiumErrorDomain";
NSNotificationName const ADHChromiumRuntimeWillShutdownNotification = @"ADHChromiumRuntimeWillShutdown";

static void ADHPumpChromium(void);

// MARK: - The application, for CEF

namespace {

/// Whether CEF's work is running right now, so a pump asked for from inside
/// it waits for the next turn instead of re-entering.
bool gPumping = false;
/// Whether `CefInitialize` has succeeded and `CefShutdown` has not run.
std::atomic<bool> gRunning{false};
/// The `-[NSApplication isHandlingSendEvent]` flag CEF reads.
BOOL gHandlingSendEvent = NO;
/// `acceptsCookies`, read by every request's cookie filter on the network
/// thread.
std::atomic<bool> gAcceptsCookies{true};

class ADHCefApp : public CefApp, public CefBrowserProcessHandler {
 public:
  ADHCefApp(std::vector<std::pair<std::string, std::string>> switches) : switches_(std::move(switches)) {}

  CefRefPtr<CefBrowserProcessHandler> GetBrowserProcessHandler() override { return this; }

  void OnContextInitialized() override {
    // The global context takes settings only once it exists.
    ADHApplyCookiePolicy(CefRequestContext::GetGlobalContext());
  }

  void OnBeforeCommandLineProcessing(const CefString& process_type,
                                     CefRefPtr<CefCommandLine> command_line) override {
    if (!process_type.empty()) {
      return;
    }
    for (const auto& entry : switches_) {
      if (entry.second.empty()) {
        command_line->AppendSwitch(entry.first);
      } else {
        command_line->AppendSwitchWithValue(entry.first, entry.second);
      }
    }
  }

  void OnScheduleMessagePumpWork(int64_t delay_ms) override {
    if (delay_ms <= 0) {
      dispatch_async(dispatch_get_main_queue(), ^{ ADHPumpChromium(); });
    } else {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay_ms * NSEC_PER_MSEC), dispatch_get_main_queue(),
                     ^{ ADHPumpChromium(); });
    }
  }

 private:
  std::vector<std::pair<std::string, std::string>> switches_;
  IMPLEMENT_REFCOUNTING(ADHCefApp);
};

class ADHDeleteCookiesCallback : public CefDeleteCookiesCallback {
 public:
  explicit ADHDeleteCookiesCallback(void (^completion)(void)) : completion_(completion) {}
  void OnComplete(int /*num_deleted*/) override {
    void (^completion)(void) = completion_;
    dispatch_async(dispatch_get_main_queue(), ^{ completion(); });
  }

 private:
  void (^completion_)(void);
  IMPLEMENT_REFCOUNTING(ADHDeleteCookiesCallback);
};

/// Adds CefAppProtocol to NSApp's class and wraps its `-sendEvent:`. Done
/// once; a second call would wrap the wrapper.
void ADHInstallApplicationProtocol(void) {
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    Class cls = [NSApp class];
    class_addProtocol(cls, @protocol(CrAppProtocol));
    class_addProtocol(cls, @protocol(CrAppControlProtocol));
    class_addProtocol(cls, @protocol(CefAppProtocol));

    IMP isHandling = imp_implementationWithBlock(^BOOL(id /*app*/) { return gHandlingSendEvent; });
    class_addMethod(cls, @selector(isHandlingSendEvent), isHandling, "c@:");
    IMP setHandling = imp_implementationWithBlock(^(id /*app*/, BOOL value) { gHandlingSendEvent = value; });
    class_addMethod(cls, @selector(setHandlingSendEvent:), setHandling, "v@:c");

    SEL sendEvent = @selector(sendEvent:);
    Method method = class_getInstanceMethod(cls, sendEvent);
    typedef void (*SendEventIMP)(id, SEL, NSEvent*);
    SendEventIMP original = reinterpret_cast<SendEventIMP>(method_getImplementation(method));
    IMP wrapped = imp_implementationWithBlock(^(id app, NSEvent* event) {
      CefScopedSendingEvent sending;
      original(app, sendEvent, event);
    });
    class_replaceMethod(cls, sendEvent, wrapped, method_getTypeEncoding(method));
  });
}

}  // namespace

void ADHApplyCookiePolicy(CefRefPtr<CefRequestContext> context) {
  if (!context) {
    return;
  }
  const bool accepts = gAcceptsCookies.load();
  // The content setting is the store-wide switch; an in-memory (private)
  // context refuses a default content setting, so the same default is also
  // written as the profile preference it is stored in.
  context->SetContentSetting(CefString(), CefString(), CEF_CONTENT_SETTING_TYPE_COOKIES,
                             accepts ? CEF_CONTENT_SETTING_VALUE_ALLOW : CEF_CONTENT_SETTING_VALUE_BLOCK);
  CefRefPtr<CefValue> value = CefValue::Create();
  value->SetInt(accepts ? CEF_CONTENT_SETTING_VALUE_ALLOW : CEF_CONTENT_SETTING_VALUE_BLOCK);
  CefString error;
  if (context->CanSetPreference("profile.default_content_setting_values.cookies") &&
      !context->SetPreference("profile.default_content_setting_values.cookies", value, error)) {
    NSLog(@"Chromium refused the cookie preference: %s", error.ToString().c_str());
  }
}

static void ADHPumpChromium(void) {
  if (gPumping || !gRunning.load()) {
    return;
  }
  gPumping = true;
  CefDoMessageLoopWork();
  gPumping = false;
}

// MARK: - Configuration

@implementation ADHChromiumRuntimeConfiguration

- (instancetype)init {
  if ((self = [super init])) {
    _cachePath = @"";
    _helperPath = @"";
    _frameworkPath = @"";
    _autoplayPolicy = @"";
    _hardwareAcceleration = YES;
  }
  return self;
}

@end

// MARK: - Runtime

@implementation ADHChromiumRuntime {
  NSTimer* _pumpTimer;
  NSError* _startError;
  NSInteger _openBrowsers;
  CefRefPtr<ADHCefApp> _app;
}

+ (ADHChromiumRuntime*)shared {
  static ADHChromiumRuntime* runtime;
  static dispatch_once_t once;
  dispatch_once(&once, ^{ runtime = [[ADHChromiumRuntime alloc] init]; });
  return runtime;
}

+ (NSString*)cefVersion {
  return @CEF_VERSION;
}

+ (NSString*)chromiumVersion {
  return [NSString stringWithFormat:@"%d.%d.%d.%d", CHROME_VERSION_MAJOR, CHROME_VERSION_MINOR, CHROME_VERSION_BUILD,
                                    CHROME_VERSION_PATCH];
}

- (BOOL)acceptsCookies {
  return gAcceptsCookies.load();
}

- (void)setAcceptsCookies:(BOOL)acceptsCookies {
  gAcceptsCookies.store(acceptsCookies);
  if (gRunning.load()) {
    ADHApplyCookiePolicy(CefRequestContext::GetGlobalContext());
  }
}

- (BOOL)isRunning {
  return gRunning.load();
}

- (NSError*)errorWithDescription:(NSString*)description {
  return [NSError errorWithDomain:ADHChromiumErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey : description}];
}

- (BOOL)startWithConfiguration:(ADHChromiumRuntimeConfiguration*)configuration error:(NSError**)error {
  NSAssert(NSThread.isMainThread, @"Chromium starts on the main thread");
  if (gRunning.load()) {
    return YES;
  }
  if (_startError) {
    if (error) {
      *error = _startError;
    }
    return NO;
  }
  NSError* failure = [self startChromium:configuration];
  if (failure) {
    _startError = failure;
    if (error) {
      *error = failure;
    }
    return NO;
  }
  return YES;
}

- (nullable NSError*)startChromium:(ADHChromiumRuntimeConfiguration*)configuration {
  NSFileManager* files = NSFileManager.defaultManager;
  NSString* library = [configuration.frameworkPath stringByAppendingPathComponent:@"Chromium Embedded Framework"];
  if (![files fileExistsAtPath:library]) {
    return [self errorWithDescription:[NSString stringWithFormat:@"Chromium is not in the app: %@", library]];
  }
  if (![files isExecutableFileAtPath:configuration.helperPath]) {
    return [self errorWithDescription:[NSString stringWithFormat:@"Chromium's helper is not in the app: %@",
                                                                 configuration.helperPath]];
  }
  if (!cef_load_library(library.fileSystemRepresentation)) {
    return [self errorWithDescription:[NSString stringWithFormat:@"Chromium could not be loaded from %@", library]];
  }
  ADHInstallApplicationProtocol();

  NSString* root = configuration.cachePath.stringByDeletingLastPathComponent;
  [files createDirectoryAtPath:configuration.cachePath withIntermediateDirectories:YES attributes:nil error:nil];

  CefSettings settings;
  settings.no_sandbox = false;
  settings.external_message_pump = true;
  settings.multi_threaded_message_loop = false;
  settings.persist_session_cookies = true;
  settings.log_severity = LOGSEVERITY_WARNING;
  CefString(&settings.browser_subprocess_path) = configuration.helperPath.UTF8String;
  CefString(&settings.framework_dir_path) = configuration.frameworkPath.UTF8String;
  CefString(&settings.main_bundle_path) = NSBundle.mainBundle.bundlePath.UTF8String;
  CefString(&settings.root_cache_path) = root.UTF8String;
  CefString(&settings.cache_path) = configuration.cachePath.UTF8String;
  CefString(&settings.log_file) = [root stringByAppendingPathComponent:@"chromium.log"].UTF8String;
  if (configuration.remoteDebuggingPort > 0) {
    settings.remote_debugging_port = static_cast<int>(configuration.remoteDebuggingPort);
  }

  std::vector<std::pair<std::string, std::string>> switches;
  if (configuration.autoplayPolicy.length > 0) {
    switches.emplace_back("autoplay-policy", configuration.autoplayPolicy.UTF8String);
  }
  if (!configuration.hardwareAcceleration) {
    switches.emplace_back("disable-gpu", "");
  }
  if (configuration.developmentMode) {
    switches.emplace_back("use-mock-keychain", "");
    switches.emplace_back("disable-backgrounding-occluded-windows", "");
    switches.emplace_back("disable-renderer-backgrounding", "");
    switches.emplace_back("disable-background-timer-throttling", "");
  }
  _app = new ADHCefApp(std::move(switches));

  CefMainArgs args(*_NSGetArgc(), *_NSGetArgv());
  gRunning.store(true);
  if (!CefInitialize(args, settings, _app, nullptr)) {
    gRunning.store(false);
    _app = nullptr;
    return [self errorWithDescription:[NSString stringWithFormat:@"Chromium did not start (exit code %d); see %@",
                                                                 CefGetExitCode(), [root stringByAppendingPathComponent:@"chromium.log"]]];
  }

  _pumpTimer = [NSTimer timerWithTimeInterval:1.0 / 30.0 repeats:YES block:^(NSTimer* /*timer*/) { ADHPumpChromium(); }];
  [NSRunLoop.mainRunLoop addTimer:_pumpTimer forMode:NSRunLoopCommonModes];
  [NSNotificationCenter.defaultCenter addObserver:self
                                         selector:@selector(applicationWillTerminate:)
                                             name:NSApplicationWillTerminateNotification
                                           object:nil];
  return nil;
}

- (void)applicationWillTerminate:(NSNotification*)notification {
  [self shutdown];
}

- (void)browserDidOpen {
  _openBrowsers += 1;
}

- (void)browserDidClose {
  _openBrowsers = MAX(0, _openBrowsers - 1);
}

- (void)shutdown {
  if (!gRunning.load()) {
    return;
  }
  [NSNotificationCenter.defaultCenter postNotificationName:ADHChromiumRuntimeWillShutdownNotification object:self];
  // A browser closes over several turns of Chromium's own loop; give them
  // half a second, which is what a quitting app can spare.
  NSDate* deadline = [NSDate dateWithTimeIntervalSinceNow:0.5];
  while (_openBrowsers > 0 && deadline.timeIntervalSinceNow > 0) {
    ADHPumpChromium();
    [NSThread sleepForTimeInterval:0.01];
  }
  [_pumpTimer invalidate];
  _pumpTimer = nil;
  [NSNotificationCenter.defaultCenter removeObserver:self name:NSApplicationWillTerminateNotification object:nil];
  CefShutdown();
  gRunning.store(false);
  _app = nullptr;
}

- (void)deleteAllCookiesWithCompletion:(void (^)(void))completion {
  if (!gRunning.load()) {
    completion();
    return;
  }
  CefRefPtr<CefCookieManager> manager = CefCookieManager::GetGlobalManager(nullptr);
  if (!manager || !manager->DeleteCookies("", "", new ADHDeleteCookiesCallback(completion))) {
    completion();
  }
}

@end
