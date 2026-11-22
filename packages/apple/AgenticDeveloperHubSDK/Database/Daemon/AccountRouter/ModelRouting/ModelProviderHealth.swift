#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// Providers that fell back recently. Thread memory pins only the thread that
/// fell back; this keeps every new thread off a failing or hung provider for
/// `cooldown`, so each one does not wait out the head deadline again.
final class ModelProviderHealth: @unchecked Sendable {
    private let cooldown: TimeInterval
    private let now: @Sendable () -> Date
    private let lock = NSLock()
    private var failedUntil: [UUID: Date] = [:]

    init(cooldown: TimeInterval = 300, now: @escaping @Sendable () -> Date = { Date() }) {
        self.cooldown = cooldown
        self.now = now
    }

    func markFailed(_ id: UUID) {
        let until = now().addingTimeInterval(cooldown)
        lock.withLock { failedUntil[id] = until }
    }

    func isCooling(_ id: UUID) -> Bool {
        let current = now()
        return lock.withLock {
            guard let until = failedUntil[id] else { return false }
            if until > current { return true }
            failedUntil[id] = nil
            return false
        }
    }
}
#endif
