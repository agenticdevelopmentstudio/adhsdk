import AppKit
import UniformTypeIdentifiers

/// Reads a markdown file the user picks. `nil` means they cancelled, or the
/// file could not be decoded as text — neither is an error worth a dialog.
@MainActor
public enum MarkdownFileImporter {

    public static func present(
        from presenter: PlatformViewController,
        completion: @escaping (String?) -> Void
    ) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = contentTypes

        // The panel's completion handler runs on the main thread; reading the
        // chosen file off it keeps a large document from freezing the UI
        // while it loads.
        let handler: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .OK, let url = panel.url else {
                // Completing asynchronously here too, rather than inline,
                // keeps the timing contract the same regardless of whether
                // the user picked a file or cancelled.
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                let text = try? String(contentsOf: url, encoding: .utf8)
                DispatchQueue.main.async { completion(text) }
            }
        }

        if let window = presenter.view.window {
            panel.beginSheetModal(for: window, completionHandler: handler)
        } else {
            handler(panel.runModal())
        }
    }

    private static var contentTypes: [UTType] {
        var types: [UTType] = [.plainText]
        if let markdown = UTType(filenameExtension: "md") { types.insert(markdown, at: 0) }
        return types
    }
}
