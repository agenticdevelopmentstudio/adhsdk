import Foundation

/// How large an inline chat surface's box is allowed to grow. Web's
/// `useChatSizing` expresses the same cap as `{ kind: 'css', value: string }`
/// (a CSS length) or `{ kind: 'element-offset', ref: RefObject }` (a DOM
/// node's offset) — both DOM-bound encodings with no Apple-side equivalent.
/// This is the *behaviour* those two reduce to on a host that already has its
/// own frame: a fixed size, or a cap that keeps the box's top edge below a
/// point measured from the container's top.
public enum ChatSizeCap: Sendable, Equatable {
    case points(CGFloat)
    /// Cap the box so its top edge stops `topInset` below the container's
    /// top — the Apple-side stand-in for web's `viewport-offset` *and*
    /// `element-offset`, both of which reduce to one number a host can
    /// compute. No `ref` equivalent: an Apple host has the frame already.
    case containerOffset(topInset: CGFloat)
}

/// A sizing behaviour: fixed, or hugging content up to a cap.
public enum ChatSizingBehavior: Sendable, Equatable {
    case fixed
    case contentHugging(maxHeight: ChatSizeCap)
}

/// The behaviour in effect while the box is *not* engaged. `.behavior` names
/// an explicit `ChatSizingBehavior`; `.minimal` collapses the box to its
/// input bar — there is no `ChatSizingBehavior` case for that because
/// "minimal" isn't a size, it's the absence of the transcript.
public enum InactiveSizingBehavior: Sendable, Equatable {
    case behavior(ChatSizingBehavior)
    case minimal
}

/// Whether a resolved sizing change animates.
public enum SizingTransition: Sendable, Equatable { case none, animated }

/// Config for an inline chat surface's sizing. Mirrors `useChatSizing`'s
/// props: an `active` behaviour always in effect while engaged, an optional
/// `inactive` behaviour for while it is not (`nil` means the box is static
/// and engagement changes nothing — the hook's documented compatibility
/// guarantee), and whether a resolved change animates.
public struct InlineChatSizing: Sendable, Equatable {
    public var active: ChatSizingBehavior
    public var inactive: InactiveSizingBehavior?
    public var transition: SizingTransition

    public init(
        active: ChatSizingBehavior = .fixed,
        inactive: InactiveSizingBehavior? = nil,
        transition: SizingTransition = .animated
    ) {
        self.active = active
        self.inactive = inactive
        self.transition = transition
    }

    /// Resolves this config against whether the box is currently engaged.
    /// Pure — a view calls this on every engagement change and applies the
    /// result; it is what makes the state machine testable without layout.
    ///
    /// Reproduces `useChatSizing` lines 35, 43, 70–72 and 152–154 exactly:
    /// `tracksEngagement` is `inactive != nil`; the effective behaviour is
    /// `engaged ? .behavior(active) : (inactive ?? .behavior(active))`;
    /// `collapsed` is that behaviour being `.minimal`; `animates` is
    /// `transition == .animated && tracksEngagement`.
    public func resolve(engaged: Bool) -> ResolvedChatSizing {
        let tracksEngagement = inactive != nil
        let behavior: InactiveSizingBehavior = engaged ? .behavior(active) : (inactive ?? .behavior(active))
        let collapsed: Bool
        if case .minimal = behavior {
            collapsed = true
        } else {
            collapsed = false
        }
        let animates = transition == .animated && tracksEngagement
        return ResolvedChatSizing(
            behavior: behavior, collapsed: collapsed, tracksEngagement: tracksEngagement, animates: animates)
    }
}

/// What the view actually applies. The whole point of the split: this is a
/// pure function of (config, engaged), so the state machine is exercised
/// directly and never through layout.
public struct ResolvedChatSizing: Sendable, Equatable {
    public let behavior: InactiveSizingBehavior
    public let collapsed: Bool
    public let tracksEngagement: Bool
    public let animates: Bool
}
