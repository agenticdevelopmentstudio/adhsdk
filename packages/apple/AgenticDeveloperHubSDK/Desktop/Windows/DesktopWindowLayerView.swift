import AppKit

/// Renders `DesktopWindowStack`: one chrome view per open window, back to front.
/// Flipped, so window frames use a top-left origin. Clicks that miss every window
/// fall through to the icons underneath.
final class DesktopWindowLayerView: NSView {
    private(set) var stack = DesktopWindowStack()
    private var chromes: [String: DesktopWindowChromeView] = [:]
    /// Called after a window opens, closes, or comes to the front.
    var onStackChange: (() -> Void)?

    override var isFlipped: Bool { true }

    /// Window identifiers, back to front.
    var identifiers: [String] { stack.entries.map(\.id) }

    func contains(_ id: String) -> Bool { chromes[id] != nil }

    func chrome(for id: String) -> DesktopWindowChromeView? { chromes[id] }

    /// Opens a window; one already open is raised instead and `chrome` is ignored.
    func open(id: String, chrome: DesktopWindowChromeView, frame: CGRect) {
        guard stack.open(id, frame: frame) else {
            render()
            return
        }
        chromes[id] = chrome
        chrome.frame = frame
        chrome.onActivate = { [weak self] in self?.bringToFront(id) }
        chrome.onFrameChange = { [weak self] in self?.stack.setFrame($0, for: id) }
        addSubview(chrome)
        render()
    }

    func bringToFront(_ id: String) {
        guard stack.frontID != id else { return }
        stack.bringToFront(id)
        render()
    }

    func close(_ id: String) {
        stack.close(id)
        chromes.removeValue(forKey: id)?.removeFromSuperview()
        render()
    }

    /// Orders the chrome views to match the stack and marks the front one active.
    /// Reorders in place, so a window's first responder and tracking survive a raise.
    private func render() {
        let ordered = stack.entries.compactMap { chromes[$0.id] }
        if subviews != ordered {
            let ranks = RankBox(Dictionary(
                uniqueKeysWithValues: ordered.enumerated().map { (ObjectIdentifier($1), $0) }
            ))
            sortSubviews({ first, second, context in
                guard let context else { return .orderedSame }
                let box = Unmanaged<RankBox>.fromOpaque(context).takeUnretainedValue()
                let lhs = box.ranks[ObjectIdentifier(first)] ?? 0
                let rhs = box.ranks[ObjectIdentifier(second)] ?? 0
                return lhs < rhs ? .orderedAscending : (lhs > rhs ? .orderedDescending : .orderedSame)
            }, context: Unmanaged.passUnretained(ranks).toOpaque())
            withExtendedLifetime(ranks) {}
        }
        for entry in stack.entries {
            chromes[entry.id]?.isActive = entry.id == stack.frontID
        }
        onStackChange?()
    }

    private final class RankBox {
        let ranks: [ObjectIdentifier: Int]
        init(_ ranks: [ObjectIdentifier: Int]) { self.ranks = ranks }
    }

    /// A press raises its window here, at dispatch time, before the content sees the click.
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let hit = super.hitTest(point), hit !== self else { return nil }
        if NSApp.currentEvent?.type == .leftMouseDown, let id = identifier(owning: hit) {
            bringToFront(id)
        }
        return hit
    }

    private func identifier(owning view: NSView) -> String? {
        var current: NSView? = view
        while let candidate = current {
            if let chrome = candidate as? DesktopWindowChromeView {
                return chromes.first { $0.value === chrome }?.key
            }
            current = candidate.superview
        }
        return nil
    }

    /// Windows stay reachable when the Desktop shrinks. Never writes settings.
    override func layout() {
        super.layout()
        guard bounds.width > 0, bounds.height > 0 else { return }
        for (id, chrome) in chromes {
            let clamped = DesktopWindowChromeView.clamped(
                chrome.frame, in: bounds.size, minimum: chrome.minimumWindowSize
            )
            if clamped != chrome.frame {
                chrome.frame = clamped
                stack.setFrame(clamped, for: id)
            }
        }
    }
}
