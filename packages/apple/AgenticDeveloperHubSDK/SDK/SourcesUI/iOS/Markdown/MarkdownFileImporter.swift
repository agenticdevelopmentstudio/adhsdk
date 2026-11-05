import UIKit
import UniformTypeIdentifiers
import ObjectiveC

/// The document picker's delegate outlives the call that creates it. Rather
/// than have it retain itself and release on a callback — which never fires
/// if the picker is dismissed programmatically or its presenter is torn down
/// first, leaking the delegate — its lifetime is tied directly to the
/// picker's own via an associated object: it lives exactly as long as the
/// picker does, callback or not.
@MainActor
public enum MarkdownFileImporter {

    private final class PickerDelegate: NSObject, UIDocumentPickerDelegate {
        private let completion: (String?) -> Void

        init(completion: @escaping (String?) -> Void) {
            self.completion = completion
            super.init()
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let completion = self.completion
            guard let url = urls.first else { completion(nil); return }
            let scoped = url.startAccessingSecurityScopedResource()
            // Reading is dispatched off the main thread so a large document
            // does not freeze the UI while it loads; the security scope stays
            // open until that read finishes.
            DispatchQueue.global(qos: .userInitiated).async {
                let text = try? String(contentsOf: url, encoding: .utf8)
                if scoped { url.stopAccessingSecurityScopedResource() }
                DispatchQueue.main.async { completion(text) }
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // Delivered asynchronously so both outcomes reach the caller the
            // same way: a completion that runs synchronously inside a delegate
            // callback re-enters the caller while the picker is still
            // dismissing, and the pick path above cannot do that.
            let completion = self.completion
            DispatchQueue.main.async { completion(nil) }
        }
    }

    private static var delegateAssociationKey: UInt8 = 0

    public static func present(
        from presenter: PlatformViewController,
        completion: @escaping (String?) -> Void
    ) {
        var types: [UTType] = [.plainText]
        if let markdown = UTType(filenameExtension: "md") { types.insert(markdown, at: 0) }

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.allowsMultipleSelection = false
        let delegate = PickerDelegate(completion: completion)
        picker.delegate = delegate
        // Retain the delegate for exactly as long as the picker: when the
        // picker is dismissed — however that happens — and released, this
        // associated object goes with it.
        objc_setAssociatedObject(
            picker, &delegateAssociationKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        presenter.present(picker, animated: true)
    }
}
