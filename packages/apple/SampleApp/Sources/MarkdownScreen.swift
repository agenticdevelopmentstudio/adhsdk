#if os(iOS)
import SwiftUI
import UIKit
import AgenticDeveloperHubSDK
import AgenticDeveloperHubSDKUI

/// The sample app's markdown screen: a list, an editor, and a viewer.
///
/// Backed by an array rather than a database on purpose. The real store lives
/// in AgenticDeveloperHubSDK, and this package depends on nothing there — the
/// dependency points downward only. What this screen exists to show is that
/// `MarkdownEditorController` and `MarkdownViewerController` work on UIKit, and
/// an array shows that as well as SQLite would.
@MainActor
final class InMemoryMarkdownDocuments: ObservableObject {

    struct Item: Identifiable, Equatable {
        let id = UUID()
        var content: String
        var title: String { MarkdownText.deriveTitle(content) }
        var excerpt: String { MarkdownText.deriveExcerpt(content) }
    }

    @Published var items: [Item] = [
        Item(content: """
            # Welcome

            This is a **markdown** document rendered natively — no web view.

            - Lists render as lists
            - `Inline code` takes the code font

            > And quotes are indented.
            """)
    ]

    func add() -> Item {
        let item = Item(content: "# New document\n\n")
        items.insert(item, at: 0)
        return item
    }

    func update(_ id: UUID, content: String) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].content = content
    }
}

struct MarkdownScreen: View {
    @StateObject private var documents = InMemoryMarkdownDocuments()

    var body: some View {
        NavigationStack {
            List(documents.items) { item in
                NavigationLink(value: item.id) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title).font(.headline)
                        Text(item.excerpt)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .navigationTitle("Documents")
            .navigationDestination(for: UUID.self) { id in
                MarkdownEditorScreen(id: id, documents: documents)
            }
            .toolbar {
                Button {
                    _ = documents.add()
                } label: {
                    Label("New", systemImage: "square.and.pencil")
                }
            }
        }
    }
}

private struct MarkdownEditorScreen: View {
    let id: UUID
    @ObservedObject var documents: InMemoryMarkdownDocuments

    private var document: InMemoryMarkdownDocuments.Item? {
        documents.items.first { $0.id == id }
    }

    var body: some View {
        MarkdownEditorRepresentable(
            content: document?.content ?? "",
            onChange: { documents.update(id, content: $0) })
        .navigationTitle(document?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Hosts the UIKit controller. The controller owns its own toolbar and mode
/// switching, so this wrapper carries no state of its own — `updateUIViewController`
/// deliberately does not push `content` back down, because that would fight the
/// user's typing.
private struct MarkdownEditorRepresentable: UIViewControllerRepresentable {
    let content: String
    let onChange: (String) -> Void

    func makeUIViewController(context: Context) -> MarkdownEditorController {
        let controller = MarkdownEditorController(palette: SemanticPalette(theme: BuiltInThemes.solarizedDark))
        controller.content = content
        controller.onContentChange = onChange
        return controller
    }

    func updateUIViewController(_ controller: MarkdownEditorController, context: Context) {}
}
#endif
