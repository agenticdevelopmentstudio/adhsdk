import AppKit
import AgenticDeveloperHubSDKCore
import AgenticDeveloperHubSDKDatabase

/// One notation for Cocoa Scripting: `notation id "…"` of the application.
/// Read on each access from the feature's snapshot, which follows the store's
/// changes (Cocoa Scripting asks synchronously; the store answers
/// asynchronously); `content` is writable and saves through the store.
@MainActor
@objc(ScriptableNotation)
public final class ScriptableNotation: NSObject {

    public let notationID: UUID
    private let store: any NotationsStoring
    private let lookup: @MainActor (UUID) -> Notation?

    /// - Parameter lookup: The notation as last read, or `nil` once gone.
    public init(notationID: UUID, store: any NotationsStoring, lookup: @escaping @MainActor (UUID) -> Notation?) {
        self.notationID = notationID
        self.store = store
        self.lookup = lookup
        super.init()
    }

    private var notation: Notation? { lookup(notationID) }

    @objc var uniqueID: String { notationID.uuidString }
    @objc var projectName: String { notation?.projectName ?? "" }
    @objc var projectPath: String { notation?.projectPath ?? "" }
    @objc var branch: String { notation?.branch ?? "" }
    @objc var notationState: String { notation?.state.rawValue ?? "" }
    @objc var createdAt: Date? { notation?.createdAt }
    @objc var modifiedAt: Date? { notation?.modifiedAt }
    @objc var archivedAt: Date? { notation?.archivedAt }

    @objc var content: String {
        get { notation?.content ?? "" }
        set {
            let store = store, id = notationID
            NotationsSaveQueue.shared.enqueue { _ = try? await store.updateContent(id: id, content: newValue) }
        }
    }

    public override nonisolated var objectSpecifier: NSScriptObjectSpecifier? {
        applicationElementSpecifier(key: "notations") { self.uniqueID }
    }
}

/// `archive notation "<id>"`: archives an active notation now, without
/// waiting for its branch to merge.
@objc(ArchiveNotationCommand)
public final class ArchiveNotationCommand: MainActorScriptCommand, @unchecked Sendable {
    public override func performMain() -> Any? {
        guard let (feature, id) = resolve() else { return nil }
        let store = feature.store
        runSuspended {
            do {
                guard try await store.archive(id: id) else {
                    return "No active notation has id \(id.uuidString)."
                }
                return nil
            } catch {
                return error.localizedDescription
            }
        }
        return nil
    }
}

/// `delete notation "<id>"`: deletes an archived notation. An active one is
/// refused, as the Notations window refuses it.
@objc(DeleteNotationCommand)
public final class DeleteNotationCommand: MainActorScriptCommand, @unchecked Sendable {
    public override func performMain() -> Any? {
        guard let (feature, id) = resolve() else { return nil }
        let store = feature.store
        runSuspended {
            do {
                guard try await store.deleteArchived(id: id) else {
                    return "No archived notation has id \(id.uuidString)."
                }
                return nil
            } catch {
                return error.localizedDescription
            }
        }
        return nil
    }
}

/// `show notations`: opens the Notations window.
@objc(ShowNotationsCommand)
public final class ShowNotationsCommand: MainActorScriptCommand, @unchecked Sendable {
    public override func performMain() -> Any? {
        guard let feature = NSApp.scriptingHost?.feature(NotationsFeature.self) else {
            scriptErrorNumber = errOSACantAssign
            scriptErrorString = "Notations are not available."
            return nil
        }
        feature.showWindow()
        return nil
    }
}

extension MainActorScriptCommand {
    /// The feature and the notation id named by the direct parameter, which
    /// is either the id's text or a `notation` specifier.
    @MainActor
    fileprivate func resolve() -> (NotationsFeature, UUID)? {
        guard let feature = NSApp.scriptingHost?.feature(NotationsFeature.self) else {
            fail("Notations are not available.")
            return nil
        }
        let raw: String?
        if let text = directParameter as? String {
            raw = text
        } else if let notation = directParameter as? ScriptableNotation {
            raw = notation.uniqueID
        } else if let specifier = directParameter as? NSUniqueIDSpecifier {
            raw = specifier.uniqueID as? String
        } else {
            raw = nil
        }
        guard let raw, let id = UUID(uuidString: raw.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            fail("A notation id is required.")
            return nil
        }
        return (feature, id)
    }

    /// Suspends the script while `body` runs against the store, then
    /// resumes it, failing with the message `body` answers, if any. Cocoa
    /// Scripting waits for the result without blocking the main thread.
    @MainActor
    fileprivate func runSuspended(_ body: @escaping @Sendable () async -> String?) {
        suspendExecution()
        Task { @MainActor in
            if let message = await body() { self.fail(message) }
            self.resumeExecution(withResult: nil)
        }
    }

    @MainActor
    fileprivate func fail(_ message: String) {
        scriptErrorNumber = errOSACantAssign
        scriptErrorString = message
    }
}
