#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// The newest Claude Code version seen in a request's User-Agent. In memory only.
final class ModelClientVersionMemory: @unchecked Sendable {
    private let lock = NSLock()
    private var highest: Sessions.ClaudeCodeVersion?

    func note(_ version: Sessions.ClaudeCodeVersion) {
        lock.lock()
        defer { lock.unlock() }
        if let current = highest, current >= version { return }
        highest = version
    }

    var newest: Sessions.ClaudeCodeVersion? {
        lock.lock()
        defer { lock.unlock() }
        return highest
    }
}
#endif
