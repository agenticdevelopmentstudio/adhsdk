import Foundation

/// How a style set's "Dismiss after" reads in the popup: one of the presets,
/// or Custom… carrying a stored value that is not a preset.
///
/// Pure, so the mapping between a stored `autoDismiss` and the popup is
/// testable without a view.
enum DismissAfterChoice: Equatable {
    /// A preset: nil is Never, otherwise the seconds.
    case preset(TimeInterval?)
    /// Custom…, with the stored seconds.
    case custom(TimeInterval)

    /// The popup's presets, in order. nil is "Never".
    static let presets: [TimeInterval?] = [nil, 5, 8, 15, 30, 60]

    /// The seconds Custom… accepts, as a whole number.
    static let customRange: ClosedRange<Int> = 1...3600

    /// What the popup shows for a stored `autoDismiss`.
    init(seconds: TimeInterval?) {
        if Self.presets.contains(where: { $0 == seconds }) {
            self = .preset(seconds)
        } else if let seconds {
            self = .custom(seconds)
        } else {
            self = .preset(nil)
        }
    }

    /// The popup item's title: "Never", "8 seconds" or "Custom…".
    var title: String {
        switch self {
        case .preset(let seconds): seconds.map { Self.secondsTitle($0) } ?? "Never"
        case .custom: "Custom…"
        }
    }

    /// The seconds this choice stores, nil for Never.
    var seconds: TimeInterval? {
        switch self {
        case .preset(let seconds): seconds
        case .custom(let seconds): seconds
        }
    }

    /// The popup's items: every preset, then a Custom… placeholder (its seconds
    /// are the field's to say).
    static func popupChoices(custom: TimeInterval) -> [DismissAfterChoice] {
        presets.map(DismissAfterChoice.preset) + [.custom(custom)]
    }

    /// The popup item `self` selects, by kind: every Custom… is the same item.
    func isSameItem(as other: DismissAfterChoice) -> Bool {
        switch (self, other) {
        case (.custom, .custom): true
        default: self == other
        }
    }

    /// A whole number of seconds in `customRange` from what was typed; nil for
    /// anything else, so the field reverts.
    static func customSeconds(from text: String) -> TimeInterval? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard let value = Int(trimmed), customRange.contains(value) else { return nil }
        return TimeInterval(value)
    }

    private static func secondsTitle(_ seconds: TimeInterval) -> String {
        "\(Int(seconds)) seconds"
    }
}
