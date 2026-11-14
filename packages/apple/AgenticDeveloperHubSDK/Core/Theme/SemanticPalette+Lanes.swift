import Foundation

extension SemanticPalette {

    /// The ANSI slots that colour graph lanes (and avatars), in cycle order:
    /// the six normal hues, then the six bright ones. Black and white, normal
    /// and bright, are left out because one of each pair vanishes into any
    /// background (recipe `ui/components/display/commit-graph-cell`).
    public static let laneANSISlots = [1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13, 14]

    /// How many distinct lane colours there are before the cycle repeats.
    public static var laneCount: Int { laneANSISlots.count }

    /// The colour of `lane`, cycling `laneANSISlots`; a slot the theme lacks
    /// (hand-authored schemes need not carry all 16) falls back to `accent`.
    public func laneColor(_ lane: Int) -> RGBAColor {
        let count = Self.laneCount
        let slot = Self.laneANSISlots[((lane % count) + count) % count]
        return theme.ansiColor(at: slot) ?? color(.accent)
    }
}
