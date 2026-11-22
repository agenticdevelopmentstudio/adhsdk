#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation
import os

/// The account router's logger and the one function every error string passes
/// through before it reaches a log line or the `error` column.
///
/// `Loggable.makeLogger()` names the category after the type; the spec fixes
/// it at `AccountRouter`, so the logger is built here explicitly.
enum AccountRouterLog {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var current = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "account-router", category: "AccountRouter")

    /// The logger, under the hosting daemon's label once ``configure(label:)`` ran.
    static var logger: Logger {
        lock.withLock { current }
    }

    /// Names the log subsystem after the daemon hosting the router.
    static func configure(label: String) {
        lock.withLock { current = Logger(subsystem: label, category: "AccountRouter") }
    }
    static let maxLength = 200

    /// A key prefix and how many characters must follow it before the run is
    /// taken for a key. `sk-ant-` is always a key; a bare `sk-` (OpenAI's
    /// `sk-…` and `sk-proj-…`) or `AIza` (Google) needs a key-sized run, so
    /// ordinary words such as "disk-full" are left alone.
    private struct Marker {
        let prefix: [Unicode.Scalar]
        let minimumBody: Int
    }

    private static let markers = [
        Marker(prefix: Array("sk-ant-".unicodeScalars), minimumBody: 1),
        Marker(prefix: Array("sk-".unicodeScalars), minimumBody: 20),
        Marker(prefix: Array("AIza".unicodeScalars), minimumBody: 30)
    ]

    /// A secret shorter than this is not matched by value: redacting every
    /// occurrence of a few characters would shred ordinary text.
    static let minimumSecretLength = 8

    /// Three steps, in this order:
    /// 1. Keep only scalars that are visible (`Sessions.VisibleText.isVisible`): letters,
    ///    digits, punctuation, symbols and plain spaces. Everything else is
    ///    deleted: controls, format characters, every combining mark, line and
    ///    paragraph separators, unassigned and private-use code points, and
    ///    anything Unicode lists as default-ignorable (fillers such as U+3164,
    ///    variation selectors, joiners).
    /// 2. Each exact occurrence of a value in `secrets` (the route's own key,
    ///    where the caller has it) becomes `[redacted]`. Then from each key
    ///    prefix (`sk-ant-`, `sk-`, `AIza`, see ``Marker``) to the next space
    ///    becomes `[redacted]`. That is a superset of `sk-ant-[A-Za-z0-9_-]+`:
    ///    an odd visible character inside a token cannot end the redaction
    ///    early either.
    /// 3. Truncate to ``maxLength`` characters.
    ///
    /// The order is the guarantee. Nothing invisible can split a token or hide
    /// its prefix, because it is gone before the redaction looks. Only a space
    /// can end a token, and a space is visible. A cut can never leave half a
    /// token, because truncation comes last.
    static func scrub(_ text: String, secrets: [String?] = []) -> String {
        let scalars = Array(text.unicodeScalars.filter(Sessions.VisibleText.isVisible))
        let values = secrets.compactMap { $0 }
            .map { Array($0.unicodeScalars.filter(Sessions.VisibleText.isVisible)) }
            .filter { $0.count >= minimumSecretLength }
        var out = String.UnicodeScalarView()
        var index = 0
        scan: while index < scalars.count {
            for value in values where matches(value, in: scalars, at: index) {
                out.append(contentsOf: "[redacted]".unicodeScalars)
                index += value.count
                continue scan
            }
            for marker in markers where matches(marker.prefix, in: scalars, at: index) {
                var end = index + marker.prefix.count
                while end < scalars.count, !isSpace(scalars[end]) { end += 1 }
                if end - (index + marker.prefix.count) >= marker.minimumBody {
                    out.append(contentsOf: "[redacted]".unicodeScalars)
                    index = end
                    continue scan
                }
            }
            out.append(scalars[index])
            index += 1
        }
        return String(String(out).prefix(maxLength))
    }

    private static func matches(_ needle: [Unicode.Scalar], in scalars: [Unicode.Scalar], at index: Int) -> Bool {
        index + needle.count <= scalars.count && scalars[index..<index + needle.count].elementsEqual(needle)
    }

    private static func isSpace(_ scalar: Unicode.Scalar) -> Bool {
        scalar.properties.generalCategory == .spaceSeparator
    }
}
#endif
