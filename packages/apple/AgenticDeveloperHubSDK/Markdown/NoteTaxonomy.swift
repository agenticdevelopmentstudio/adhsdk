import Foundation

/// The note categories ("folders") a notes window shows and edits, with
/// nothing said about where they are kept.
///
/// `MarkdownStore` keeps them in its own SQLite file and conforms directly. A
/// storage that keeps them elsewhere — a daemon over HTTP — conforms with a
/// local copy it keeps current, so these calls stay synchronous: the folders
/// pane, the Move-to menu and the split view call them on the main actor while
/// they build a menu or a row, and a network round trip there would stall the
/// UI. Such a storage announces outside changes with
/// `NoteChange.taxonomyChanged`.
///
/// The requirements name every parameter `MarkdownStore`'s methods take, so its
/// conformance is its existing methods; the shorter forms the UI calls are in
/// the extension below.
public protocol NoteTaxonomy: AnyObject, Sendable {
    func categories() throws -> [MarkdownCategory]
    func categoryEdges() throws -> [(parent: String, child: String)]
    /// Notes per category id, counting only notes the list can show.
    func categoryNoteCounts() throws -> [String: Int]
    /// The number of notes "All Notes" shows.
    func noteCount(marker: MarkdownMarker) throws -> Int
    func documentIDs(forCategory categoryID: String) throws -> Set<String>
    func categories(forDocument documentID: String) throws -> [MarkdownCategory]

    func createCategory(
        name: String, description: String, color: String,
        icon: String, sortOrder: Int, now: Date
    ) throws -> MarkdownCategory
    func renameCategory(_ id: String, to name: String, now: Date) throws
    func deleteCategory(_ id: String, now: Date) throws
    func addCategoryEdge(parent: String, child: String, sortOrder: Int, now: Date) throws
    func assignCategory(_ categoryID: String, toDocument documentID: String, sortOrder: Int, now: Date) throws
    func unassignCategory(_ id: String, fromDocument documentID: String, now: Date) throws
}

extension NoteTaxonomy {
    public func createCategory(name: String) throws -> MarkdownCategory {
        try createCategory(name: name, description: "", color: "", icon: "", sortOrder: 0, now: Date())
    }

    public func renameCategory(_ id: String, to name: String) throws {
        try renameCategory(id, to: name, now: Date())
    }

    public func deleteCategory(_ id: String) throws {
        try deleteCategory(id, now: Date())
    }

    public func addCategoryEdge(parent: String, child: String) throws {
        try addCategoryEdge(parent: parent, child: child, sortOrder: 0, now: Date())
    }

    public func assignCategory(_ categoryID: String, toDocument documentID: String) throws {
        try assignCategory(categoryID, toDocument: documentID, sortOrder: 0, now: Date())
    }

    public func unassignCategory(_ id: String, fromDocument documentID: String) throws {
        try unassignCategory(id, fromDocument: documentID, now: Date())
    }
}

extension MarkdownStore: NoteTaxonomy {}
