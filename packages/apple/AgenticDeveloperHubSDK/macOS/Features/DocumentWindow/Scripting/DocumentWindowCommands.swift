import AppKit

/// AppleScript command: `open document "<path>"` — opens a file in a
/// Document window, as a tab or in a window of its own as Settings > General >
/// Tab Behavior says, or brings forward the window already showing it.
@objc(OpenDocumentCommand)
public final class OpenDocumentCommand: MainActorScriptCommand, @unchecked Sendable {
    public override func performMain() -> Any? {
        guard let path = directParameter as? String,
              !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            scriptErrorNumber = errOSACantAssign
            scriptErrorString = "A file path is required."
            return nil
        }
        guard let feature = NSApp.scriptingHost?.feature(DocumentWindowsFeature.self) else {
            scriptErrorNumber = errOSACantAssign
            scriptErrorString = "Document windows are not available."
            return nil
        }
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        guard feature.open(file: url) != nil else {
            scriptErrorNumber = errOSACantAssign
            scriptErrorString = "Not a file: \(path)"
            return nil
        }
        return nil
    }
}
