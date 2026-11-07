import CoreGraphics
import AgenticDeveloperHubSDKNotifications

/// The frame of a toast stack's window, in screen coordinates (AppKit's:
/// origin at the bottom left). Pure math, so it is tested without a screen.
///
/// The window always reserves room for its hover chrome, so the chrome
/// appearing never moves a card: `margin` on every side of the cards, plus a
/// `barHeight` strip on the side away from the anchor, where the title bar
/// goes. The cards sit exactly where `ToastStackLayout` would put them.
public enum ToastStackGeometry {

    /// Which edge of the window the title bar is on.
    public enum Edge: Equatable, Sendable {
        case top, bottom
    }

    public static let margin: CGFloat = 8
    public static let barHeight: CGFloat = 22
    public static let cardSpacing: CGFloat = 8
    /// How far from the screen edge the cards sit when anchored there.
    public static let screenMargin: CGFloat = 12

    /// Away from the anchor: bottom positions get the bar on top, top
    /// positions on the bottom, and center on top.
    nonisolated public static func titleBarEdge(for position: NoticeProfile.Position) -> Edge {
        switch position {
        case .topLeft, .topCenter: .bottom
        case .center, .bottomLeft, .bottomCenter, .bottomRight: .top
        }
    }

    /// The window for a stack whose cards, spaced and stacked, measure
    /// `stackSize`: anchored at `position` on `visible`, moved by `offset`,
    /// then kept inside `visible`.
    nonisolated public static func windowFrame(
        stackSize: CGSize,
        position: NoticeProfile.Position,
        visible: CGRect,
        offset: NoticeStackOffset
    ) -> CGRect {
        let block = ToastStackLayout.frames(
            sizes: [stackSize], in: visible, position: position,
            spacing: cardSpacing, margin: screenMargin)[0]
        let barBelow = titleBarEdge(for: position) == .bottom
        let anchored = CGRect(
            x: block.minX - margin,
            y: block.minY - margin - (barBelow ? barHeight : 0),
            width: block.width + 2 * margin,
            height: block.height + 2 * margin + barHeight)
        return clamp(anchored.offsetBy(dx: offset.dx, dy: offset.dy), to: visible)
    }

    /// The part of a window's bounds the cards occupy, in the window's own
    /// coordinates (origin bottom left).
    nonisolated public static func cardArea(inWindowSize size: CGSize, position: NoticeProfile.Position) -> CGRect {
        let barBelow = titleBarEdge(for: position) == .bottom
        return CGRect(
            x: margin, y: margin + (barBelow ? barHeight : 0),
            width: max(0, size.width - 2 * margin), height: max(0, size.height - 2 * margin - barHeight))
    }

    /// The title bar's strip, in the window's own coordinates.
    nonisolated public static func barArea(inWindowSize size: CGSize, position: NoticeProfile.Position) -> CGRect {
        let atTop = titleBarEdge(for: position) == .top
        return CGRect(x: 0, y: atTop ? size.height - barHeight : 0, width: size.width, height: barHeight)
    }

    /// `frame` moved the least that puts it inside `visible`; a frame larger
    /// than `visible` is pinned to its bottom left.
    nonisolated public static func clamp(_ frame: CGRect, to visible: CGRect) -> CGRect {
        var result = frame
        result.origin.x = max(visible.minX, min(frame.minX, visible.maxX - frame.width))
        result.origin.y = max(visible.minY, min(frame.minY, visible.maxY - frame.height))
        return result
    }

    /// How far `frame` is from `anchoredFrame`: what a drag saves.
    nonisolated public static func offset(of frame: CGRect, from anchoredFrame: CGRect) -> NoticeStackOffset {
        NoticeStackOffset(dx: frame.minX - anchoredFrame.minX, dy: frame.minY - anchoredFrame.minY)
    }
}
