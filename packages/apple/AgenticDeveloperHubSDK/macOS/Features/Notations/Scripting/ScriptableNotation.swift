import AppKit
import AgenticDeveloperHubSDKCore

/// One notation for Cocoa Scripting: `notation id "…"` of the application.
/// Read live from the store on each access, so a script never sees a stale
/// copy; `content` is writable and saves through the store.
@MainActor
@objc(ScriptableNotation)
public final class ScriptableNotation: NSObject {

    public let notationID: UUID
    private let store: NotationsStore

    public init(notationID: UUID, store: NotationsStore) {
        self.notationID = notationID
        self.store = store
        super.init()
    }

    private var notation: Notation? { try? store.notation(id: notationID) }

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
        set { _ = try? store.updateContent(id: notationID, content: newValue) }
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
        do {
            guard try feature.store.archive(id: id) else {
                fail("No active notation has id \(id.uuidString).")
                return nil
            }
        } catch {
            fail(error.localizedDescription)
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
        do {
            guard try feature.store.deleteArchived(id: id) else {
                fail("No archived notation has id \(id.uuidString).")
                return nil
            }
        } catch {
            fail(error.localizedDescription)
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

    @MainActor
    fileprivate func fail(_ message: String) {
        scriptErrorNumber = errOSACantAssign
        scriptErrorString = message
    }
}
