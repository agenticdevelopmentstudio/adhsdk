//
//  ADHChromiumBrowserView.h
//  AgenticDeveloperHubSDKChromium
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ADHChromiumBrowserView;

/// The JavaScript dialog kinds CEF reports.
typedef NS_ENUM(NSInteger, ADHChromiumDialogKind) {
    ADHChromiumDialogKindAlert,
    ADHChromiumDialogKindConfirm,
    ADHChromiumDialogKindPrompt,
} NS_SWIFT_NAME(ChromiumDialogKind);

/// What a browser view reports. Every call arrives on the main thread, which
/// is CEF's UI thread on macOS.
NS_SWIFT_NAME(ChromiumBrowserViewDelegate) NS_SWIFT_UI_ACTOR
@protocol ADHChromiumBrowserViewDelegate <NSObject>
- (void)chromiumBrowserViewAddressDidChange:(ADHChromiumBrowserView *)view;
- (void)chromiumBrowserViewTitleDidChange:(ADHChromiumBrowserView *)view;
/// `isLoading`, `canGoBack` or `canGoForward` changed.
- (void)chromiumBrowserViewLoadingStateDidChange:(ADHChromiumBrowserView *)view;
/// The main frame began a load; the page is committed to the new address.
- (void)chromiumBrowserViewDidStartMainFrameLoad:(ADHChromiumBrowserView *)view;
- (void)chromiumBrowserViewDidFinishMainFrameLoad:(ADHChromiumBrowserView *)view;
- (void)chromiumBrowserView:(ADHChromiumBrowserView *)view
     didFailLoadWithMessage:(NSString *)message
                    address:(NSString *)address;
/// `level` is a console method name: log, info, warn, error or debug.
- (void)chromiumBrowserView:(ADHChromiumBrowserView *)view
          didLogConsoleText:(NSString *)text
                      level:(NSString *)level;
/// A dialog CEF has already suppressed.
- (void)chromiumBrowserView:(ADHChromiumBrowserView *)view
            didRaiseDialog:(ADHChromiumDialogKind)kind
                   message:(NSString *)message;
/// Hand `completion` the path to save to, or nil to refuse the download.
- (void)chromiumBrowserView:(ADHChromiumBrowserView *)view
    destinationForDownloadNamed:(NSString *)name
                     completion:(void (^)(NSString *_Nullable path))completion;
/// Hand `completion` @YES, @NO, or nil for Chromium's own default (refuse).
- (void)chromiumBrowserView:(ADHChromiumBrowserView *)view
    allowsMediaCaptureForHost:(NSString *)host
                       camera:(BOOL)camera
                   microphone:(BOOL)microphone
                   completion:(void (^)(NSNumber *_Nullable allowed))completion;
/// A new-window request for `address`, already refused; the delegate decides
/// whether to load it in place.
- (void)chromiumBrowserView:(ADHChromiumBrowserView *)view
    didRequestPopupForAddress:(NSString *)address
                  userGesture:(BOOL)userGesture;
@end

/// What a pane fixes when its browser is created.
NS_SWIFT_NAME(ChromiumBrowserOptions)
@interface ADHChromiumBrowserOptions : NSObject
/// A store of its own, kept in memory and thrown away with the browser.
@property (nonatomic) BOOL privateBrowsing;
/// Points; 0 keeps Chromium's own.
@property (nonatomic) NSInteger minimumFontSize;
/// The colour behind a page that paints none, so a blank page is the theme's.
@property (nonatomic, copy, nullable) NSColor *backgroundColor;
@end

/// An `NSView` holding one Chromium browser.
///
/// The browser is created the first time the view is in a window, since CEF
/// needs a real parent view; anything asked of it before then is queued
/// (`load`) or answered from what is known (`address` is nil).
NS_SWIFT_NAME(ChromiumBrowserView) NS_SWIFT_UI_ACTOR
@interface ADHChromiumBrowserView : NSView

- (instancetype)initWithFrame:(NSRect)frame options:(ADHChromiumBrowserOptions *)options NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(NSRect)frame NS_UNAVAILABLE;
- (nullable instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@property (nonatomic, weak, nullable) id<ADHChromiumBrowserViewDelegate> delegate;

@property (nonatomic, readonly, copy, nullable) NSString *address;
@property (nonatomic, readonly, copy, nullable) NSString *pageTitle;
@property (nonatomic, readonly) BOOL isLoading;
@property (nonatomic, readonly) BOOL canGoBack;
@property (nonatomic, readonly) BOOL canGoForward;
/// Whether the browser exists yet.
@property (nonatomic, readonly) BOOL hasBrowser;

- (void)loadAddress:(NSString *)address;
- (void)goBack;
- (void)goForward;
- (void)reload;
- (void)stopLoading;
/// 1.0 is 100%.
- (void)setZoomFactor:(double)factor;

/// Whether the context menu offers Inspect Element.
@property (nonatomic) BOOL allowsDevTools;
- (void)showDevTools;

/// Sends one DevTools protocol method to this browser. `completion` gets the
/// method's `result` object, or an error carrying the protocol's message.
/// Methods sent before the browser exists wait for it, in order.
- (void)sendDevToolsMethod:(NSString *)method
                    params:(nullable NSDictionary<NSString *, id> *)params
                completion:(void (^)(NSDictionary<NSString *, id> *_Nullable result,
                                     NSError *_Nullable error))completion;

/// Closes the browser and drops every callback; the view is not used again.
- (void)close;

@end

NS_ASSUME_NONNULL_END
