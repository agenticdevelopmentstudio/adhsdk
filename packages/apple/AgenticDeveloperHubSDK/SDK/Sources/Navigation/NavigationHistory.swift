import Foundation

/// A back/forward trail: what a `‹ ›` control walks.
///
/// A value type with no reference to a view or a window: it records the places
/// visited and answers where the arrows should go. Keeping it free of any UI is
/// what makes the awkward part — that stepping backwards must not itself count
/// as a new step — testable without a window. The Settings window walks panel
/// indices with it; a document editor walks the files it has shown.
public struct NavigationHistory<Element: Equatable>: Equatable {

    /// Every visited place, oldest first, including the ones ahead of the
    /// cursor that a forward step would return to.
    private var entries: [Element] = []

    /// Index into `entries` of where the user is now; -1 before anything is
    /// visited.
    private var cursor: Int = -1

    public init() {}

    /// The place the user is on, or nil before anything is visited.
    public var current: Element? {
        entries.indices.contains(cursor) ? entries[cursor] : nil
    }

    /// Whether there is somewhere behind the current place to go back to — the
    /// enabled state of the `‹` segment.
    public var canGoBack: Bool { cursor > 0 }

    /// Whether a back step has left a trail ahead to return along — the enabled
    /// state of the `›` segment.
    public var canGoForward: Bool { cursor >= 0 && cursor < entries.count - 1 }

    /// Notes a place the user navigated *to*. Re-visiting the place already
    /// shown is not a step (clicking the selected row would otherwise stack up
    /// entries that all go nowhere), and a new step after going back discards
    /// the forward trail — the branch the user just left is no longer
    /// reachable, exactly as in a browser.
    public mutating func record(_ element: Element) {
        guard current != element else { return }
        if cursor < entries.count - 1 {
            entries.removeSubrange((cursor + 1)...)
        }
        entries.append(element)
        cursor = entries.count - 1
    }

    /// Steps back and returns the place to show, or nil at the start of the
    /// trail.
    public mutating func goBack() -> Element? {
        guard canGoBack else { return nil }
        cursor -= 1
        return entries[cursor]
    }

    /// Steps forward and returns the place to show, or nil at the end of the
    /// trail.
    public mutating func goForward() -> Element? {
        guard canGoForward else { return nil }
        cursor += 1
        return entries[cursor]
    }

    /// Forgets the whole trail, for when the places it names stop meaning
    /// anything (the list they index is replaced).
    public mutating func reset() {
        entries.removeAll()
        cursor = -1
    }
}

extension NavigationHistory: Sendable where Element: Sendable {}
