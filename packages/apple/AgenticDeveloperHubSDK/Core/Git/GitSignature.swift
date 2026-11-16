import Foundation

/// What git made of a commit's signature: `%G?` (recipe `foundation/git/git-client`,
/// "Signatures"). The raw values are git's own letters.
public enum GitSignatureStatus: String, Sendable, Hashable {
    case good = "G", bad = "B", unknownValidity = "U", expired = "X", expiredKey = "Y", revokedKey = "R"
    case cannotCheck = "E", unsigned = "N"

    /// The status in a few words, for a tooltip, an accessibility label or the detail line.
    public var title: String {
        switch self {
        case .good: return "Good signature"
        case .bad: return "Bad signature"
        case .unknownValidity: return "Signature of unknown validity"
        case .expired: return "Expired signature"
        case .expiredKey: return "Signed with an expired key"
        case .revokedKey: return "Signed with a revoked key"
        case .cannotCheck: return "Signature cannot be checked"
        case .unsigned: return "Not signed"
        }
    }
}

/// A commit's signature as git verified it: the status, the signer (`%GS`) and the key
/// (`%GK`), each nil when git printed nothing for it.
public struct GitSignature: Sendable, Hashable {
    public let status: GitSignatureStatus
    public let signer: String?
    public let key: String?

    public init(status: GitSignatureStatus, signer: String? = nil, key: String? = nil) {
        self.status = status
        self.signer = signer
        self.key = key
    }

    /// The status, then the signer when there is one: "Good signature by Ada".
    public var summary: String {
        guard let signer else { return status.title }
        return "\(status.title) by \(signer)"
    }

    /// Unit and record separators between the fields and the commits.
    static let fieldSeparator: Character = "\u{1F}"
    static let recordSeparator: Character = "\u{1E}"

    /// `--format` for `log --no-walk=unsorted`: `%H<US>%G?<US>%GS<US>%GK<RS>`.
    public static let format = "%H%x1f%G?%x1f%GS%x1f%GK%x1e"

    /// The signatures in `log`'s output for `format`, keyed by full sha. A record with
    /// fewer than two fields is skipped; a letter git adds later reads as `.cannotCheck`.
    public static func parse(log output: String) -> [String: GitSignature] {
        var signatures: [String: GitSignature] = [:]
        for record in output.split(separator: recordSeparator, omittingEmptySubsequences: true) {
            let fields = record.trimmingCharacters(in: .whitespacesAndNewlines)
                .split(separator: fieldSeparator, omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard fields.count >= 2, !fields[0].isEmpty else { continue }
            let status = GitSignatureStatus(rawValue: fields[1]) ?? .cannotCheck
            let signer = fields.count > 2 && !fields[2].isEmpty ? fields[2] : nil
            let key = fields.count > 3 && !fields[3].isEmpty ? fields[3] : nil
            signatures[fields[0]] = GitSignature(status: status, signer: signer, key: key)
        }
        return signatures
    }
}
