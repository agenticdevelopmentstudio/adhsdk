import Foundation

public enum MarkdownVisibility: String, Codable, Sendable, CaseIterable {
    case `private`
    case `public`
}

public enum MarkdownStage: String, Codable, Sendable, CaseIterable {
    case draft
    case final
}

public enum MarkdownOwnerKind: String, Codable, Sendable, CaseIterable {
    case customer
    case organization
}

/// One row of adh's `content.markdown`, as a value.
///
/// The columns adh derives — `title`, `excerpt`, `frontmatter`, `size_bytes`,
/// `content_hash` — are computed properties here rather than stored ones, so
/// there is no way to hold a document whose title contradicts its text. The
/// columns the server owns — `current_version`, `latest_version_id` — are
/// `let`, updated only by reading a row back.
public struct MarkdownDocument: Identifiable, Equatable, Sendable {

    public let id: String
    public var content: String
    public var visibility: MarkdownVisibility
    public var stage: MarkdownStage
    public var publicRoute: String?
    public var ownerKind: MarkdownOwnerKind
    public var ownerID: String
    public let createdAt: Date
    public var updatedAt: Date
    public var deletedAt: Date?
    /// adh carries both a tombstone timestamp and a boolean flag; a row is gone
    /// when either says so.
    public var isDeleted: Bool

    // Server-owned; read-only locally.
    public let currentVersion: Int
    public let latestVersionID: String?

    public init(
        id: String,
        content: String,
        visibility: MarkdownVisibility = .private,
        stage: MarkdownStage = .draft,
        publicRoute: String? = nil,
        ownerKind: MarkdownOwnerKind,
        ownerID: String,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil,
        isDeleted: Bool = false,
        currentVersion: Int = 1,
        latestVersionID: String? = nil
    ) {
        self.id = id
        self.content = content
        self.visibility = visibility
        self.stage = stage
        self.publicRoute = publicRoute
        self.ownerKind = ownerKind
        self.ownerID = ownerID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.isDeleted = isDeleted
        self.currentVersion = currentVersion
        self.latestVersionID = latestVersionID
    }

    public static func new(
        id: String,
        content: String,
        ownerKind: MarkdownOwnerKind,
        ownerID: String,
        now: Date = Date()
    ) -> MarkdownDocument {
        MarkdownDocument(
            id: id,
            content: content,
            ownerKind: ownerKind,
            ownerID: ownerID,
            createdAt: now,
            updatedAt: now
        )
    }

    // MARK: - Derived

    /// Derived from the **whole** content, deliberately: adh recomputes the
    /// title on every write and looks at the entire document, so a windowed
    /// title here would disagree with the column the server writes back.
    public var title: String { MarkdownText.deriveTitle(content) }

    /// Derived from the first `excerptSourceCharacters` only, deliberately:
    /// this property stands in for adh's LIST row, and adh's list endpoint cuts
    /// its excerpt from the first 2 KB of the content (`EXCERPT_SOURCE_CHARS`).
    /// A document whose first 2 KB is all frontmatter or one code fence simply
    /// has no excerpt — on the server, and so here. The asymmetry with `title`
    /// above is adh's, not an oversight.
    ///
    /// Only the *body* is windowed. adh's handler is
    /// `deriveExcerpt(excerptSource, row.frontmatter)`: the frontmatter comes
    /// from the `frontmatter` column, which was parsed from the whole document
    /// on write, so a `---` block that runs past the 2 KB mark still names the
    /// title and still costs the excerpt no body line. Hence the whole
    /// `content` as the second argument.
    public var excerpt: String {
        MarkdownText.deriveExcerpt(MarkdownText.excerptSource(content), frontmatterFrom: content)
    }
    public var contentHash: String { MarkdownText.contentHash(content) }
    public var sizeBytes: Int { MarkdownText.byteLength(content) }

    public var frontmatter: [String: String] {
        guard let block = Frontmatter.split(content).block else { return [:] }
        return Frontmatter.parse(block)
    }

    public var frontmatterJSON: String? { Frontmatter.jsonText(for: content) }

    /// Pinning is a local affordance carried in frontmatter rather than a
    /// column, so it survives a round trip through a server that has never
    /// heard of it.
    /// `Frontmatter.value` unquotes, so this reads both the boolean this
    /// writer emits and the quoted `pinned: "true"` a previous version wrote.
    public var isPinned: Bool { Frontmatter.value("pinned", in: content) == "true" }

    /// Writes a YAML *boolean*, not the four characters `true`. The web editor
    /// and every other reader of the document expect `pinned: true`; a quoted
    /// `pinned: "true"` is a string, and this is exactly the distinction
    /// `FrontmatterValue` exists to carry.
    public mutating func setPinned(_ pinned: Bool) {
        content = Frontmatter.setting("pinned", to: pinned ? .bool(true) : nil, in: content)
    }
}
