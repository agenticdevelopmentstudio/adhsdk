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

/// Which third-party subresources a browser view refuses. Third party means a
/// host outside the page's site (its registrable domain, by Chromium's
/// public-suffix list); a document load is never refused.
typedef NS_ENUM(NSInteger, ADHChromiumThirdPartyBlocking) {
    ADHChromiumThirdPartyBlockingNone,
    ADHChromiumThirdPartyBlockingScripts,
    ADHChromiumThirdPartyBlockingAll,
} NS_SWIFT_NAME(ChromiumThirdPartyBlocking);

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
/// Whether a drag that has entered the page may reach it.
- (BOOL)chromiumBrowserViewShouldAcceptDrag:(ADHChromiumBrowserView *)view;
/// Whether text input or an editing command may reach the page. `action` is
/// the selector Chromium's view was sent: `insertText:replacementRange:` for
/// typed, dictated or picked text, `setMarkedText:…` for an input method's
/// composition, or an Edit menu action such as `paste:`. Asked for every
/// one, whether a key event, a menu or the system delivered it.
- (BOOL)chromiumBrowserView:(ADHChromiumBrowserView *)view shouldPerformTextInput:(NSString *)action;
/// A DevTools protocol event. `sessionId` names the attached target it came
/// from (an out-of-process frame, attached with `Target.setAutoAttach`), and
/// is nil for the page's own.
- (void)chromiumBrowserView:(ADHChromiumBrowserView *)view
    didReceiveDevToolsEvent:(NSString *)method
                     params:(NSDictionary<NSString *, id> *)params
                  sessionId:(nullable NSString *)sessionId;
@end

/// What a pane fixes when its browser is created.
NS_SWIFT_NAME(ChromiumBrowserOptions)
@interface ADHChromiumBrowserOptions : NSObject
/// Where the browser keeps its cookies and site data. nil is the shared
/// profile; an empty string is a store of its own kept in memory and thrown
/// away with the browser; a path is a profile of its own on disk, which must
/// sit inside the runtime's root cache directory.
@property (nonatomic, copy, nullable) NSString *cachePath;
/// Whether cookies are sent and saved when the browser is created.
@property (nonatomic) BOOL acceptsCookies;
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

/// Whether this browser sends and saves cookies; applied to its store live.
@property (nonatomic) BOOL acceptsCookies;
/// Which third-party subresources this browser refuses; applies from the next
/// request.
@property (nonatomic) ADHChromiumThirdPartyBlocking thirdPartyBlocking;

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

/// The same, sent to an attached target's session: `sessionId` from a
/// `Target.attachedToTarget` event, or nil for the page itself.
- (void)sendDevToolsMethod:(NSString *)method
                    params:(nullable NSDictionary<NSString *, id> *)params
                 sessionId:(nullable NSString *)sessionId
                completion:(void (^)(NSDictionary<NSString *, id> *_Nullable result,
                                     NSError *_Nullable error))completion;

/// Closes the browser and drops every callback; the view is not used again.
- (void)close;

@end

NS_ASSUME_NONNULL_END
