import CryptoKit
import Foundation

/// Who a `CLAUDE_CODE_OAUTH_TOKEN` belongs to, answered without anything being
/// handed a token.
///
/// The daemon and the CLI both have to name the account a hook event is billed
/// to, and neither can read the credentials: they live in the app's own Keychain
/// items, and macOS names the process that asks in the permission dialog it
/// raises — a launchd daemon can neither put that dialog in front of anyone nor
/// answer it. So the app, which can, publishes a map of **SHA-256(token) →
/// account name**, and these two look up a digest of the token they were given.
///
/// A digest does not reverse, so the file answers a question about a secret
/// while carrying none, and the app never has to ship a credential to a process
/// that had no business holding one. One file rather than one per reader, so the
/// daemon and the CLI cannot attribute the same token to two different accounts.
///
/// **A miss is an answer, not a failure.** The ordinary session runs as the
/// machine-wide login, whose token Claude Code rotates on its own schedule — so
/// a fingerprint taken when the app last looked will eventually stop matching.
/// Attribution falls back to `~/.claude.json`'s own `oauthAccount` then, which
/// names that very login, so the common case is right either way. The map earns
/// its keep on the case the fallback gets *wrong*: a terminal carrying a
/// credential of its own in `CLAUDE_CODE_OAUTH_TOKEN`, billing an account the
/// machine-wide config has never heard of.
///
/// The file lives in the toolkit's Core so every reader and the writer share
/// one copy of the format: a second copy would be a second answer to "whose
/// token is this".
public enum AccountFingerprints {

    /// Where the app publishes and the other two read. Alongside the database,
    /// in the support directory all three already share.
    public static var defaultPath: String {
        StenographerPaths().supportDirectory
            .appendingPathComponent("account-fingerprints.json").path
    }

    /// How many fingerprints one account keeps. An OAuth access token rotates,
    /// and a token stays usable for a while after the store has moved past it,
    /// so the tail is what keeps a session that started this morning attributed
    /// this afternoon. Bounded because the file would otherwise grow one entry
    /// per rotation forever.
    public static let historyPerAccount = 8

    /// The digest a token is looked up by. SHA-256, rendered by `DigestHex` so
    /// the writer and the readers cannot spell the same hash two ways.
    public static func fingerprint(of token: String) -> String {
        SHA256.hash(data: Data(token.utf8)).hexString
    }

    // MARK: - Reading

    /// The account a token belongs to, or "" — no token, no file, or no match.
    ///
    /// Guards the empty-token case before touching the filesystem: most hook
    /// events carry no token at all, and those must not pay for a file read.
    public static func accountName(forToken token: String?, atPath path: String = defaultPath) -> String {
        guard let token, !token.isEmpty else { return "" }
        return names(atPath: path)[fingerprint(of: token)] ?? ""
    }

    /// fingerprint → account name, for whatever the file holds.
    ///
    /// Tolerant by construction: an entry that is not an object, or carries no
    /// name, is skipped rather than failing the whole map. A reader built
    /// against one version of the file meets the next one by ignoring what it
    /// does not recognise, which is cheaper than a version negotiation between
    /// three targets that ship together anyway.
    public static func parse(_ data: Data) -> [String: String] {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let root = object as? [String: Any],
              let tokens = root["tokens"] as? [String: Any] else { return [:] }
        var names: [String: String] = [:]
        for (digest, value) in tokens {
            guard let entry = value as? [String: Any],
                  let account = entry["account"] as? String, !account.isEmpty else { continue }
            names[digest] = account
        }
        return names
    }

    // MARK: - Writing (the app)

    /// Publishes the fingerprints of the credentials the app just read, keeping
    /// each account's recent history.
    ///
    /// Merged rather than replaced, and that is the point: one call knows about
    /// the credentials it was handed, while a token minted an hour ago is still
    /// billing its account right now. Replacing would un-attribute every live
    /// session whose token has since rotated.
    ///
    /// Written atomically, so a reader never sees half a file — the daemon reads
    /// this on the hook path, where a truncated read would attribute a whole
    /// burst of events to nobody.
    ///
    /// The file is owner-only (0600) from the moment it appears: the new
    /// contents go to a temporary file beside it, which is set to 0600 before
    /// it is renamed over the old one. When the mode cannot be set, `publish`
    /// throws, the temporary file is removed and the previous file stays as it
    /// was, so a file readable by others is never published.
    public static func publish(
        _ fresh: [String: String],
        atPath path: String = defaultPath,
        now: Date = Date()
    ) throws {
        try publish(fresh, atPath: path, now: now, setOwnerOnly: { path in
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: path)
        })
    }

    /// `publish` with the permission step injectable, so a test can make it fail.
    static func publish(
        _ fresh: [String: String],
        atPath path: String,
        now: Date,
        setOwnerOnly: (String) throws -> Void
    ) throws {
        let url = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let existing = FileManager.default.contents(atPath: path) ?? Data()
        let merged = Self.merge(into: Self.entries(existing), fresh, now: now.timeIntervalSince1970)
        var tokens: [String: Any] = [:]
        for entry in merged {
            tokens[entry.digest] = ["account": entry.account, "seen": entry.seen]
        }
        let body: [String: Any] = ["version": 1, "tokens": tokens]
        let data = try JSONSerialization.data(
            withJSONObject: body, options: [.prettyPrinted, .sortedKeys])
        let temporary = url.deletingLastPathComponent()
            .appendingPathComponent(".\(url.lastPathComponent).\(UUID().uuidString).tmp")
        do {
            try data.write(to: temporary)
            try setOwnerOnly(temporary.path)
            guard rename(temporary.path, path) == 0 else {
                throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
            }
        } catch {
            try? FileManager.default.removeItem(at: temporary)
            throw error
        }
    }

    /// One published fingerprint: which account, and when it was last seen.
    public struct Entry: Equatable {
        public let digest: String
        public let account: String
        public let seen: Double

        public init(digest: String, account: String, seen: Double) {
            self.digest = digest
            self.account = account
            self.seen = seen
        }
    }

    /// Every entry in the file, newest first.
    public static func entries(_ data: Data) -> [Entry] {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let root = object as? [String: Any],
              let tokens = root["tokens"] as? [String: Any] else { return [] }
        var found: [Entry] = []
        for (digest, value) in tokens {
            guard let entry = value as? [String: Any],
                  let account = entry["account"] as? String, !account.isEmpty else { continue }
            found.append(Entry(
                digest: digest, account: account, seen: entry["seen"] as? Double ?? 0))
        }
        return found.sorted { $0.seen == $1.seen ? $0.digest < $1.digest : $0.seen > $1.seen }
    }

    /// `fresh` folded into `existing`, each account trimmed to its newest
    /// `historyPerAccount` fingerprints.
    ///
    /// A digest already present is re-stamped rather than duplicated, so a token
    /// still in use never ages out while it is still being used — the trim drops
    /// the ones nothing has presented for longest, which is the closest thing to
    /// "rotated away" that a writer can know.
    ///
    /// A digest that changes hands is taken at its newest word: the same token
    /// cannot belong to two accounts, so the later claim is the true one and
    /// keeping both would make the lookup order decide the answer.
    public static func merge(
        into existing: [Entry], _ fresh: [String: String], now: Double
    ) -> [Entry] {
        var byDigest: [String: Entry] = [:]
        for entry in existing { byDigest[entry.digest] = entry }
        for (digest, account) in fresh {
            byDigest[digest] = Entry(digest: digest, account: account, seen: now)
        }
        var kept: [Entry] = []
        var counts: [String: Int] = [:]
        for entry in byDigest.values
            .sorted(by: { $0.seen == $1.seen ? $0.digest < $1.digest : $0.seen > $1.seen }) {
            let count = counts[entry.account] ?? 0
            guard count < historyPerAccount else { continue }
            counts[entry.account] = count + 1
            kept.append(entry)
        }
        return kept
    }

    // MARK: - Cache

    private static let lock = NSLock()
    nonisolated(unsafe) private static var cachedPath: String?
    nonisolated(unsafe) private static var cachedMtime: Date?
    nonisolated(unsafe) private static var cachedSize: Int?
    nonisolated(unsafe) private static var cachedNames: [String: String] = [:]

    /// The parsed map for `path`, reusing the cache while the file's
    /// modification date AND size are both unchanged.
    ///
    /// The daemon asks this on every hook event, so the steady state has to be a
    /// dictionary lookup rather than a read and a parse. Keyed on the
    /// SYMLINK-RESOLVED path's attributes, because `attributesOfItem` does not
    /// traverse a final symlink and a linked file would otherwise cache for the
    /// life of the process. Size is in the key too: a rewrite can land on the
    /// same coarse-granularity mtime, and a length change still invalidates.
    private static func names(atPath path: String) -> [String: String] {
        lock.lock()
        defer { lock.unlock() }

        let statPath = URL(fileURLWithPath: path).resolvingSymlinksInPath().path
        let attrs = try? FileManager.default.attributesOfItem(atPath: statPath)
        let mtime = attrs?[.modificationDate] as? Date
        let size = attrs?[.size] as? Int
        if cachedPath == path && mtime == cachedMtime && size == cachedSize {
            return cachedNames
        }
        let parsed = parse(FileManager.default.contents(atPath: path) ?? Data())
        cachedPath = path
        cachedMtime = mtime
        cachedSize = size
        cachedNames = parsed
        return parsed
    }
}
