import AppKit

/// AppleScript command: `open file browser "<path>"` — opens a File Browser
/// window on a directory, or brings forward the one already open on it.
@objc(OpenFileBrowserCommand)
public final class OpenFileBrowserCommand: MainActorScriptCommand, @unchecked Sendable {
    public override func performMain() -> Any? {
        guard let path = directParameter as? String,
              !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            scriptErrorNumber = errOSACantAssign
            scriptErrorString = "A directory path is required."
            return nil
        }
        guard let feature = NSApp.scriptingHost?.feature(FileBrowserWindowsFeature.self) else {
            scriptErrorNumber = errOSACantAssign
            scriptErrorString = "File Browser windows are not available."
            return nil
        }
        let url = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
        guard feature.open(directory: url) != nil else {
            scriptErrorNumber = errOSACantAssign
            scriptErrorString = "Not a directory: \(path)"
            return nil
        }
        return nil
    }
}
