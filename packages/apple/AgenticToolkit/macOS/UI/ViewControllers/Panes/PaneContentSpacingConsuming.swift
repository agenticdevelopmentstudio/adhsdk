import AppKit

/// Adopted by pane content that insets itself — a terminal holds its grid off
/// its own edges, because a theme may override that padding.
///
/// The rule is "one gap, not a second padding stacked on the first", and this
/// is what decides who applies it: content that adopts this is handed the
/// app-wide pane-content spacing (`PaneSpacing.contentSpacing`) and does the
/// insetting, and its pane pins it flush. Content that does not adopt it has
/// the gap applied for it, by the pane. Exactly one of the two, chosen by a
/// conformance rather than by the pane knowing what a terminal is
/// (`explicit-over-implicit`).
@MainActor
public protocol PaneContentSpacingConsuming: AnyObject {

    /// Apply this gap. The pane pins the content flush, so nothing is applied
    /// twice. Called again whenever the setting changes.
    func applyPaneSpacing(_ spacing: Spacing)
}
