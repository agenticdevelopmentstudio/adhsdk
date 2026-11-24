//
//  ADHChromeViewsHost.mm
//  AgenticDeveloperHubSDKChromium
//

#import "ADHChromeViewsHost.h"
#import "ADHChromiumPrivate.h"

#import "ADHChromiumBrowserView.h"

#import <objc/message.h>
#import <objc/runtime.h>

// MARK: - Which pane owns a window

/// Each tracked CEF window, and the pane view it sits over. Both weak: the
/// entry goes when either does.
static NSMapTable<NSWindow*, ADHChromiumBrowserView*>* ADHOwnersByWindow(void) {
  static NSMapTable* table;
  static dispatch_once_t once;
  dispatch_once(&once, ^{ table = [NSMapTable weakToWeakObjectsMapTable]; });
  return table;
}

ADHChromiumBrowserView* _Nullable ADHBrowserViewOwningWindow(NSWindow* window) {
  for (NSWindow* candidate = window; candidate; candidate = candidate.parentWindow) {
    ADHChromiumBrowserView* owner = [ADHOwnersByWindow() objectForKey:candidate];
    if (owner) {
      return owner;
    }
  }
  return nil;
}

// MARK: - Window actions belong to the project window

/// The project window behind `window` when `window` is itself a tracked page
/// window — not a bubble or menu above one, whose own Close is its own.
static NSWindow* _Nullable ADHProjectWindowBehindPageWindow(NSWindow* window) {
  ADHChromiumBrowserView* owner = [ADHOwnersByWindow() objectForKey:window];
  NSWindow* parent = owner.window;
  return parent == window ? nil : parent;
}

/// The window-level actions of the Window menu and the title bar. While the
/// page window is key they would reach it before the project window, and it
/// can do none of them — it cannot close, minimize or zoom, and it is neither
/// a tab nor a full-screen window — so they are the project window's.
static NSSet<NSString*>* ADHProjectWindowActions(void) {
  static NSSet<NSString*>* actions;
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    actions = [NSSet setWithArray:@[
      @"performClose:", @"performMiniaturize:", @"performZoom:", @"centerWindow:", @"toggleFullScreen:",
      @"toggleToolbarShown:",
      @"runToolbarCustomizationPalette:", @"toggleTabBar:", @"toggleTabOverview:", @"selectNextTab:",
      @"selectPreviousTab:", @"moveTabToNewWindow:", @"mergeAllWindows:"
    ]];
  });
  return actions;
}

/// Wraps `validator` (`validateMenuItem:` or `validateUserInterfaceItem:`)
/// on `cls`, so a project-window action is validated by the project window.
static void ADHForwardValidation(Class cls, SEL validator) {
  Method method = class_getInstanceMethod(cls, validator);
  if (!method) {
    return;
  }
  typedef BOOL (*ValidateIMP)(id, SEL, id);
  ValidateIMP original = reinterpret_cast<ValidateIMP>(method_getImplementation(method));
  IMP wrapped = imp_implementationWithBlock(^BOOL(NSWindow* window, id<NSValidatedUserInterfaceItem> item) {
    NSWindow* parent = ADHProjectWindowBehindPageWindow(window);
    SEL action = item.action;
    if (parent && action && [ADHProjectWindowActions() containsObject:NSStringFromSelector(action)]) {
      if (![parent respondsToSelector:action]) {
        return NO;
      }
      if ([parent respondsToSelector:validator]) {
        return reinterpret_cast<ValidateIMP>(objc_msgSend)(parent, validator, item);
      }
      return YES;
    }
    return original(window, validator, item);
  });
  class_replaceMethod(cls, validator, wrapped, method_getTypeEncoding(method));
}

/// Wraps the window-level actions of Chrome's window class, and their
/// validation, so on a tracked page window they act on, and are validated
/// by, the project window behind it. AppKit sends a menu item's action to
/// the key window's chain first, so making the project window main is not
/// enough for these: the page window answers them itself. Every other window
/// of the class — Chrome's bubbles, menus, DevTools — is left as it was.
/// Done once per class, on the main thread.
static void ADHForwardWindowActionsOfClass(Class cls) {
  static NSMutableSet<Class>* done;
  if (!done) {
    done = [NSMutableSet set];
  }
  if (!cls || [done containsObject:cls]) {
    return;
  }
  [done addObject:cls];
  for (NSString* name in ADHProjectWindowActions()) {
    SEL selector = NSSelectorFromString(name);
    Method method = class_getInstanceMethod(cls, selector);
    if (!method) {
      continue;
    }
    typedef void (*ActionIMP)(id, SEL, id);
    ActionIMP original = reinterpret_cast<ActionIMP>(method_getImplementation(method));
    // Only an action the user sent — a menu item, a button — is forwarded:
    // those pass themselves as the sender. Chrome's own calls pass nil, and
    // they mean Chrome's window: a page asking for full screen makes Chrome
    // send `toggleFullScreen:nil` to it, which forwarded would take the
    // project window into full screen, and the screen with it, while Chrome
    // waited for a transition of its own window that never came.
    BOOL isFullScreen = selector == @selector(toggleFullScreen:);
    IMP wrapped = imp_implementationWithBlock(^(NSWindow* window, id sender) {
      NSWindow* parent = ADHProjectWindowBehindPageWindow(window);
      if (parent && sender) {
        [NSApp sendAction:selector to:parent from:sender];
        return;
      }
      // Nor can the page window go full screen itself: it is a child pinned
      // over its pane, and the tracker would put it straight back, leaving
      // Chrome and the page waiting in a full-screen layout that never
      // completes. Page full screen (a video's button, requestFullscreen) is
      // refused the way AppKit refuses one, so Chrome unwinds its own state
      // and the page's — its fullscreenchange or fullscreenerror fires and
      // the video stays in the page. Taking the project window full screen
      // for the page instead would leave the Kitchen in a full-screen Space
      // the page asked for and cannot leave cleanly. Control-Command-F
      // still takes the project window full screen, with the page in it.
      if (parent && isFullScreen) {
        id<NSWindowDelegate> delegate = window.delegate;
        if ([delegate respondsToSelector:@selector(windowDidFailToEnterFullScreen:)]) {
          __weak NSWindow* weakWindow = window;
          dispatch_async(dispatch_get_main_queue(), ^{
            NSWindow* strongWindow = weakWindow;
            id<NSWindowDelegate> strongDelegate = strongWindow.delegate;
            if (strongWindow && [strongDelegate respondsToSelector:@selector(windowDidFailToEnterFullScreen:)]) {
              [strongDelegate windowDidFailToEnterFullScreen:strongWindow];
            }
          });
        }
        return;
      }
      original(window, selector, sender);
    });
    class_replaceMethod(cls, selector, wrapped, method_getTypeEncoding(method));
  }
  ADHForwardValidation(cls, @selector(validateMenuItem:));
  ADHForwardValidation(cls, @selector(validateUserInterfaceItem:));
}

// MARK: - Covered pages

/// Posted with the project window whose panes became covered or uncovered.
static NSNotificationName const ADHChromePagesCoveredDidChange = @"ADHChromePagesCoveredDidChange";

/// The project windows whose panes are covered. Weak, so a closed window
/// leaves no entry for a recycled address to inherit.
static NSHashTable<NSWindow*>* ADHCoveredWindows(void) {
  static NSHashTable* table;
  static dispatch_once_t once;
  dispatch_once(&once, ^{ table = [NSHashTable weakObjectsHashTable]; });
  return table;
}

// MARK: - The tracker

@implementation ADHChromeWindowTracker {
  __weak NSView* _anchor;
  __weak NSWindow* _child;
  /// The window whose notifications are being observed.
  __weak NSWindow* _observedParent;
  /// The anchor's ancestors whose frame notifications are being observed.
  NSArray<NSView*>* _observedAncestors;
  /// A sheet is on its way in or attached; `attachedSheet` is not yet set
  /// when the will-begin notification arrives.
  BOOL _sheetBeginning;
  BOOL _detached;
  /// `update` is running. The frame and ordering changes it makes post
  /// move, resize and occlusion notifications synchronously, which come
  /// straight back to `update`; a child the window server has not yet
  /// reported visible would then be re-added without end.
  BOOL _updating;
  /// A notification arrived during `update`: one more pass once it returns.
  BOOL _updateAgain;
}

+ (NSRect)screenFrameOfView:(NSView*)view {
  NSWindow* window = view.window;
  if (!window) {
    return NSZeroRect;
  }
  // A window cannot be clipped, so it is given only the part of the view
  // that shows: a FrameHoldingView keeps its content wider than itself
  // while a pane's width changes, clipped at its trailing edge, and the
  // page framed to the whole view would paint over the pane beside it.
  // `visibleRect` is what the view's clipping ancestors leave of it; the
  // content view's frame bounds it to the window's content as well.
  NSRect rect = [view convertRect:view.visibleRect toView:nil];
  NSView* content = window.contentView;
  if (content) {
    rect = NSIntersectionRect(rect, [content convertRect:content.bounds toView:nil]);
  }
  if (NSIsEmptyRect(rect)) {
    return NSZeroRect;
  }
  return [window convertRectToScreen:rect];
}

+ (BOOL)pagesAreCoveredInWindow:(NSWindow*)window {
  return window && [ADHCoveredWindows() containsObject:window];
}

+ (void)setPagesCovered:(BOOL)covered inWindow:(NSWindow*)window {
  if ([self pagesAreCoveredInWindow:window] == covered) {
    return;
  }
  if (covered) {
    [ADHCoveredWindows() addObject:window];
  } else {
    [ADHCoveredWindows() removeObject:window];
  }
  [NSNotificationCenter.defaultCenter postNotificationName:ADHChromePagesCoveredDidChange object:window];
}

- (instancetype)initWithAnchor:(NSView*)anchor child:(NSWindow*)child {
  if ((self = [super init])) {
    _anchor = anchor;
    _child = child;
    // Follows the project window into full screen; without it a full-screen
    // parent leaves its page behind on the desktop's space.
    child.collectionBehavior |= NSWindowCollectionBehaviorFullScreenAuxiliary;
    if ([anchor isKindOfClass:[ADHChromiumBrowserView class]]) {
      [ADHOwnersByWindow() setObject:(ADHChromiumBrowserView*)anchor forKey:child];
    }
    ADHForwardWindowActionsOfClass([child class]);
    [self observeChild:child];
    [self anchorDidMove];
  }
  return self;
}

- (void)dealloc {
  [NSNotificationCenter.defaultCenter removeObserver:self];
}

/// Chrome shows, moves and activates its own window when it chooses — an
/// extension focusing its window, a permission bubble, an install prompt —
/// and none of that passes through the parent. Each is a reason to put the
/// child back where the pane says it belongs.
- (void)observeChild:(NSWindow*)child {
  NSNotificationCenter* center = NSNotificationCenter.defaultCenter;
  for (NSNotificationName name in @[
         NSWindowDidChangeOcclusionStateNotification, NSWindowDidMoveNotification, NSWindowDidResizeNotification,
         NSWindowDidDeminiaturizeNotification
       ]) {
    [center addObserver:self selector:@selector(geometryDidChange:) name:name object:child];
  }
  [center addObserver:self selector:@selector(childDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:child];
}

/// The page window took the key: by a click into the page, or because
/// Chrome made it key itself. The project window stays the main window, so
/// its title bar stays active and the menu bar's items that follow the main
/// window find it (`makeMainWindow` never activates the app). A page window
/// that should not be showing is ordered out again by `update`; one that
/// went key while the app is not active hands the key back to the project
/// window rather than leaving Chrome to bring the Kitchen forward.
- (void)childDidBecomeKey:(NSNotification*)notification {
  if (_detached) {
    return;
  }
  [self update];
  NSWindow* child = _child;
  NSView* anchor = _anchor;
  NSWindow* parent = anchor.window;
  if (!child.isVisible || !parent) {
    return;
  }
  if (!parent.isMainWindow && parent.canBecomeMainWindow) {
    [parent makeMainWindow];
  }
  // The pane holds the focus while its page has the keys, so the project
  // window remembers it: a tab switch, or the project window becoming key
  // again, then gives the keys back to the page rather than to whatever
  // held the project window's focus before the page was clicked.
  if (parent.firstResponder != anchor && anchor.acceptsFirstResponder) {
    [parent makeFirstResponder:anchor];
  }
  // A click went to the page: the key is the user's to give it, however
  // late activation follows, and the click's typing belongs in the page.
  switch (NSApp.currentEvent.type) {
    case NSEventTypeLeftMouseDown:
    case NSEventTypeRightMouseDown:
    case NSEventTypeOtherMouseDown:
      return;
    default:
      break;
  }
  // Chrome made it key itself. Checked a turn later, since a key change and
  // the app's activation arrive in either order.
  __weak NSWindow* weakChild = child;
  __weak NSWindow* weakParent = parent;
  dispatch_async(dispatch_get_main_queue(), ^{
    NSWindow* strongChild = weakChild;
    NSWindow* strongParent = weakParent;
    if (!NSApp.isActive && strongChild.isKeyWindow && strongParent.isVisible && strongParent.canBecomeKeyWindow) {
      [strongParent makeKeyWindow];
    }
  });
}

- (void)anchorDidMove {
  if (_detached) {
    return;
  }
  NSNotificationCenter* center = NSNotificationCenter.defaultCenter;
  for (NSView* ancestor in _observedAncestors) {
    [center removeObserver:self name:NSViewFrameDidChangeNotification object:ancestor];
  }
  NSMutableArray<NSView*>* ancestors = [NSMutableArray array];
  for (NSView* ancestor = _anchor.superview; ancestor; ancestor = ancestor.superview) {
    [ancestors addObject:ancestor];
    [center addObserver:self
               selector:@selector(geometryDidChange:)
                   name:NSViewFrameDidChangeNotification
                 object:ancestor];
  }
  _observedAncestors = ancestors;
  [self observeParent:_anchor.window];
  [self update];
}

- (void)observeParent:(NSWindow*)parent {
  NSWindow* old = _observedParent;
  if (old == parent) {
    return;
  }
  NSNotificationCenter* center = NSNotificationCenter.defaultCenter;
  NSArray<NSNotificationName>* geometry = @[
    NSWindowDidMoveNotification, NSWindowDidResizeNotification, NSWindowDidEndLiveResizeNotification,
    NSWindowDidEnterFullScreenNotification, NSWindowDidExitFullScreenNotification,
    NSWindowDidMiniaturizeNotification, NSWindowDidDeminiaturizeNotification,
    NSWindowDidChangeOcclusionStateNotification
  ];
  if (old) {
    for (NSNotificationName name in geometry) {
      [center removeObserver:self name:name object:old];
    }
    [center removeObserver:self name:NSWindowWillBeginSheetNotification object:old];
    [center removeObserver:self name:NSWindowDidEndSheetNotification object:old];
    [center removeObserver:self name:ADHChromePagesCoveredDidChange object:old];
  }
  _observedParent = parent;
  _sheetBeginning = NO;
  if (!parent) {
    return;
  }
  for (NSNotificationName name in geometry) {
    [center addObserver:self selector:@selector(geometryDidChange:) name:name object:parent];
  }
  [center addObserver:self selector:@selector(sheetWillBegin:) name:NSWindowWillBeginSheetNotification object:parent];
  [center addObserver:self selector:@selector(sheetDidEnd:) name:NSWindowDidEndSheetNotification object:parent];
  [center addObserver:self selector:@selector(geometryDidChange:) name:ADHChromePagesCoveredDidChange object:parent];
}

- (void)geometryDidChange:(NSNotification*)notification {
  [self update];
}

- (void)sheetWillBegin:(NSNotification*)notification {
  _sheetBeginning = YES;
  [self update];
}

- (void)sheetDidEnd:(NSNotification*)notification {
  _sheetBeginning = NO;
  [self update];
}

/// Places the page window over the anchor, or orders it out. Re-entry from
/// the notifications its own changes post is folded into a single second
/// pass, which sees the settled state and changes nothing it already
/// changed; a third pass is never needed.
- (void)update {
  if (_updating) {
    _updateAgain = YES;
    return;
  }
  _updating = YES;
  _updateAgain = NO;
  [self place];
  if (_updateAgain) {
    _updateAgain = NO;
    [self place];
  }
  _updateAgain = NO;
  _updating = NO;
}

- (void)place {
  NSWindow* child = _child;
  NSView* anchor = _anchor;
  if (_detached || !child) {
    return;
  }
  NSWindow* parent = anchor.window;
  [self observeParent:parent];
  NSRect frame = [ADHChromeWindowTracker screenFrameOfView:anchor];
  // A sheet is drawn by the window server above the parent but below its
  // child windows, so the page would cover it: the page steps out instead.
  // So it does for anything the parent draws over its panes (Arrange mode),
  // which as the parent's own content is always beneath the page.
  BOOL shows = parent && parent.isVisible && !parent.isMiniaturized && !anchor.isHiddenOrHasHiddenAncestor &&
               !NSIsEmptyRect(frame) && !parent.attachedSheet && !_sheetBeginning &&
               ![ADHChromeWindowTracker pagesAreCoveredInWindow:parent];
  if (!shows) {
    [self orderOut];
    return;
  }
  if (!NSEqualRects(child.frame, frame)) {
    [child setFrame:frame display:YES];
  }
  // A child keeps its own level, so under quiet presentation a parent sunk
  // behind the desktop would otherwise have its page float above every app.
  if (child.level != parent.level) {
    child.level = parent.level;
  }
  if (child.parentWindow != parent) {
    [child.parentWindow removeChildWindow:child];
    // Orders the child in with its parent, without activating anything.
    [parent addChildWindow:child ordered:NSWindowAbove];
  } else if (!child.isVisible) {
    [parent removeChildWindow:child];
    [parent addChildWindow:child ordered:NSWindowAbove];
  }
}

- (void)orderOut {
  NSWindow* child = _child;
  // A page leaving with the keys gives them to the project window, which
  // AppKit would otherwise hand to whichever window it found next — and
  // whatever covers the pane (Arrange mode's Escape, Return and arrows)
  // listens on the project window.
  NSWindow* parent = _anchor.window;
  if (child.isKeyWindow && parent.isVisible && parent.canBecomeKeyWindow) {
    [parent makeKeyWindow];
  }
  [child.parentWindow removeChildWindow:child];
  if (child.isVisible) {
    [child orderOut:nil];
  }
}

- (void)detach {
  if (_detached) {
    return;
  }
  [self orderOut];
  _detached = YES;
  [NSNotificationCenter.defaultCenter removeObserver:self];
  _observedAncestors = nil;
  _observedParent = nil;
  NSWindow* child = _child;
  if (child) {
    [ADHOwnersByWindow() removeObjectForKey:child];
  }
}

@end
