#if canImport(AgenticDeveloperHubSDKCore)

import Foundation
import Synchronization

/// Keeps an app's own `Projects.db` holding a `git_repo` row for every
/// project in a registry it does not otherwise list (apps suite Phase 4,
/// Decision 4), so window state can hang off the registry's ids.
///
/// `ProjectsCoordinator` mirrors for itself; this is the same
/// `LocalProjectMirror` for an app with no project coordinator, such as
/// ADTerminal. adhd's registry announces every project on each (re)connect,
/// so following `changes` alone catches up; the opening `projects()` read
/// only fills the file sooner when the connection is already there.
///
/// The row at `keepingLocal` is the app's own (ADTerminal's window over the
/// home directory) and never registered: a registry project at that path is
/// not mirrored, because the mirror would delete the local row there and its
/// layout with it.
public final class ProjectRegistryFollower: Sendable {
    private let registry: any ProjectRegistry
    private let mirror: LocalProjectMirror
    private let keptPath: String?
    private let task = Mutex<Task<Void, Never>?>(nil)

    public init(registry: any ProjectRegistry, mirror: LocalProjectMirror, keepingLocal path: String? = nil) {
        self.registry = registry
        self.mirror = mirror
        self.keptPath = path
    }

    /// Starts following; a second call does nothing. `onFailure` hears a
    /// read or write that failed, and following goes on.
    public func start(onFailure: @escaping @Sendable (any Error) -> Void) {
        task.withLock { current in
            guard current == nil else { return }
            // Subscribed before the list is read, so nothing lands between.
            let changes = registry.changes
            current = Task { [registry, mirror, keptPath] in
                do {
                    try mirror.sync(try await registry.projects().filter { $0.path != keptPath })
                } catch {
                    if !Task.isCancelled { onFailure(error) }
                }
                for await change in changes {
                    if Task.isCancelled { return }
                    if case .upserted(let project) = change, project.path == keptPath { continue }
                    do { try mirror.apply(change) } catch { onFailure(error) }
                }
            }
        }
    }

    /// Stops following. The rows already mirrored stay.
    public func stop() {
        task.withLock { current in
            current?.cancel()
            current = nil
        }
    }
}

#endif
