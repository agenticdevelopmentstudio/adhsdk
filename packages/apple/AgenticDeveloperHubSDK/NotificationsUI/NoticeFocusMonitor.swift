import Foundation

/// Whether the user's Focus mode is on. While it is, the presentation center
/// holds notices below `now` and shows them when Focus ends.
///
/// A seam: reading the real Focus state needs the Focus Status entitlement,
/// which this round does not have, so the only shipped monitor is
/// `NeverFocused`. A host that gains the entitlement supplies its own monitor
/// and calls `NoticePresentationCenter.focusDidChange()` when it flips.
public protocol NoticeFocusMonitor {
    var isFocused: Bool { get }
}

/// The monitor that always reports "not focused", so nothing is ever held.
public struct NeverFocused: NoticeFocusMonitor {
    public init() {}
    public var isFocused: Bool { false }
}
