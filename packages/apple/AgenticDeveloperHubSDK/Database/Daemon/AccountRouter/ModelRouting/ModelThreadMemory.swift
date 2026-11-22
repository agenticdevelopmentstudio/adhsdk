#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// What the router decided for a thread, so later requests on it stay put
/// (changing model mid-thread would void the prompt cache).
final class ModelThreadMemory: @unchecked Sendable {
    struct Entry: Equatable, Sendable {
        let requestedModel: String
        let decision: ModelDecision
        let reverted: Bool
    }

    private let capacity: Int
    private let lock = NSLock()
    private var entries: [String: Entry] = [:]
    /// Least recently used first.
    private var order: [String] = []

    init(capacity: Int = 4096) { self.capacity = max(1, capacity) }

    func entry(_ key: String) -> Entry? {
        lock.lock()
        defer { lock.unlock() }
        guard let found = entries[key] else { return nil }
        touch(key)
        return found
    }

    func remember(_ key: String, _ entry: Entry) {
        lock.lock()
        defer { lock.unlock() }
        entries[key] = entry
        touch(key)
        while order.count > capacity {
            entries.removeValue(forKey: order.removeFirst())
        }
    }

    /// Later requests on this thread are kept, rule `sticky: reverted`.
    func markReverted(_ key: String) {
        lock.lock()
        defer { lock.unlock() }
        guard let found = entries[key] else { return }
        entries[key] = Entry(requestedModel: found.requestedModel, decision: found.decision, reverted: true)
        touch(key)
    }

    private func touch(_ key: String) {
        if let index = order.firstIndex(of: key) { order.remove(at: index) }
        order.append(key)
    }
}
#endif
