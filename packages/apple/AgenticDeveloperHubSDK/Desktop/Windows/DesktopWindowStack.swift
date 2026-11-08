import CoreGraphics
import Foundation

/// The open App windows, back to front. Opening an open App raises it instead of duplicating it.
public struct DesktopWindowStack: Sendable, Equatable {
    public struct Entry: Sendable, Equatable {
        public let id: String
        public var frame: CGRect
    }

    public private(set) var entries: [Entry] = []

    public init() {}

    public var frontID: String? { entries.last?.id }

    /// Returns true if newly opened; if already open, raises it and returns false.
    public mutating func open(_ id: String, frame: CGRect) -> Bool {
        if entries.contains(where: { $0.id == id }) {
            bringToFront(id)
            return false
        }
        entries.append(Entry(id: id, frame: frame))
        return true
    }

    public mutating func bringToFront(_ id: String) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries.append(entries.remove(at: index))
    }

    public mutating func close(_ id: String) {
        entries.removeAll { $0.id == id }
    }

    public mutating func setFrame(_ frame: CGRect, for id: String) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].frame = frame
    }
}
