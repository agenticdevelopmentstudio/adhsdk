import CoreGraphics
import AgenticDeveloperHubSDKNotifications

/// Where each card of a stack goes, in screen coordinates (AppKit's: origin at
/// the bottom left). Pure math, so it is tested without a screen.
///
/// Index 0 is the newest card and sits nearest the anchor: the corner or edge
/// the position names. Top and center positions grow downward, bottom
/// positions grow upward. `center` puts the newest card in the middle of the
/// screen and stacks older ones below it.
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
        case .topLeft, .topCenter, .topRight:
            growsDown = true
            cursor = visible.maxY - margin
        case .center:
            growsDown = true
            cursor = visible.midY + first.height / 2
        case .bottomLeft, .bottomCenter, .bottomRight:
            growsDown = false
            cursor = visible.minY + margin
        }

        return sizes.map { size in
            let originX: CGFloat
            switch position {
            case .topLeft, .bottomLeft:
                originX = visible.minX + margin
            case .topRight, .bottomRight:
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
            return CGRect(x: originX, y: originY, width: size.width, height: size.height)
        }
    }
}
