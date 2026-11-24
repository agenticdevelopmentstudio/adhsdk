import Foundation

/// Where a privacy word applies, as site patterns (``PrivacyWord/sites``).
///
/// - `*` alone: everywhere — every web page and every private terminal.
/// - Otherwise `host[:port][/path][?query][#fragment]`, as the address reads,
///   each part a glob in which `*` matches any run of characters, `/`
///   included, and every other character only itself (`GlobPattern(wildcard:)`):
///   `google.com/*`, `foo.com/hi/*`, `*.google.com`, `localhost:3000/*`,
///   `[::1]:8080`. A scheme in front (`https://`) is ignored, since the
///   pattern names a site; a `://` further on is part of the path.
/// - **Host.** Compared without regard to case, and in one form whichever
///   way it was written: a Unicode name and its punycode (`münchen.de`,
///   `xn--mnchen-3ya.de`) are the same host, and an IPv6 literal matches with
///   or without its brackets.
/// - **Port.** A pattern with no port matches every port. One with a port
///   matches that port, the scheme's default standing in for an address
///   that names none (`example.com:443` covers `https://example.com`).
/// - **Path.** A pattern with no path matches every path on its host. Paths
///   compare with regard to case, percent-escapes decoded on both sides, and
///   a trailing `/` does not count (`foo.com/docs/` and `foo.com/docs` are
///   the same). `X/*` also covers `X` itself, stars in `X` or not.
/// - **Query and fragment.** Ignored unless the pattern has one: a pattern
///   with a `?` is matched against the address's query too, one with a `#`
///   against its fragment too, so an address pasted from the address bar
///   matches its own page.
///
/// Only `*` applies where there is no address, as in a private terminal.
public enum PrivacySitePattern {

    /// The pattern that applies everywhere.
    public static let everywhere = "*"

    /// Splits the comma-separated text the editor shows into patterns,
    /// trimmed, empties dropped.
    public static func parse(_ text: String) -> [String] {
        text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    /// `patterns` trimmed, empties dropped, and `*` when none is left: a word
    /// with no sites would apply nowhere, and concealing more is the safe
    /// direction.
    public static func normalized(_ patterns: [String]) -> [String] {
        let kept = patterns
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return kept.isEmpty ? [everywhere] : kept
    }

    /// The patterns as the editor shows them.
    public static func format(_ patterns: [String]) -> String {
        patterns.joined(separator: ", ")
    }

    /// The pattern a word added on `url`'s page starts with: its host and
    /// every path under it, on every port, or `*` for a page with no host.
    /// An IPv6 host is written in brackets, as an address writes it.
    public static func defaultPattern(for url: URL?) -> String {
        guard let host = url?.host?.lowercased(), !host.isEmpty else { return everywhere }
        let written = host.contains(":") && !host.hasPrefix("[") ? "[\(host)]" : host
        return written + "/*"
    }

    /// Whether `pattern` applies at `url`; `nil` is a place with no address.
    public static func matches(_ pattern: String, url: URL?) -> Bool {
        let pattern = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        if pattern == everywhere { return true }
        guard let url, !pattern.isEmpty, let address = Address(url) else { return false }
        let parts = Parts(pattern)
        guard GlobPattern(wildcard: parts.host).matches(address.host) else { return false }
        if let port = parts.port, !GlobPattern(wildcard: port).matches(address.port) { return false }
        guard let path = parts.path else { return true }

        var target = address.path
        if parts.hasQuery { target += "?" + (address.query ?? "") }
        if parts.hasFragment { target += "#" + (address.fragment ?? "") }
        var candidates = [path + parts.rest]
        // `foo.com/hi/*` also covers `foo.com/hi` itself.
        if path.hasSuffix("/*") {
            let covered = String(path.dropLast(2))
            candidates.append((covered.isEmpty ? "/" : covered) + parts.rest)
        }
        return candidates.contains { GlobPattern(wildcard: $0).matches(target) }
    }

    // MARK: - The two sides, in one form

    /// A pattern taken apart.
    private struct Parts {
        /// The host glob, in `normalizedHost(_:)`'s form.
        var host: String
        /// The port glob; nil when the pattern names no port.
        var port: String?
        /// The path glob, decoded and in `normalizedPath(_:)`'s form; nil
        /// when the pattern has neither a path, a query nor a fragment.
        var path: String?
        /// The query and fragment glob, `?` or `#` first, decoded; empty when
        /// the pattern has neither.
        var rest: String
        /// Whether the pattern has a query, and so is matched against the
        /// address's query too.
        var hasQuery = false
        /// Whether the pattern has a fragment, and so is matched against the
        /// address's fragment too.
        var hasFragment = false

        init(_ pattern: String) {
            var text = Substring(pattern)
            if let separator = text.range(of: "://"),
               PrivacySitePattern.isScheme(text[..<separator.lowerBound]) {
                text = text[separator.upperBound...]
            }
            let authorityEnd = text.firstIndex { $0 == "/" || $0 == "?" || $0 == "#" } ?? text.endIndex
            let (host, port) = PrivacySitePattern.splitAuthority(text[..<authorityEnd])
            self.host = PrivacySitePattern.normalizedHost(host)
            self.port = port.flatMap { $0.isEmpty ? nil : String($0) }

            let tail = text[authorityEnd...]
            guard !tail.isEmpty else {
                path = nil
                rest = ""
                return
            }
            let pathEnd = tail.firstIndex { $0 == "?" || $0 == "#" } ?? tail.endIndex
            path = PrivacySitePattern.normalizedPath(PrivacySitePattern.decoded(tail[..<pathEnd]))
            // Told apart before decoding, so an escaped `?` or `#` stays
            // part of the path or query it was written in.
            hasQuery = tail[pathEnd...].hasPrefix("?")
            hasFragment = tail[pathEnd...].contains("#")
            rest = PrivacySitePattern.decoded(tail[pathEnd...])
        }
    }

    /// An address in the form a pattern is matched against.
    private struct Address {
        var host: String
        /// The port, or the scheme's default; empty when there is neither.
        var port: String
        /// Decoded, in `normalizedPath(_:)`'s form.
        var path: String
        var query: String?
        var fragment: String?

        init?(_ url: URL) {
            guard let host = url.host, !host.isEmpty else { return nil }
            self.host = PrivacySitePattern.normalizedHost(host)
            let defaultPort: Int? = switch url.scheme?.lowercased() {
            case "http", "ws": 80
            case "https", "wss": 443
            default: nil
            }
            port = (url.port ?? defaultPort).map(String.init) ?? ""
            // The path as the address has it, trailing `/` and escapes
            // included, which `URL.path` drops and decodes.
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            path = PrivacySitePattern.normalizedPath(
                PrivacySitePattern.decoded(components?.percentEncodedPath ?? url.path))
            query = components?.percentEncodedQuery.map { PrivacySitePattern.decoded($0) }
            fragment = components?.percentEncodedFragment.map { PrivacySitePattern.decoded($0) }
        }
    }

    /// Whether `text` is a scheme (`https`, `*`) rather than the start of a
    /// path that holds a URL: no `/`, and only the characters a scheme has.
    private static func isScheme(_ text: Substring) -> Bool {
        guard let first = text.first, first.isLetter || first == "*" else { return false }
        return text.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || "+-.*".contains($0)) }
    }

    /// `host[:port]`, `[v6]` or `[v6]:port` split in two. A bare IPv6
    /// literal, with more than one `:`, is all host.
    private static func splitAuthority(_ authority: Substring) -> (host: Substring, port: Substring?) {
        if authority.hasPrefix("["), let close = authority.firstIndex(of: "]") {
            let host = authority[authority.index(after: authority.startIndex)..<close]
            let after = authority[authority.index(after: close)...]
            let port: Substring? = after.hasPrefix(":") ? after.dropFirst() : nil
            return (host, port)
        }
        let colons = authority.filter { $0 == ":" }.count
        guard colons == 1, let colon = authority.firstIndex(of: ":") else { return (authority, nil) }
        return (authority[..<colon], authority[authority.index(after: colon)...])
    }

    /// `host` lowercased, out of its brackets, and with each non-ASCII label
    /// in punycode, the form an address's host is in whichever way it was
    /// typed.
    private static func normalizedHost<S: StringProtocol>(_ host: S) -> String {
        var host = host.lowercased()
        if host.hasPrefix("["), host.hasSuffix("]") { host = String(host.dropFirst().dropLast()) }
        return host.split(separator: ".", omittingEmptySubsequences: false).map { label in
            guard !label.allSatisfy(\.isASCII) else { return String(label) }
            var components = URLComponents()
            components.host = String(label)
            return components.encodedHost?.lowercased() ?? String(label)
        }.joined(separator: ".")
    }

    /// `path` with one trailing `/` dropped, and `/` for no path at all.
    private static func normalizedPath(_ path: String) -> String {
        guard !path.isEmpty else { return "/" }
        return path.count > 1 && path.hasSuffix("/") ? String(path.dropLast()) : path
    }

    /// `text` with its percent-escapes decoded, or as it is when it holds a
    /// `%` that is not one.
    private static func decoded<S: StringProtocol>(_ text: S) -> String {
        String(text).removingPercentEncoding ?? String(text)
    }
}
