import CoreGraphics
import AgenticDeveloperHubSDKNotifications

/// Where each card of a stack goes, in screen coordinates (AppKit's: origin at
/// the bottom left). Pure math, so it is tested without a screen.
///
/// Index 0 is the newest card and sits nearest the anchor: the corner or edge
/// the position names. Top and center positions grow downward, bottom
/// positions grow upward. `center` puts the newest card in the middle of the
/// screen and stacks older ones below it, rising as far as it must to stay on
/// screen. Every frame is clamped inside `visible`, less the margin.
public enum ToastStackLayout {

    public static func frames(
        count: Int,
        cardSize: CGSize,
        in visible: CGRect,
        position: NoticeProfile.Position,
        spacing: CGFloat = 8,
        margin: CGFloat = 12
    ) -> [CGRect] {
        frames(
            sizes: Array(repeating: cardSize, count: max(0, count)),
            in: visible, position: position, spacing: spacing, margin: margin)
    }

    /// The same, for cards of differing heights — a hovered card grows to show
    /// its full details, and the cards beyond it move rather than overlap.
    public static func frames(
        sizes: [CGSize],
        in visible: CGRect,
        position: NoticeProfile.Position,
        spacing: CGFloat = 8,
        margin: CGFloat = 12
    ) -> [CGRect] {
        guard let first = sizes.first else { return [] }

        let growsDown: Bool
        var cursor: CGFloat
        switch position {
        case .topLeft, .topCenter:
            growsDown = true
            cursor = visible.maxY - margin
        case .center:
            growsDown = true
            // Newest in the middle, unless the stack would then run off the
            // bottom: then it rises just enough to fit.
            let total = sizes.map(\.height).reduce(0, +) + spacing * CGFloat(sizes.count - 1)
            cursor = min(
                max(visible.midY + first.height / 2, visible.minY + margin + total),
                visible.maxY - margin)
        case .bottomLeft, .bottomCenter, .bottomRight:
            growsDown = false
            cursor = visible.minY + margin
        }

        return sizes.map { size in
            let originX: CGFloat
            switch position {
            case .topLeft, .bottomLeft:
                originX = visible.minX + margin
            case .bottomRight:
                originX = visible.maxX - margin - size.width
            case .topCenter, .bottomCenter, .center:
                originX = visible.midX - size.width / 2
            }
            let originY: CGFloat
            if growsDown {
                originY = cursor - size.height
                cursor = originY - spacing
            } else {
                originY = cursor
                cursor = originY + size.height + spacing
            }
            // A stack taller than the screen keeps every card on it; the
            // oldest overlap at the far edge rather than vanish past it.
            let clampedY = max(visible.minY + margin, min(originY, visible.maxY - margin - size.height))
            return CGRect(x: originX, y: clampedY, width: size.width, height: size.height)
        }
    }
}
