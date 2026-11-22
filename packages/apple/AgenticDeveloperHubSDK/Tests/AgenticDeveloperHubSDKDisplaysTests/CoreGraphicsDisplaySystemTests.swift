import CoreGraphics
import Testing
@testable import AgenticDeveloperHubSDKDisplays

/// True when CoreGraphics reports at least one online display. Headless
/// runners (CI without a window server session) have none, so the tests
/// that need real hardware are skipped there instead of failing.
private let hasOnlineDisplay: Bool = {
    var count: UInt32 = 0
    return CGGetOnlineDisplayList(0, nil, &count) == .success && count > 0
}()

/// True when at least one display is active. `onlineDisplays()` lists active
/// displays only (see `DisplaySystem`), and a display that is asleep is online
/// but not active, so while every screen sleeps it rightly lists none. The
/// tests that read the list need this, not `hasOnlineDisplay`.
private var hasActiveDisplay: Bool {
    var count: UInt32 = 0
    return CGGetActiveDisplayList(0, nil, &count) == .success && count > 0
}

@MainActor @Suite struct CoreGraphicsDisplaySystemTests {
    @Test(.enabled(if: hasActiveDisplay, "needs an awake display"))
    func listsTheMainDisplayAtOrigin() throws {
        let displays = CoreGraphicsDisplaySystem().onlineDisplays()
        let main = try #require(displays.first { $0.isMain })
        #expect(main.bounds.origin == .zero)
        #expect(main.identity.uuid != nil)
        #expect(main.frame.size == main.bounds.size)
    }

    @Test(.enabled(if: hasActiveDisplay, "needs an awake display"))
    func listsModesIncludingTheCurrentOne() throws {
        let system = CoreGraphicsDisplaySystem()
        let main = try #require(system.onlineDisplays().first { $0.isMain })
        let current = try #require(main.mode)
        #expect(system.modes(for: main.id).contains { $0.spec.matches(current.spec) })
    }

    /// Registering retains the handler; `cancel()` unregisters and releases
    /// it, and a second `cancel()` (or the token's deinit) does nothing more.
    @Test(.enabled(if: hasOnlineDisplay, "needs a window server session"))
    func observerCancelReleasesTheHandlerOnce() {
        final class Witness {}
        var witness: Witness? = Witness()
        weak let weakWitness = witness
        let observation = CoreGraphicsDisplaySystem().addReconfigurationObserver { [witness] in _ = witness }
        witness = nil
        #expect(weakWitness != nil)
        observation.cancel()
        #expect(weakWitness == nil)
        observation.cancel()
        #expect(weakWitness == nil)
    }
}
