import AppKit

/// Keeps a status item's image in step with the system appearance and one
/// app-owned "monochrome" switch. The image itself comes from `provider`;
/// this class only knows *when* to ask for a new one and where to put it.
///
/// Appearance changes are announced by `AppleInterfaceThemeChangedNotification`,
/// which fires before `AppleInterfaceStyle` is updated in `UserDefaults`; the
/// controller re-reads on a short schedule until the value it sees differs
/// from the one it last applied, then stops.
@MainActor
public final class StatusBarImageController {
    public typealias Provider = @MainActor (_ monochrome: Bool, _ systemIsDark: Bool) -> NSImage

    private let provider: Provider
    private let sink: @MainActor (NSImage) -> Void

    /// The live `DistributedNotificationCenter` observer registered by
    /// `start()`, or `nil` when not observing. `nonisolated(unsafe)` because
    /// `deinit` (which is not MainActor-isolated and cannot hop) must read
    /// and clear it directly to remove the observer on deallocation; every
    /// other access to this property runs on the main actor like the rest of
    /// the class, and by the time `deinit` runs no other access is possible,
    /// so the exclusivity Swift can't prove statically is guaranteed
    /// dynamically. Internal (not `private`) so a same-module test can hold a
    /// *weak* reference to the token and confirm it is released — i.e. that
    /// removal actually ran — once the controller deallocates, the same
    /// pattern `appliedIsDark` uses to give tests a hook without widening the
    /// public API.
    nonisolated(unsafe) var themeObserver: NSObjectProtocol?

    /// The app's switch: `true` asks the provider for a monochrome image in
    /// every appearance.
    public var monochrome = false {
        didSet { if monochrome != oldValue { apply() } }
    }

    /// The appearance the last `apply()` rendered for; `nil` before the first.
    /// Internal (not `private(set)`) so a same-module test can force a
    /// mismatch against the live `systemIsDark` without waiting on the real
    /// appearance to change.
    var appliedIsDark: Bool?

    static let rereadDelays: [TimeInterval] = [0, 0.05, 0.1, 0.2, 0.3, 0.5]

    /// Bumped by every `start()`/`stop()`. A settle re-read closure captures the
    /// generation it was scheduled under and checks it before doing anything —
    /// so `stop()` (or a `start()` that begins a new one) invalidates any
    /// re-read still sitting on the main queue, rather than letting it push an
    /// image through the sink up to `rereadDelays.last` seconds after the
    /// controller was told to stop.
    private var generation = 0

    /// Schedules one settle re-read `delay` seconds out. Defaults to the real
    /// main-queue dispatch; internal (not private) so a same-module test can
    /// substitute a synchronous stand-in and drive the settle loop through
    /// every `rereadDelays` step deterministically instead of racing real
    /// timers.
    ///
    /// The re-read itself is `@Sendable` because the default implementation
    /// hands it to `DispatchQueue.asyncAfter`, which crosses a concurrency
    /// domain to run it. Only the *parameter* carries the annotation: the
    /// property's own type stays non-`Sendable` so a test stand-in may still
    /// close over and mutate its own local state.
    var scheduleReread: (TimeInterval, @escaping @Sendable () -> Void) -> Void = { delay, work in
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    public init(provider: @escaping Provider, sink: @escaping @MainActor (NSImage) -> Void) {
        self.provider = provider
        self.sink = sink
    }

    public convenience init(statusBar: StatusBarAppDelegate, provider: @escaping Provider) {
        self.init(provider: provider) { [weak statusBar] image in statusBar?.menuImage = image }
    }

    /// Removes the distributed-notification observer directly (rather than
    /// calling `stop()`, which is MainActor-isolated and cannot be invoked
    /// from a nonisolated `deinit`) so a controller deallocated without an
    /// explicit `stop()` doesn't leave a live registration for the rest of
    /// the process, firing on every theme change and holding this instance's
    /// captures alive indefinitely.
    deinit {
        if let themeObserver {
            DistributedNotificationCenter.default().removeObserver(themeObserver)
        }
    }

    /// `true` when the menu bar is dark: `AppleInterfaceStyle` is "Dark", or
    /// absent when light.
    public static var systemIsDark: Bool {
        UserDefaults.standard.string(forKey: "AppleInterfaceStyle")?.lowercased().hasPrefix("dark") ?? false
    }

    /// The image for the current switch and appearance, without pushing it.
    public func currentImage() -> NSImage {
        provider(monochrome, Self.systemIsDark)
    }

    /// Push an image now and follow the appearance from here on.
    public func start() {
        stop()
        apply()
        themeObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.applyWhenTheStyleSettles() }
        }
    }

    /// Stops following the appearance. Any settle re-read already scheduled by
    /// `applyWhenTheStyleSettles` becomes a no-op — it checks the generation
    /// this bumps before touching the sink, so nothing arrives after `stop()`
    /// returns. Idempotent: calling it again (or from `deinit` after an
    /// explicit `stop()` already ran) is a harmless no-op since `themeObserver`
    /// is already `nil`.
    public func stop() {
        generation += 1
        if let themeObserver {
            DistributedNotificationCenter.default().removeObserver(themeObserver)
            self.themeObserver = nil
        }
    }

    func applyWhenTheStyleSettles(attempt: Int = 0) {
        guard attempt < Self.rereadDelays.count else { return }
        let generationAtSchedule = generation
        scheduleReread(Self.rereadDelays[attempt]) { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.generation == generationAtSchedule else { return }
                if Self.systemIsDark != self.appliedIsDark {
                    self.apply()
                } else {
                    self.applyWhenTheStyleSettles(attempt: attempt + 1)
                }
            }
        }
    }

    func apply() {
        let dark = Self.systemIsDark
        appliedIsDark = dark
        sink(provider(monochrome, dark))
    }
}
