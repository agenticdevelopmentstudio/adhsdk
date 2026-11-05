import AppKit

/// The parts of a chat window that differ between the tools that open one.
///
/// Everything *else* about the window — the hidden title bar, the transparent
/// background, the gear and its switches, the sizing behaviour — is the same
/// everywhere on purpose, which is why it lives in `ChatWindowController`
/// rather than in each host.
public struct ChatWindowConfiguration: Sendable {

    /// The window's title. Hidden in the bar, but it is what the Window menu,
    /// Mission Control and the accessibility tree read.
    public var title: String

    /// Prefix for this window's saved appearance settings. Two windows with
    /// different namespaces remember their text size and transparency
    /// separately; two with the same namespace share them.
    public var defaultsNamespace: String

    /// Caption at the top of the gear's panel — the window's name in the
    /// reader's language rather than its title-bar string.
    public var appearanceTitle: String

    /// Size the window opens at the first time, before a saved frame exists.
    public var contentSize: NSSize

    /// Which face the chat wears: the stock look, or the terminal's.
    public var chrome: InlineChatChrome

    /// What the gear calls the backdrop switch, when the window has a
    /// backdrop. "Rain" reads better than "Background animation" for the
    /// window that has rain in it.
    public var backdropToggleTitle: String

    public init(
        title: String,
        defaultsNamespace: String,
        appearanceTitle: String,
        contentSize: NSSize = NSSize(width: 460, height: 620),
        chrome: InlineChatChrome = InlineChatChrome(),
        backdropToggleTitle: String = "Background animation"
    ) {
        self.title = title
        self.defaultsNamespace = defaultsNamespace
        self.appearanceTitle = appearanceTitle
        self.contentSize = contentSize
        self.chrome = chrome
        self.backdropToggleTitle = backdropToggleTitle
    }
}

/// A window that is nothing but a chat: no title bar furniture, a transparent
/// background so the theme's own alpha means something, and a gear at the
/// trailing edge holding the window's appearance switches.
///
/// Open one from any tool. What a host supplies is a view model over its own
/// backend and a `ChatWindowConfiguration`; what it gets back is the same
/// window every other tool's chat is, which is the point — a reader who has
/// used one of these knows where the gear is and what ⌘+ does.
///
/// Subclass it to add a host's own behaviour on top (a connect ritual, a
/// status item, extra chrome); the window itself needs no subclass.
@MainActor
open class ChatWindowController: NSWindowController {

    /// The chat this window holds. Public because a host's own machinery —
    /// a scripted arrival, a placeholder that changes with connection state —
    /// drives the view directly.
    public let chatView: InlineChatView

    /// The gear and the switches behind it.
    public let appearance: ChatWindowAppearanceController

    public init(
        viewModel: ObservableChatViewModel,
        localParticipantID: String,
        configuration: ChatWindowConfiguration,
        backdrop: NSView? = nil
    ) {
        let chatView = InlineChatView(viewModel: viewModel, localParticipantID: localParticipantID)
        chatView.chrome = configuration.chrome
        // Passed in rather than named in the configuration, because a view is
        // not a value: `ChatWindowConfiguration` is `Sendable` and describes
        // *what* a window is, and this is a thing the host already built.
        chatView.backdrop = backdrop
        self.chatView = chatView

        let size = configuration.contentSize
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)

        // Through a content view *controller*, not `contentView` directly.
        // Assigned as a bare content view, `InlineChatView` opened 232 points
        // wide — its own constraints' minimum — instead of the size asked for,
        // and could not be dragged wider: the only constraints AppKit derived
        // tied the view's origin to the window, never its width, so the layout
        // engine was free to settle the width at that minimum and the window
        // followed the view down.
        window.contentViewController = ChatContentViewController(chatView: chatView, size: size)

        // The one thing that makes the window open at the size asked for.
        // `NSWindow` hands its content view a flexible autoresizing mask, and
        // a flexible mask against `NSThemeFrame` — which is not laid out by
        // auto layout — yields no width constraint at all, leaving the content
        // view's width a free variable the engine settles at the smallest its
        // constraints allow. A fixed mask makes AppKit derive
        // `width == frame.width` instead, and re-derive it every time the
        // window sets the content frame — so the window still resizes, it just
        // stops shrink-wrapping itself on the way up.
        window.contentView?.autoresizingMask = []
        window.title = configuration.title

        // No title bar: the chat *is* the window. `.fullSizeContentView` runs
        // the content to the top edge, and the three pieces below take away
        // what would otherwise still be drawn over it — the bar's material,
        // the title, and the traffic lights. `.titled` stays in the mask
        // because it is what makes a window key-able and what carries the
        // standard window commands; hiding its furniture is a separate
        // question from having it.
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(button)?.isHidden = true
        }
        // With no bar left to grab, the surface itself is the handle.
        window.isMovableByWindowBackground = true

        // Translucent, so what is behind reads faintly through the chat. The
        // alpha is the theme's own — `old-school-terminal` sets
        // `--pc-surface: rgba(5, 8, 5, 0.8)` and `InlineChatView` paints that
        // straight onto its layer. All that is needed here is a window willing
        // to let it mean something: an opaque window composites its own
        // background behind the content first, so every theme's carefully
        // chosen alpha would land on solid grey.
        window.isOpaque = false
        window.backgroundColor = .clear

        appearance = ChatWindowAppearanceController(
            window: window,
            chatView: chatView,
            defaults: WindowAppearanceDefaults(namespace: configuration.defaultsNamespace),
            title: configuration.appearanceTitle,
            backdropToggleTitle: configuration.backdropToggleTitle)

        super.init(window: window)

        // Where the reader last left it. Set *after* `super.init(window:)` and
        // through the controller rather than the window, because adopting a
        // window is what clears its `frameAutosaveName`: a name set before this
        // line is thrown away, and the window opens centred every launch.
        // `windowFrameAutosaveName` is the controller's own spelling of the
        // same setting, and it is what makes AppKit write the frame on every
        // move and resize. `setFrameUsingName` reads it back, and its `false` —
        // nothing saved yet — is the only case where centring is right.
        // Namespaced with the settings, so two chat windows remember their
        // frames as separately as they remember their text size.
        let frameName = "\(configuration.defaultsNamespace).chatWindowFrame"
        windowFrameAutosaveName = frameName
        if !window.setFrameUsingName(frameName) { window.center() }

        appearance.install()

        // Typing is never off in a chat window. The composer is always
        // editable, but "editable" is not "ready": a window that comes forward
        // with its first responder still on the window itself swallows the
        // first thing typed into it. Re-taking focus every time the window
        // becomes key covers the ways a chat window arrives — a status-bar
        // item re-fronting it, ⌘` from another window, a click on the desktop
        // and back — without the host having to remember any of them.
        NotificationCenter.default.addObserver(
            self, selector: #selector(windowBecameKey),
            name: NSWindow.didBecomeKeyNotification, object: window)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    /// Only when nothing else already has the caret.
    ///
    /// The window swallowing the first keystroke is the problem being solved,
    /// and that only happens when the first responder is still the window
    /// itself. Taking focus unconditionally solves it by creating a worse one:
    /// select a passage of the transcript, click away to another app, click
    /// back — and the selection is gone before ⌘C can reach it, every time the
    /// window regains key.
    @objc private func windowBecameKey() {
        guard let window, window.firstResponder === window else { return }
        focusInput()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("ChatWindowController is created in code, never from a nib")
    }

    open override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
        focusInput()
    }

    /// Puts the caret in the composer, so typing works the moment the window
    /// appears. `InlineChatView` keeps its input field private, so it is found
    /// by walking the hierarchy — the composer is the only editable field in a
    /// chat, since transcript bubbles are labels.
    public func focusInput() {
        guard let field = window?.contentView?.firstEditableTextField() else { return }
        window?.makeFirstResponder(field)
    }
}

/// The chat's scope, declared one level up so that everything pinned beside the
/// chat resolves to it too.
///
/// A superview walk from the border never passes through the chat — they are
/// siblings — so without this the border resolves to `ThemeScope.app` no matter
/// what `host:` it was handed. Inert while a scope carries only a type scale (a
/// hairline has no type), and wrong the moment one carries a colour, which is
/// the entire reason scopes exist.
@MainActor
private final class ChatContainerView: NSView, ThemeScopeProviding {
    let themeScope: ThemeScope

    init(frame: NSRect, themeScope: ThemeScope) {
        self.themeScope = themeScope
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("ChatContainerView is created in code, never from a nib")
    }
}

/// Carries the chat view as a window's content view controller. Exists only
/// for that: `NSWindow` drives a content view controller's view the way a
/// window should drive its content, where a view assigned straight to
/// `contentView` is left to size itself.
@MainActor
private final class ChatContentViewController: NSViewController {
    private let chatView: InlineChatView

    init(chatView: InlineChatView, size: NSSize) {
        self.chatView = chatView
        super.init(nibName: nil, bundle: nil)
        // The window asks the content how big it wants to be, and
        // `InlineChatView` only ever answers with its minimum — it has no
        // intrinsic size, just floors. Left unanswered the window opens at
        // that minimum (232 points square) rather than the size asked for.
        // A preference, not a constraint: the window is still resizable, down
        // to the view's own minimum.
        preferredContentSize = size
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("ChatContentViewController is created in code, never from a nib")
    }

    override func loadView() {
        // The chat view goes *inside* a plain container rather than being the
        // content view itself. As the content view it was the root of its own
        // layout engine, with nothing tying its width to the window — and a
        // root whose width no constraint determines gets shrunk to the
        // smallest its own constraints allow, taking the window down with it
        // (a 232-point-wide window that could not be dragged wider). Pinned
        // inside a frame-driven container, its width is determined by the
        // container, and the container is sized by the window.
        let container = ChatContainerView(
            frame: NSRect(origin: .zero, size: preferredContentSize),
            themeScope: chatView.themeScope)
        chatView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(chatView)
        // Above the chat rather than inside it: the border traces the
        // *window's* edge, and the chat is only the thing that happens to fill
        // it. Click-through, so the composer still gets its clicks.
        let border = KeyWindowBorderView()
        border.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(border)
        NSLayoutConstraint.activate([
            chatView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            chatView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            chatView.topAnchor.constraint(equalTo: container.topAnchor),
            chatView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            border.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            border.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            border.topAnchor.constraint(equalTo: container.topAnchor),
            border.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        view = container
    }
}

private extension NSView {
    func firstEditableTextField() -> NSTextField? {
        if let field = self as? NSTextField, field.isEditable { return field }
        for sub in subviews {
            if let found = sub.firstEditableTextField() { return found }
        }
        return nil
    }
}
