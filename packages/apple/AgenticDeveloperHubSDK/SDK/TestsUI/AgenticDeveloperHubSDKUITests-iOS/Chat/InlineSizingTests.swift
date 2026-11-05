import Testing
import Foundation
@testable import AgenticDeveloperHubSDKUI

/// `InlineChatSizing.resolve(engaged:)` is a pure function — these tests
/// exercise the state machine directly, never through layout, per Task 8's
/// third amendment.
@Suite("InlineChatSizing")
struct InlineSizingTests {

    @Test("tracksEngagement is true exactly when an inactive behaviour is configured")
    func tracksEngagementReflectsInactiveConfiguration() {
        let withInactive = InlineChatSizing(inactive: .minimal)
        let withoutInactive = InlineChatSizing()
        #expect(withInactive.resolve(engaged: true).tracksEngagement == true)
        #expect(withInactive.resolve(engaged: false).tracksEngagement == true)
        #expect(withoutInactive.resolve(engaged: true).tracksEngagement == false)
        #expect(withoutInactive.resolve(engaged: false).tracksEngagement == false)
    }

    @Test("the effective behaviour is active while engaged, inactive-or-active otherwise")
    func effectiveBehaviorFollowsEngagement() {
        let sizing = InlineChatSizing(
            active: .contentHugging(maxHeight: .points(400)),
            inactive: .behavior(.fixed))
        #expect(sizing.resolve(engaged: true).behavior == .behavior(.contentHugging(maxHeight: .points(400))))
        #expect(sizing.resolve(engaged: false).behavior == .behavior(.fixed))
    }

    @Test("an unconfigured inactive means the box is static and engaged changes nothing")
    func unconfiguredInactiveIsStatic() {
        // The compatibility guarantee `useChatSizing`'s comment calls out:
        // every existing call site with no `inactive` behaves identically
        // regardless of engagement.
        let sizing = InlineChatSizing(active: .contentHugging(maxHeight: .points(320)))
        let engaged = sizing.resolve(engaged: true)
        let disengaged = sizing.resolve(engaged: false)
        #expect(engaged == disengaged)
        #expect(engaged.behavior == .behavior(.contentHugging(maxHeight: .points(320))))
        #expect(engaged.tracksEngagement == false)
        #expect(engaged.collapsed == false)
        #expect(engaged.animates == false)
    }

    @Test("collapsed is true exactly when the resolved behaviour is minimal")
    func collapsedReflectsMinimalBehavior() {
        let sizing = InlineChatSizing(inactive: .minimal)
        #expect(sizing.resolve(engaged: false).collapsed == true)
        #expect(sizing.resolve(engaged: true).collapsed == false)

        let neverMinimal = InlineChatSizing(inactive: .behavior(.fixed))
        #expect(neverMinimal.resolve(engaged: false).collapsed == false)
    }

    @Test("animates is true only when the transition is animated and engagement is tracked")
    func animatesRequiresBothAnimatedTransitionAndTrackedEngagement() {
        let animatedTracked = InlineChatSizing(inactive: .minimal, transition: .animated)
        #expect(animatedTracked.resolve(engaged: false).animates == true)

        let noneTracked = InlineChatSizing(inactive: .minimal, transition: .none)
        #expect(noneTracked.resolve(engaged: false).animates == false)

        let animatedUntracked = InlineChatSizing(inactive: nil, transition: .animated)
        #expect(animatedUntracked.resolve(engaged: false).animates == false)
    }

    @Test("containerOffset and points caps round-trip through resolve unchanged")
    func sizeCapsRoundTrip() {
        let sizing = InlineChatSizing(active: .contentHugging(maxHeight: .containerOffset(topInset: 48)))
        let resolved = sizing.resolve(engaged: true)
        #expect(resolved.behavior == .behavior(.contentHugging(maxHeight: .containerOffset(topInset: 48))))
    }
}
