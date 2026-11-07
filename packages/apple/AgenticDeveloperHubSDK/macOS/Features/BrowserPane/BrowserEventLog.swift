//
//  BrowserEventLog.swift
//  AgenticDeveloperHubSDK
//

import AppKit
import Combine

/// One line of a browser pane's event log: what happened, on which channel,
/// and whether it reached the page.
public struct BrowserEventLogEntry: Sendable, Equatable {

    /// What became of the event.
    public enum Decision: String, Sendable {
        /// The user's event reached the page.
        case delivered
        /// The event was held back from the page.
        case withheld
        /// The agent's own event reached the page.
        case synthesized
        /// Not an input decision: a navigation, a window change, a setting.
        case info
    }

    public var date: Date
    public var channel: String
    public var event: String
    public var decision: Decision
    public var detail: String
    /// How many identical events this one line stands for (see
    /// `BrowserEventLog.coalescedEvents`).
    public var count: Int

    public init(date: Date, channel: String, event: String, decision: Decision, detail: String, count: Int = 1) {
        self.date = date
        self.channel = channel
        self.event = event
        self.decision = decision
        self.detail = detail
        self.count = count
    }
}

/// What a browser pane delivered to its page, withheld from it, and did
/// around it (spec section 12): an in-memory ring buffer owned by the pane.
///
/// Nothing here is ever written to disk, and typed characters are never
/// recorded — the key detail names named keys only, and calls every printable
/// character `"character"` (`keyDetail(for:)`), because characters typed into
/// a password field would otherwise sit in the log. It exists in release
/// builds too, so the recording code has one path; only debug builds show it.
@MainActor
public final class BrowserEventLog {

    /// Events that arrive in floods. A run of identical ones inside
    /// `coalescingWindow` is one line with a count, or the log would be
    /// nothing but pointer moves.
    static let coalescedEvents: Set<String> = ["mouseMoved", "scrollWheel"]

    /// The text-input calls an input method makes for a keystroke it handles
    /// asynchronously, after the keyDown the gate already decided. The same
    /// keystroke, reported twice, so it is folded into the keyDown's line.
    static let textInputEvents: Set<String> = [
        "insertText:", "insertText:replacementRange:", "setMarkedText:selectedRange:replacementRange:"
    ]

    /// How close in time two events must be to share a line.
    static let coalescingWindow: TimeInterval = 0.5

    public let capacity: Int
    public private(set) var entries: [BrowserEventLogEntry] = []
    /// Fires after every change to `entries`.
    public let changes: AnyPublisher<Void, Never>

    private let subject = PassthroughSubject<Void, Never>()
    private let now: () -> Date

    /// - Parameters:
    ///   - capacity: How many lines are kept; the oldest go first.
    ///   - now: The clock. Injected by tests of the coalescing window.
    public init(capacity: Int = 2000, now: @escaping () -> Date = Date.init) {
        self.capacity = max(1, capacity)
        self.now = now
        changes = subject.eraseToAnyPublisher()
    }

    /// Appends a line, or folds the event into the last one when it is the
    /// same flood event (a count) or the input method's second report of the
    /// keystroke the last line already holds (no new line, no count).
    public func record(
        channel: String,
        event: String,
        decision: BrowserEventLogEntry.Decision,
        detail: String = ""
    ) {
        let date = now()
        if let last = entries.last, date.timeIntervalSince(last.date) <= Self.coalescingWindow {
            if Self.coalescedEvents.contains(event), last.channel == channel, last.event == event,
               last.decision == decision {
                entries[entries.count - 1].count += 1
                entries[entries.count - 1].date = date
                subject.send()
                return
            }
            if Self.textInputEvents.contains(event), last.channel == channel, last.event == "keyDown",
               last.decision == decision {
                return
            }
        }
        entries.append(BrowserEventLogEntry(
            date: date, channel: channel, event: event, decision: decision, detail: detail))
        if entries.count > capacity { entries.removeFirst(entries.count - capacity) }
        subject.send()
    }

    public func clear() {
        guard !entries.isEmpty else { return }
        entries.removeAll()
        subject.send()
    }

    // MARK: - Key detail

    /// Named keys by their `charactersIgnoringModifiers` scalar.
    private static let namedKeys: [UInt32: String] = {
        var names: [UInt32: String] = [
            0x0D: "Return", 0x03: "Enter", 0x09: "Tab", 0x19: "Tab", 0x1B: "Escape",
            0x20: "Space", 0x7F: "Delete",
            UInt32(NSUpArrowFunctionKey): "Up", UInt32(NSDownArrowFunctionKey): "Down",
            UInt32(NSLeftArrowFunctionKey): "Left", UInt32(NSRightArrowFunctionKey): "Right",
            UInt32(NSDeleteFunctionKey): "Forward Delete",
            UInt32(NSHomeFunctionKey): "Home", UInt32(NSEndFunctionKey): "End",
            UInt32(NSPageUpFunctionKey): "Page Up", UInt32(NSPageDownFunctionKey): "Page Down"
        ]
        for index in 0..<35 { names[UInt32(NSF1FunctionKey) + UInt32(index)] = "F\(index + 1)" }
        return names
    }()

    /// The modifiers held, as the menu bar writes them.
    static func modifierSymbols(_ flags: NSEvent.ModifierFlags) -> String {
        var symbols = ""
        if flags.contains(.control) { symbols += "⌃" }
        if flags.contains(.option) { symbols += "⌥" }
        if flags.contains(.shift) { symbols += "⇧" }
        if flags.contains(.command) { symbols += "⌘" }
        return symbols
    }

    /// A key event's detail: the modifiers, then the key's name for a named
    /// key and `"character"` for anything else. The character itself is never
    /// returned. A flagsChanged event, which has no key, is its modifiers.
    public static func keyDetail(for event: NSEvent) -> String {
        let modifiers = modifierSymbols(event.modifierFlags.intersection(.deviceIndependentFlagsMask))
        guard event.type == .keyDown || event.type == .keyUp else { return modifiers }
        let key: String
        if let scalar = event.charactersIgnoringModifiers?.unicodeScalars.first,
           let name = namedKeys[scalar.value] {
            key = name
        } else {
            key = "character"
        }
        return modifiers + key
    }
}
