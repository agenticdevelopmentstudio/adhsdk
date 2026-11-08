import AppKit
import Testing
@testable import AgenticDeveloperHubSDKMenuBar

@MainActor
struct StatusBarImageControllerTests {
    private struct Call: Equatable { let monochrome: Bool; let dark: Bool }

    private func make(monochrome: Bool = false) -> (StatusBarImageController, () -> [Call], () -> Int) {
        var calls: [Call] = []
        var sunk = 0
        let controller = StatusBarImageController(
            // swiftlint:disable:next identifier_name
            provider: { m, d in
                calls.append(Call(monochrome: m, dark: d))
                return NSImage(size: NSSize(width: 18, height: 18))
            },
            sink: { _ in sunk += 1 }
        )
        controller.monochrome = monochrome
        return (controller, { calls }, { sunk })
    }

    @Test func applyAsksTheProviderForTheCurrentCellAndPushesItToTheSink() {
        let (controller, calls, sunk) = make()
        let before = sunk()
        controller.apply()
        #expect(calls().last == Call(monochrome: false, dark: StatusBarImageController.systemIsDark))
        #expect(sunk() == before + 1)
        #expect(controller.appliedIsDark == StatusBarImageController.systemIsDark)
    }

    @Test func flippingMonochromeReappliesWithTheNewValue() {
        let (controller, calls, _) = make()
        controller.monochrome = true
        #expect(calls().last?.monochrome == true)
        controller.monochrome = false
        #expect(calls().last?.monochrome == false)
    }

    @Test func currentImageReadsTheCheckboxAndTheSystem() {
        let (controller, calls, sunk) = make(monochrome: true)
        let before = sunk()
        _ = controller.currentImage()
        #expect(calls().last == Call(monochrome: true, dark: StatusBarImageController.systemIsDark))
        #expect(sunk() == before, "currentImage() renders; it does not push")
    }

    @Test func startAppliesOnceAndStopIsIdempotent() {
        let (controller, _, sunk) = make()
        let before = sunk()
        controller.start()
        #expect(sunk() == before + 1)
        controller.stop()
        controller.stop()
        #expect(sunk() == before + 1)
    }

    @Test func theSettleLoopGivesUpAfterTheLastDelay() {
        let (controller, _, sunk) = make()
        controller.apply()
        let before = sunk()

        // Replace the real dispatch-queue scheduler with a synchronous stand-in
        // that runs each re-read immediately and counts how many times it was
        // asked to schedule one. This drives the loop deterministically through
        // every `rereadDelays` step instead of asserting before the real
        // `DispatchQueue.main.asyncAfter` work has had a chance to run.
        var scheduledCount = 0
        controller.scheduleReread = { _, work in
            scheduledCount += 1
            work()
        }

        // `apply()` above already synced `appliedIsDark` to the live
        // `systemIsDark`, so every re-read sees "unchanged" and takes the
        // reschedule branch — exactly the case that must run out of attempts
        // rather than applying anyway.
        controller.applyWhenTheStyleSettles()

        #expect(
            scheduledCount == StatusBarImageController.rereadDelays.count,
            "must drive through every delay before giving up"
        )
        #expect(sunk() == before, "gave up after the last delay without applying anyway")
    }

    @Test func deinitRemovesTheThemeObserverSoItDoesNotOutliveTheController() {
        var controller: StatusBarImageController? = make().0
        controller?.start()

        // `DistributedNotificationCenter` retains a block-based observer
        // token internally until `removeObserver` is called for it — that's
        // the whole mechanism `start()`/`stop()` rely on. Hold only a *weak*
        // reference to the token from the test: if `stop()`'s cleanup never
        // runs (no `deinit`), the notification center's internal retain is
        // the only thing keeping the token alive, so it survives; if `deinit`
        // removes it, nothing retains it once the controller is gone and the
        // weak reference goes to `nil`.
        weak var observerToken: AnyObject?
        if let token = controller?.themeObserver {
            observerToken = token as AnyObject
        }
        #expect(observerToken != nil, "start() must have registered an observer")

        controller = nil // drop the only strong reference; deinit must run here

        #expect(
            observerToken == nil,
            """
            deinit must remove the observer, or it keeps firing (as a no-op via weak self) \
            and its token stays registered with DistributedNotificationCenter for the life of the process
            """
        )
    }

    @Test func aStatusBarSinkWritesMenuImage() {
        let statusBar = StatusBarAppDelegate(
            healthProbe: { nil },
            composer: MenuComposer(sections: []),
            menuIcon: "◎",
            refreshInterval: 60
        )
        let controller = StatusBarImageController(statusBar: statusBar) { _, _ in
            NSImage(size: NSSize(width: 18, height: 18))
        }
        #expect(statusBar.menuImage == nil)
        controller.apply()
        #expect(statusBar.menuImage != nil)
    }

    @Test func stopCancelsAnInFlightSettleSequence() async throws {
        let (controller, _, sunk) = make()
        controller.start()
        let afterStart = sunk()
        // Force the settle loop to see a changed appearance, so it would
        // reach `apply()` if `stop()` did not cut it off first. Without this,
        // `appliedIsDark` already matches the live `systemIsDark` and every
        // re-read takes the reschedule branch, never `apply()` — the test
        // would pass even against pre-fix code.
        controller.appliedIsDark = !StatusBarImageController.systemIsDark
        controller.applyWhenTheStyleSettles()
        controller.stop()
        let longerThanTheLongestDelay = (StatusBarImageController.rereadDelays.last ?? 0) + 0.2
        try await Task.sleep(nanoseconds: UInt64(longerThanTheLongestDelay * 1_000_000_000))
        #expect(sunk() == afterStart, "an in-flight settle sequence must not push after stop()")
    }

    /// The positive control for `stopCancelsAnInFlightSettleSequence`: the same
    /// forced-mismatch setup, but WITHOUT `stop()`, must actually reach
    /// `apply()` — proving the negative test's premise (that a push was
    /// otherwise on its way) rather than the sink simply never firing.
    @Test func aChangedAppearanceSettlesIntoOnePush() async throws {
        let (controller, _, sunk) = make()
        controller.start()
        let afterStart = sunk()
        controller.appliedIsDark = !StatusBarImageController.systemIsDark
        controller.applyWhenTheStyleSettles()
        let longerThanTheLongestDelay = (StatusBarImageController.rereadDelays.last ?? 0) + 0.2
        try await Task.sleep(nanoseconds: UInt64(longerThanTheLongestDelay * 1_000_000_000))
        #expect(sunk() == afterStart + 1, "a changed appearance settles into exactly one push")
        #expect(controller.appliedIsDark == StatusBarImageController.systemIsDark)
    }
}
