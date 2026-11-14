import AppKit

/// Locks the vertical scroll of several `LineViewerViewController`s together:
/// whichever is scrolled, the others follow to the same vertical offset, each
/// keeping its own horizontal one. Rows are assumed aligned (side-by-side diff
/// pads with filler rows). Holds the viewers' clip views weakly; keep the sync
/// alive as long as the lock should hold.
@MainActor
public final class LineViewerScrollSync {

    private struct Member {
        weak var clip: NSClipView?
    }

    private let members: [Member]
    private var observers: [NSObjectProtocol] = []
    private var isFollowing = false

    public init(_ viewers: [LineViewerViewController]) {
        let clips = viewers.map { $0.scrollView.contentView }
        members = clips.map { Member(clip: $0) }
        for clip in clips {
            clip.postsBoundsChangedNotifications = true
            observers.append(NotificationCenter.default.addObserver(
                forName: NSView.boundsDidChangeNotification, object: clip, queue: nil
            ) { [weak self, weak clip] _ in
                MainActor.assumeIsolated {
                    guard let self, let clip else { return }
                    self.follow(clip)
                }
            })
        }
    }

    isolated deinit {
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
    }

    private func follow(_ source: NSClipView) {
        guard !isFollowing else { return }
        isFollowing = true
        defer { isFollowing = false }
        let top = source.bounds.origin.y
        for member in members {
            guard let clip = member.clip, clip !== source, clip.bounds.origin.y != top else { continue }
            clip.scroll(to: NSPoint(x: clip.bounds.origin.x, y: top))
            (clip.superview as? NSScrollView)?.reflectScrolledClipView(clip)
        }
    }
}
