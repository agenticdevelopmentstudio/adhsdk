import Testing
import AppKit
import Foundation
import AgenticDeveloperHubSDK
@testable import AgenticDeveloperHubSDKUI

/// Covers `InlineChatView`'s sizing/engagement wiring — amendment 6 of
/// Task 8: `sizing` plus AppKit-side engagement tracking. Kept separate from
/// `InlineChatViewTests.swift`, which must stay unedited and passing: that
/// file never sets `sizing`, so the default `InlineChatSizing()` (no
/// `inactive` configured) must keep reproducing today's fixed-height
/// behaviour exactly, and this suite is where that guarantee — and the new
/// collapse/animate behaviour — gets pinned.
@MainActor
@Suite("InlineChatView sizing")
struct InlineChatViewSizingTests {

    private func makeManager(activeThemeID: String) -> ThemeManager {
        ThemeManager(storage: InMemoryThemeStorage(activeThemeID: activeThemeID))
    }

    private func makeView(localParticipantID: String = "user-1") -> (InlineChatView, ObservableChatViewModel, FakeBackend) {
        let backend = FakeBackend()
        let viewModel = ObservableChatViewModel(backend: backend, localParticipantID: localParticipantID)
        let view = InlineChatView(viewModel: viewModel, localParticipantID: localParticipantID)
        view.frame = NSRect(x: 0, y: 0, width: 400, height: 500)
        view.layoutSubtreeIfNeeded()
        return (view, viewModel, backend)
    }

    @Test("the default sizing (no inactive configured) never tracks engagement, so the transcript stays visible")
    func defaultSizingIsStaticRegardlessOfEngagement() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()

        #expect(view.sizing.resolve(engaged: false).tracksEngagement == false)
        view.engaged = true
        #expect(view.transcriptScroll.isHidden == false)
        view.engaged = false
        #expect(view.transcriptScroll.isHidden == false)
    }

    @Test("inactive: .minimal collapses the transcript when disengaged, and engaging expands it")
    func minimalInactiveCollapsesWhenDisengaged() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()
        view.sizing = InlineChatSizing(active: .fixed, inactive: .minimal, transition: .none)

        // Freshly constructed engagement default is `false`, so an
        // `.minimal` inactive behaviour must already be collapsed.
        #expect(view.transcriptScroll.isHidden == true)

        view.engaged = true
        #expect(view.transcriptScroll.isHidden == false)

        view.engaged = false
        #expect(view.transcriptScroll.isHidden == true)
    }

    @Test("controlTextDidBeginEditing engages the view; controlTextDidEndEditing disengages it")
    func focusInAndOutTrackEngagement() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()
        view.sizing = InlineChatSizing(active: .fixed, inactive: .minimal, transition: .none)
        #expect(view.engaged == false)

        view.controlTextDidBeginEditing(Notification(name: NSControl.textDidBeginEditingNotification))
        #expect(view.engaged == true)

        view.controlTextDidEndEditing(Notification(name: NSControl.textDidEndEditingNotification))
        #expect(view.engaged == false)
    }

    @Test("Escape (cancelOperation) disengages the view")
    func escapeDisengages() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()
        view.sizing = InlineChatSizing(active: .fixed, inactive: .minimal, transition: .none)
        view.engaged = true

        let handled = view.control(
            NSControl(), textView: NSTextView(),
            doCommandBy: #selector(NSResponder.cancelOperation(_:)))

        #expect(handled == true)
        #expect(view.engaged == false)
    }

    @Test("a points cap is installed as a cap, not a floor")
    func contentHuggingPointsCapSetsHeight() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()
        view.sizing = InlineChatSizing(
            active: .contentHugging(maxHeight: .points(120)), inactive: .minimal, transition: .none)
        view.engaged = true
        view.layoutSubtreeIfNeeded()

        #expect(view.transcriptScroll.isHidden == false)
        #expect(view.transcriptHeightConstraint.constant == 120)
        // The relation is the whole point: `maxHeight` written into a `>=`
        // constraint would make the cap a minimum instead.
        #expect(view.transcriptHeightConstraint.relation == .lessThanOrEqual)
    }

    @Test("each behaviour installs its own relation: floor, cap, exact zero")
    func eachBehaviourInstallsItsOwnRelation() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()

        // `.fixed` is the default, so this is also today's shipped behaviour.
        #expect(view.transcriptHeightConstraint.relation == .greaterThanOrEqual)
        #expect(view.transcriptHeightConstraint.constant == 200)

        view.sizing = InlineChatSizing(active: .fixed, inactive: .minimal, transition: .none)
        // Disengaged, so `.minimal` is in effect: an exact zero, because
        // `isHidden` alone leaves the old height constraint in force.
        #expect(view.transcriptHeightConstraint.relation == .equal)
        #expect(view.transcriptHeightConstraint.constant == 0)

        view.engaged = true
        #expect(view.transcriptHeightConstraint.relation == .greaterThanOrEqual)
        #expect(view.transcriptHeightConstraint.constant == 200)
    }

    @Test("a containerOffset cap tracks the view's height instead of freezing at init")
    func containerOffsetCapTracksBounds() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()
        view.sizing = InlineChatSizing(
            active: .contentHugging(maxHeight: .containerOffset(topInset: 60)),
            inactive: .minimal, transition: .none)
        view.engaged = true
        view.layoutSubtreeIfNeeded()

        // makeView() gave the view a 500pt height, so the cap is 500 - 60.
        #expect(view.transcriptHeightConstraint.constant == 440)

        view.frame = NSRect(x: 0, y: 0, width: 400, height: 300)
        view.layoutSubtreeIfNeeded()
        #expect(view.transcriptHeightConstraint.constant == 240)
    }

    @Test("focus moving into the transcript keeps the box engaged")
    func focusMovingIntoTheTranscriptKeepsEngagement() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()

        #expect(view.shouldStayEngaged(afterFocusMovingTo: view.transcriptScroll))
        #expect(view.shouldStayEngaged(afterFocusMovingTo: view.transcriptScroll.contentView))
        #expect(!view.shouldStayEngaged(afterFocusMovingTo: NSView()))
        #expect(!view.shouldStayEngaged(afterFocusMovingTo: nil))
        // The composer's own field editor is a descendant of the view but not
        // of the transcript, so ending editing there still disengages.
        #expect(!view.shouldStayEngaged(afterFocusMovingTo: view))
    }

    @Test("animates is true only when the transition is .animated and inactive is configured")
    func animatesReflectsResolvedSizing() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()

        view.sizing = InlineChatSizing(active: .fixed, inactive: .minimal, transition: .animated)
        #expect(view.sizing.resolve(engaged: view.engaged).animates == true)

        view.sizing = InlineChatSizing(active: .fixed, inactive: nil, transition: .animated)
        #expect(view.sizing.resolve(engaged: view.engaged).animates == false)
    }

    /// The three rows stack: transcript, hairline, composer. A `divider` left
    /// with its autoresizing translation on had required constraints pinning
    /// it to (0, 0, 0, 0), and because `divider.top == transcript.bottom` and
    /// `composer.top == divider.bottom`, that zeroed the composer and gave the
    /// transcript the entire view — a chat window with no place to type, and
    /// no constraint conflict logged to say why.
    @Test("the divider and composer get their own rows, so the transcript never fills the view")
    func composerKeepsItsRow() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()

        #expect(view.transcriptScroll.frame.height < view.frame.height)

        // `setupViews()` adds them in this order: transcript, status row,
        // divider, composer.
        let divider = view.subviews[2]
        let composer = view.subviews[3]
        #expect(divider.frame.height == 1)
        #expect(divider.frame.width == view.frame.width)
        #expect(composer.frame.height > 0)
        #expect(composer.frame.width == view.frame.width)
    }

    /// Every horizontal constraint in the view pins a subview to the view's
    /// own edges, so width flows outward from the host and nothing inside
    /// asks for any. Before the floor existed, `fittingSize.width` was 0 —
    /// and an `NSWindow` given this as its `contentView` collapsed to a
    /// zero-width window that drew nothing and could not be dragged open
    /// again. The floor has to be *required*: at priority 999 it left
    /// `fittingSize.width` at 0, because a view's fitting size is settled by
    /// its required constraints alone.
    @Test("the view has a required minimum width, so a host sizing to it never collapses")
    func minimumWidthKeepsTheViewFromCollapsing() {
        _ = makeManager(activeThemeID: BuiltInThemes.solarizedDark.id)
        let (view, _, _) = makeView()

        #expect(view.fittingSize.width == 232)

        let floors = view.constraints.filter {
            $0.firstItem === view && $0.firstAttribute == .width && $0.relation == .greaterThanOrEqual
        }
        #expect(floors.count == 1)
        #expect(floors.first?.priority == .required)
    }
}
