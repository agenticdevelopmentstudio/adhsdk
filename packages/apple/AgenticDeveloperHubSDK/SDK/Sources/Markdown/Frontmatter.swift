import Foundation

/// A document split at its frontmatter fence.
///
/// `prefix + body` always reproduces the original content byte for byte, so a
/// document can be opened, re-serialised and stored without being rewritten.
public struct FrontmatterSplit: Equatable, Sendable {
    /// The fenced block including both `---` lines and the newline that ends
    /// the closing fence, exactly as written. Empty when there is no block.
    public let prefix: String
    /// The text between the fences, with no trailing newline. `nil` when there
    /// is no block — which is not the same as an empty block.
    public let block: String?
    /// Everything after `prefix`.
    public let body: String

    public init(prefix: String, block: String?, body: String) {
        self.prefix = prefix
        self.block = block
        self.body = body
    }
}

/// What a caller means by the text it is writing into a frontmatter value.
///
/// A `String` alone cannot say it. `title` must round-trip as a *string* —
/// adh's reader drops a `title` that fails `typeof v === 'string'`, so
/// `title: 42` falls through to the body heading and the column then flips on
/// every sync round trip; that is why the writer quotes anything YAML would
/// type as something else. `pinned` is the opposite: it is a boolean the
/// caller happens to be holding as text, and quoting it puts a string on the
/// wire where every other reader of the document — the web editor above all —
/// expects `true`. The quoting rule is right; a parameter that cannot tell the
/// two apart is what was wrong.
public enum FrontmatterValue: Equatable, Sendable, ExpressibleByStringLiteral {

    /// Text that must read back as this exact string. Emitted bare when a
    /// bare emission would parse as the same string, and quoted otherwise.
    /// A bare string literal means this case, because it is the common one.
    case string(String)

    /// A scalar already written in YAML's own notation — `true`, `42`, `null`
    /// — emitted verbatim rather than quoted. Only for a caller that means the
    /// *type*, not the characters.
    case yaml(String)

    /// The YAML booleans, spelled once.
    public static func bool(_ flag: Bool) -> FrontmatterValue { .yaml(flag ? "true" : "false") }

    public init(stringLiteral value: String) { self = .string(value) }
}

/// The `---`-fenced YAML-ish header that adh writes at the top of a markdown
/// document.
///
/// This is deliberately not a YAML parser. adh's own reader takes flat
/// `key: value` scalars and ignores everything else, and a local reader that
/// understood more would disagree with the server about what a document says.
/// Anything unreadable is skipped, never thrown — a malformed header must not
/// make a document unopenable.
public enum Frontmatter {

    /// `^---\r?\n([\s\S]*?)\r?\n---[ \t]*\r?\n?` — adh's `FRONTMATTER_RE`.
    private static let pattern = "^---\\r?\\n([\\s\\S]*?)\\r?\\n---[ \\t]*\\r?\\n?"

    private static let regex: NSRegularExpression = {
        // The pattern is a literal, so a throw here is a programmer error.
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: pattern, options: [])
    }()

    public static func split(_ content: String) -> FrontmatterSplit {
        let full = NSRange(content.startIndex..<content.endIndex, in: content)
        guard let match = regex.firstMatch(in: content, options: [.anchored], range: full),
              let matchRange = Range(match.range, in: content),
              let blockRange = Range(match.range(at: 1), in: content) else {
            return FrontmatterSplit(prefix: "", block: nil, body: content)
        }
        return FrontmatterSplit(
            prefix: String(content[matchRange]),
            block: String(content[blockRange]),
            body: String(content[matchRange.upperBound...])
        )
    }

    /// Lines are split on `Character.isNewline` rather than on the `"\n"`
    /// scalar: Swift's `String` groups a `"\r\n"` pair into a single
    /// extended grapheme cluster, so splitting on the `"\n"` `Character`
    /// alone silently fails to split a CRLF-authored block at all — every
    /// key but the first would be lost. (`split(_:)` above is unaffected;
    /// its fence match runs over UTF-16 code units, not `Character`s.)
    public static func parse(_ block: String) -> [String: String] {
        var values: [String: String] = [:]
        for line in block.split(omittingEmptySubsequences: false, whereSeparator: { $0.isNewline }) {
            guard let pair = scalarPair(in: String(line)) else { continue }
            values[pair.key] = pair.value
        }
        return values
    }

    public static func value(_ key: String, in content: String) -> String? {
        guard let block = split(content).block else { return nil }
        return parse(block)[key]
    }

    /// The value of `key`, but **only when a YAML parser would type it as a
    /// string** — otherwise `nil`, exactly as adh's `firstNonEmpty` drops a
    /// value that fails `typeof v === 'string'`.
    ///
    /// `value(_:in:)` returns the same key stringified, which is what every
    /// other caller wants; the title derivation cannot use it, because it
    /// cannot tell `title: 42` (a number, which adh ignores) from
    /// `title: "42"` (a string, which adh takes), and a document whose
    /// frontmatter carries `title: >-` above a folded block would otherwise be
    /// titled with the literal indicator `>-`.
    ///
    /// **This is an approximation of a YAML parser, not one.** Adding a YAML
    /// dependency to a foundation-tier package that compiles into five
    /// platforms is not a trade this reader gets to make. The residual
    /// divergence from adh: a real parser returns *null for the whole block*
    /// when it is malformed — an undefined alias, a top-level sequence — and
    /// this reader still reads keys out of such a block.
    ///
    /// The last occurrence of a duplicated key wins, as it does in `parse`.
    public static func stringValue(_ key: String, in content: String) -> String? {
        guard let block = split(content).block else { return nil }
        var found: String?
        for line in block.split(omittingEmptySubsequences: false, whereSeparator: { $0.isNewline }) {
            guard let pair = rawScalarPair(in: String(line)), pair.key == key else { continue }
            found = YAMLScalar.isString(pair.value) ? unquote(pair.value) : nil
        }
        return found
    }

    /// Rewrites one key, preserving every other line verbatim.
    ///
    /// Passing `nil` removes the key; removing the last key removes the whole
    /// block, so a document never carries an empty fence.
    ///
    /// **A duplicated key is normalised, not preserved:** the first occurrence
    /// is rewritten and every later one is deleted, so exactly one line carries
    /// the key when this returns. The readers here all take the *last*
    /// occurrence (`parse` assigns into a dictionary; `stringValue` says so
    /// outright), so a writer that touched only the first would leave a
    /// surviving duplicate answering for it — `setPinned(false)` returning a
    /// still-pinned document. One line is the only state both agree on.
    ///
    /// **The rewritten block is re-emitted with LF line endings even when the
    /// document was authored with CRLF**, and the body after the closing fence
    /// keeps whatever endings it had. That is deliberate: the block is rebuilt
    /// from parsed lines, so it has to be joined with *something*, and adh
    /// writes LF. Normalising only the block keeps the change to the bytes this
    /// call already had to rewrite instead of touching the whole document.
    /// (`settingRewritesOneLineWithCRLF` pins it.)
    ///
    /// A bare string literal is a `.string`, so `setting("title", to: "42", …)`
    /// still writes a quoted `"42"`. A caller that means a YAML *type* rather
    /// than these characters — `setPinned` writing a boolean — says so with
    /// `.yaml`/`.bool`.
    public static func setting(_ key: String, to value: FrontmatterValue?, in content: String) -> String {
        let parts = split(content)

        guard let block = parts.block else {
            guard let value else { return content }
            return "---\n\(key): \(serialize(value))\n---\n" + content
        }

        // Same CRLF-grapheme-cluster hazard as `parse` above — split on
        // newline characters, not the `"\n"` scalar.
        var lines = block.split(omittingEmptySubsequences: false, whereSeparator: { $0.isNewline }).map(String.init)
        // EVERY line carrying the key, not just the first. A block can hold
        // the same key twice — two writers appending, or a hand edit — and the
        // readers all take the LAST one, so rewriting only the first left
        // `setting` silently a no-op. Normalising the block on each write
        // dissolves the ambiguity instead of picking a side.
        let indices = lines.indices.filter { scalarPair(in: lines[$0])?.key == key }

        if let first = indices.first {
            if let value {
                lines[first] = "\(key): \(serialize(value))"
                for duplicate in indices.dropFirst().reversed() { lines.remove(at: duplicate) }
            } else {
                for duplicate in indices.reversed() { lines.remove(at: duplicate) }
            }
        } else if let value {
            lines.append("\(key): \(serialize(value))")
        } else {
            return content
        }

        let remaining = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard !remaining.isEmpty else { return parts.body }
        return "---\n" + lines.joined(separator: "\n") + "\n---\n" + parts.body
    }

    /// The parsed block as canonical JSON — sorted keys, no whitespace — ready
    /// for the `frontmatter` column. `nil` when the document has no block.
    ///
    /// **Values are YAML-typed, not stringified.** `pinned: true` becomes
    /// `{"pinned":true}` and `order: 3` becomes `{"order":3}`, because adh runs
    /// a real YAML parser and stores exactly that. A stringified projection
    /// would guarantee the flip this port exists to prevent: the client writes
    /// `{"pinned":"true"}`, the server recomputes the column on the same write
    /// and stores `{"pinned":true}`, and the row then looks dirty on every sync
    /// round trip forever.
    ///
    /// `parse` deliberately keeps returning `[String: String]` — the local
    /// readers want the text — so the typing happens here, from the *raw*
    /// scalars, through the same `YAMLScalar` predicates the writer quotes by.
    ///
    /// The residual divergences from adh's parser are recorded as tests in
    /// `MarkdownAdhParityTests`, not as prose: a block sequence, a flow
    /// mapping, a block scalar and an anchor/alias are all things a real parser
    /// understands and this one hands back as text.
    public static func jsonText(for content: String) -> String? {
        guard let block = split(content).block else { return nil }
        var values: [String: Any] = [:]
        for line in block.split(omittingEmptySubsequences: false, whereSeparator: { $0.isNewline }) {
            guard let pair = rawScalarPair(in: String(line)) else { continue }
            values[pair.key] = jsonValue(for: pair.value)
        }
        guard JSONSerialization.isValidJSONObject(values),
              let data = try? JSONSerialization.data(
                withJSONObject: values,
                options: [.sortedKeys, .withoutEscapingSlashes]
              ) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    /// One raw scalar as the JSON value a YAML parser would have produced.
    ///
    /// Order matters: `YAMLScalar.isString` is asked first because a *quoted*
    /// scalar is a string whatever its characters spell — `"42"` is not 42.
    private static func jsonValue(for raw: String) -> Any {
        // `key:` with nothing after it is YAML's null, not the empty string.
        if raw.isEmpty { return NSNull() }
        if YAMLScalar.isString(raw) { return unquote(raw) }
        if YAMLScalar.isNull(raw) { return NSNull() }
        if let flag = YAMLScalar.booleanValue(raw) { return flag }
        if let number = YAMLScalar.numberValue(raw) {
            // JSON has no infinity or NaN, and `JSON.stringify` — which is what
            // put adh's column there — writes `null` for both.
            return number.doubleValue.isFinite ? number : NSNull()
        }
        if let items = flowSequenceItems(raw) { return items.map { jsonValue(for: $0) } }
        // A block-scalar header, a flow mapping, an alias: nothing this reader
        // can type without becoming the YAML parser it declines to be. The text
        // is what it has, so the text is what it emits.
        return unquote(raw)
    }

    /// Splits a YAML flow sequence — `[a, b]`, `[1, "x, y"]` — into its item
    /// texts, or `nil` when `raw` is not one this reader will type.
    ///
    /// Worth doing rather than stringifying because a flow sequence is the one
    /// non-scalar adh's frontmatter routinely holds, and `{"allowed":"[a, b]"}`
    /// against the server's `{"allowed":["a","b"]}` is the same round-trip flip
    /// as the scalar case. Anything harder than a flat list of scalars —
    /// nesting, a flow mapping, an unclosed quote — returns `nil` and falls
    /// back to the text, because a wrong type is worse than an honest string.
    private static func flowSequenceItems(_ raw: String) -> [String]? {
        guard raw.count >= 2, raw.hasPrefix("["), raw.hasSuffix("]") else { return nil }
        let inner = String(raw.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
        guard !inner.isEmpty else { return [] }

        var items: [String] = []
        var current = ""
        var quote: Character?
        var isEscaped = false
        for character in inner {
            if let open = quote {
                current.append(character)
                if isEscaped {
                    isEscaped = false
                } else if open == "\"", character == "\\" {
                    isEscaped = true
                } else if character == open {
                    quote = nil
                }
            } else if character == "\"" || character == "'" {
                quote = character
                current.append(character)
            } else if character == "," {
                items.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else if character == "[" || character == "{" {
                return nil   // nested collection
            } else {
                current.append(character)
            }
        }
        guard quote == nil else { return nil }   // unterminated quote
        items.append(current.trimmingCharacters(in: .whitespaces))
        return items.contains(where: \.isEmpty) ? nil : items
    }

    // MARK: - Lines

    private static func scalarPair(in line: String) -> (key: String, value: String)? {
        guard let raw = rawScalarPair(in: line) else { return nil }
        return (raw.key, unquote(raw.value))
    }

    /// The same pair, with the value left exactly as it was written — quotes
    /// and all. `stringValue` needs the raw text, because whether a scalar was
    /// quoted is what decides its YAML type.
    private static func rawScalarPair(in line: String) -> (key: String, value: String)? {
        // A leading space means a nested mapping or a list item — adh's reader
        // does not descend, so neither does this one.
        guard let first = line.first, !first.isWhitespace, first != "#" else { return nil }
        guard let colon = line.firstIndex(of: ":") else { return nil }
        let key = String(line[line.startIndex..<colon]).trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return nil }
        let raw = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
        return (key, raw)
    }

    /// The exact inverse of `serialize`.
    ///
    /// A double-quoted scalar carries YAML's backslash escapes. Exactly five
    /// are recognised — `\"` → `"`, `\\` → `\`, `\n` → newline, `\r` →
    /// carriage return, `\t` → tab — which is precisely the set `serialize`
    /// can produce. **Any other escape is preserved verbatim, backslash
    /// included**: a sequence this file did not write is a sequence it does not
    /// understand, and dropping the backslash silently rewrites the document
    /// (`title: "C:\Users\me"` used to read back as `C:Usersme`, and that
    /// mangled value then synced as a genuine edit).
    ///
    /// Without the `\"`/`\\` cases a title like `Re: the "big" rewrite` gained
    /// a backslash layer on every save/load cycle. A single-quoted scalar has
    /// no backslash escapes in YAML, so its contents are taken literally.
    private static func unquote(_ value: String) -> String {
        guard value.count >= 2, let first = value.first, let last = value.last,
              first == last, first == "\"" || first == "'" else { return value }
        let inner = String(value.dropFirst().dropLast())
        guard first == "\"" else { return inner }

        var result = ""
        var isEscaped = false
        for character in inner {
            if isEscaped {
                switch character {
                case "\"": result.append("\"")
                case "\\": result.append("\\")
                case "n": result.append("\n")
                case "r": result.append("\r")
                case "t": result.append("\t")
                default: result.append("\\"); result.append(character)
                }
                isEscaped = false
            } else if character == "\\" {
                isEscaped = true
            } else {
                result.append(character)
            }
        }
        // A trailing lone backslash is malformed; keep it rather than drop it,
        // in the same fail-soft spirit as the rest of this reader.
        if isEscaped { result.append("\\") }
        return result
    }

    /// Emits `value` as the YAML scalar its case names.
    ///
    /// `.yaml` goes out verbatim — that is the whole point of the case — with
    /// one fail-soft guard: a scalar that is empty or carries a newline cannot
    /// be written bare without ending the line or breaking the fence, so it
    /// falls back to the quoted form. That is a caller error, and a quoted
    /// value is a wrong value in one key rather than a mangled document.
    private static func serialize(_ value: FrontmatterValue) -> String {
        switch value {
        case .string(let text):
            return serializeString(text)
        case .yaml(let text):
            guard text.isEmpty || text.contains(where: \.isNewline) else { return text }
            return serializeString(text)
        }
    }

    private static func serializeString(_ value: String) -> String {
        guard YAMLScalar.needsQuoting(value) else { return value }
        // Backslash first: escaping the quotes first would then escape the
        // backslashes this step just wrote. CRLF before LF and CR, because
        // Swift groups `"\r\n"` into one grapheme cluster and neither
        // single-character replacement would find it.
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r\n", with: "\\r\\n")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
        return "\"" + escaped + "\""
    }
}

/// What YAML would make of a bare (unquoted) scalar.
///
/// One predicate with two call sites, so the reader and the writer cannot
/// drift apart: `Frontmatter.stringValue` uses `isString` to drop a value adh
/// would drop (`typeof v === 'string'` is load-bearing in its `firstNonEmpty`),
/// and `Frontmatter.serialize` uses `needsQuoting` so a value we write is a
/// value adh reads back as the same string. An unquoted `title: 42` is a
/// *number* to adh: it falls through to the body heading, and the title column
/// then flips on every sync round trip.
///
/// This approximates YAML 1.2's core schema; it is not a parser. `needsQuoting`
/// is deliberately the more conservative of the two — it also quotes YAML 1.1's
/// `yes`/`no`/`on`/`off` booleans and anything opening with an indicator
/// character, because a writer that over-quotes only costs two bytes while a
/// writer that under-quotes changes a document's meaning.
enum YAMLScalar {

    /// `true` when a parser would type this scalar, exactly as written, as a
    /// string. A quoted scalar always is; a bare one is unless it reads as a
    /// number, a boolean, a null, a flow collection or a block-scalar header.
    static func isString(_ raw: String) -> Bool {
        if raw.hasPrefix("\"") || raw.hasPrefix("'") { return true }
        if raw.isEmpty { return false }
        if isNull(raw) || isBoolean(raw) || isNumber(raw) { return false }
        if raw.hasPrefix("[") || raw.hasPrefix("{") { return false }
        if isBlockScalarHeader(raw) { return false }
        return true
    }

    /// `true` when emitting `value` bare would not read back as the same
    /// string — because the line would not parse, because a reader would type
    /// it as something other than a string, or because it opens with a
    /// character YAML reserves.
    static func needsQuoting(_ value: String) -> Bool {
        if value.isEmpty { return true }
        // A raw newline would end the line: at best the tail is dropped, at
        // worst it injects a key or closes the `---` fence and promotes the
        // rest into the body.
        if value.contains(where: \.isNewline) { return true }
        if value.contains("\t") || value.contains(":") || value.contains("#") { return true }
        if value.first?.isWhitespace == true || value.last?.isWhitespace == true { return true }
        if let first = value.first, indicators.contains(first) { return true }
        if !isString(value) { return true }
        return isExtendedBoolean(value)
    }

    /// YAML's indicator characters, which may not open a plain scalar. A value
    /// that itself begins with a quote is in here too: without it, `unquote`
    /// would read `"Hamlet"` back as `Hamlet` and the document would lose the
    /// author's own quotation marks on first read.
    private static let indicators: Set<Character> = [
        "-", "?", ":", ",", "[", "]", "{", "}", "#", "&", "*", "!",
        "|", ">", "'", "\"", "%", "@", "`"
    ]

    static func isNull(_ raw: String) -> Bool {
        raw == "~" || raw.lowercased() == "null"
    }

    /// YAML 1.2's core schema: `true`/`false` in any case a reader accepts.
    private static func isBoolean(_ raw: String) -> Bool {
        booleanValue(raw) != nil
    }

    /// The boolean this bare scalar denotes, or `nil` when it is not one.
    /// Same rule as `isBoolean`, spelled once, so the predicate that decides
    /// whether to quote and the projection that decides what JSON to write can
    /// never answer differently.
    static func booleanValue(_ raw: String) -> Bool? {
        switch raw.lowercased() {
        case "true": return true
        case "false": return false
        default: return nil
        }
    }

    /// The number this bare scalar denotes, or `nil` when it is not one.
    ///
    /// `NSNumber` rather than `Double`, because `JSONSerialization` writes an
    /// integer-typed one as `3` and a double-typed one as `3.0` — and adh's
    /// column holds `3`. `.inf`/`.nan` come back as the non-finite doubles
    /// they name; the caller decides what JSON can do with those.
    static func numberValue(_ raw: String) -> NSNumber? {
        guard isNumber(raw) else { return nil }
        if raw.hasPrefix("0o"), let value = Int(raw.dropFirst(2), radix: 8) { return NSNumber(value: value) }
        if raw.hasPrefix("0x"), let value = Int(raw.dropFirst(2), radix: 16) { return NSNumber(value: value) }
        if let value = Int(raw) { return NSNumber(value: value) }
        let lowered = raw.lowercased()
        if lowered.hasSuffix(".inf") {
            return NSNumber(value: lowered.hasPrefix("-") ? -Double.infinity : Double.infinity)
        }
        if lowered.hasSuffix(".nan") { return NSNumber(value: Double.nan) }
        // An integer too large for `Int` also lands here, as a double — the
        // same widening `JSON.stringify` would have applied.
        guard let value = Double(raw) else { return nil }
        return NSNumber(value: value)
    }

    /// YAML 1.1's extra booleans. Readers disagree about these, so the writer
    /// quotes them and the reader does not reject them.
    private static func isExtendedBoolean(_ raw: String) -> Bool {
        ["yes", "no", "on", "off"].contains(raw.lowercased())
    }

    private static let numberPattern = [
        "[-+]?[0-9]+",                                        // decimal int
        "0o[0-7]+",                                           // octal
        "0x[0-9a-fA-F]+",                                     // hex
        "[-+]?(?:\\.[0-9]+|[0-9]+(?:\\.[0-9]*)?)(?:[eE][-+]?[0-9]+)?",  // float
        "[-+]?\\.(?:inf|Inf|INF)",
        "\\.(?:nan|NaN|NAN)"
    ].joined(separator: "|")

    private static let number: NSRegularExpression = {
        // The pattern is a literal, so a throw here is a programmer error.
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: "\\A(?:" + numberPattern + ")\\z", options: [])
    }()

    private static func isNumber(_ raw: String) -> Bool {
        let range = NSRange(raw.startIndex..<raw.endIndex, in: raw)
        return number.firstMatch(in: raw, options: [], range: range) != nil
    }

    /// `>` or `|`, alone or carrying a chomping indicator and/or an explicit
    /// indent — `>-`, `|+`, `>2`, `|2-`. A document whose frontmatter opens a
    /// folded block used to be titled with the literal indicator.
    private static func isBlockScalarHeader(_ raw: String) -> Bool {
        guard let first = raw.first, first == ">" || first == "|" else { return false }
        var sawIndent = false
        var sawChomping = false
        for character in raw.dropFirst() {
            if character.isNumber, !sawIndent {
                sawIndent = true
            } else if character == "-" || character == "+", !sawChomping {
                sawChomping = true
            } else {
                return false
            }
        }
        return true
    }
}
