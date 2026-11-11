import Foundation

/// Reads HTML mail as plain text, and decodes the HTML entities Gmail leaves in snippets.
///
/// Deliberately small: no layout engine, no WebKit (which wants the main thread), just enough to
/// make an HTML-only message readable in a terminal or to a model. `head`, `style`, `script`,
/// `title` and comments are dropped; block elements and `<br>` become line breaks (a paragraph
/// or heading a blank line); every other tag is removed; entities are decoded; whitespace is
/// collapsed as a browser would, keeping the line breaks.
public enum MailHTMLText {
    /// The text of `html`.
    public static func plainText(fromHTML html: String) -> String {
        var text = html
        // Whole elements whose content is never shown.
        text = replace(#"<!--.*?-->"#, in: text, with: " ")
        for element in ["head", "style", "script", "title", "noscript"] {
            text = replace("<\(element)\\b[^>]*>.*?</\(element)\\s*>", in: text, with: " ")
        }
        // Source whitespace is insignificant in HTML: any run of it is one space.
        text = replace(#"\s+"#, in: text, with: " ")
        // `<br>` is a real line break; block boundaries are soft ones that merge with their
        // neighbours, so `</div><div>` is one line break, not a blank line.
        text = replace(#"<br\b[^>]*>"#, in: text, with: "\n")
        text = replace(#"<li\b[^>]*>"#, in: text, with: "\(lineBreak)- ")
        text = replace(#"</?(?:p|h[1-6]|blockquote|table|ul|ol|dl|pre|hr)\b[^>]*>"#, in: text, with: paragraphBreak)
        text = replace("</?(?:\(lineElements.joined(separator: "|")))\\b[^>]*>", in: text, with: lineBreak)
        text = replace(#"</?(?:td|th)\b[^>]*>"#, in: text, with: " ")
        text = replace(#"<[^>]*>"#, in: text, with: "")
        text = resolveBreaks(text)
        text = decodeEntities(text)
        return tidy(text)
    }

    /// Block elements that start and end a line.
    private static let lineElements = [
        "div", "tr", "li", "dt", "dd", "section", "article", "header", "footer", "nav", "aside", "main",
        "address", "figure", "figcaption", "center", "form", "fieldset"
    ]

    /// Soft break markers: control characters no mail body text carries.
    private static let lineBreak = "\u{1}"
    private static let paragraphBreak = "\u{2}"

    /// Turns each run of soft breaks into the largest one in it, counting the newlines the text
    /// already ends with, and drops soft breaks at the very start and end.
    private static func resolveBreaks(_ text: String) -> String {
        var result = ""
        var pending = 0
        var trailingNewlines = 0
        for char in text {
            switch char {
            case "\u{1}": pending = max(pending, 1)
            case "\u{2}": pending = max(pending, 2)
            case " " where pending > 0:
                continue
            default:
                if pending > 0, !result.isEmpty {
                    let needed = pending - trailingNewlines
                    if needed > 0 {
                        result += String(repeating: "\n", count: needed)
                        trailingNewlines += needed
                    }
                }
                pending = 0
                result.append(char)
                trailingNewlines = char == "\n" ? trailingNewlines + 1 : 0
            }
        }
        return result
    }

    /// `text` with its HTML character references decoded: the common named ones and every
    /// numeric one (`&#39;`, `&#x27;`), reading `&#128;`–`&#159;` as windows-1252 the way
    /// browsers do. One that is malformed or unknown is left as written. Control characters
    /// other than tab and line breaks are dropped, decoded or raw, so mail can't write terminal
    /// escape sequences.
    /// Invisible padding characters (zero-width spaces, soft hyphens, and joiners that join
    /// nothing) are dropped: marketing mail fills its preview text with them.
    public static func decodeEntities(_ text: String) -> String {
        guard text.contains("&") else { return stripInvisible(text) }
        // Scalars, not Characters: a `;` or `&` followed by a combining mark or joiner (preview
        // padding is often `&nbsp;` then U+034F) forms one Character with it.
        let scalars = Array(text.unicodeScalars)
        var result = String.UnicodeScalarView()
        var index = 0
        while index < scalars.count {
            guard scalars[index] == "&", let (decoded, end) = reference(in: scalars, at: index) else {
                result.append(scalars[index])
                index += 1
                continue
            }
            result.append(contentsOf: decoded.unicodeScalars)
            index = end
        }
        return stripInvisible(String(result))
    }

    // MARK: - Entities

    /// The character reference starting at `start` (an `&`) and the index just past its `;`.
    private static func reference(in scalars: [Unicode.Scalar], at start: Int) -> (String, Int)? {
        let body = start + 1
        // Names and numbers are short; looking further only finds the next sentence's `;`.
        guard let semicolon = scalars[body..<min(scalars.count, body + 12)].firstIndex(of: ";") else { return nil }
        var nameScalars = String.UnicodeScalarView()
        nameScalars.append(contentsOf: scalars[body..<semicolon])
        let name = String(nameScalars)
        let end = semicolon + 1
        if name.hasPrefix("#") {
            guard let value = numericValue(name.dropFirst()), value != 0 else { return nil }
            if let mapped = windows1252[value] { return (String(mapped), end) }
            guard let scalar = Unicode.Scalar(value) else { return nil }
            return (isControl(scalar) ? "" : String(scalar), end)
        }
        guard let decoded = named[name] else { return nil }
        return (decoded, end)
    }

    /// The value of a numeric reference's digits (`39`, `x27`): ASCII digits only, so no sign
    /// or space, and at most eight of them.
    private static func numericValue(_ digits: Substring) -> UInt32? {
        let hex = digits.first == "x" || digits.first == "X"
        let number = hex ? digits.dropFirst() : digits
        guard (1...8).contains(number.count),
              number.unicodeScalars.allSatisfy({ hex ? $0.properties.isASCIIHexDigit : ("0"..."9").contains($0) })
        else { return nil }
        return UInt32(number, radix: hex ? 16 : 10)
    }

    /// What browsers show for `&#128;`–`&#159;`: the windows-1252 characters Word and Outlook
    /// meant. The five codes windows-1252 leaves undefined stay controls (and are dropped).
    private static let windows1252: [UInt32: Character] = [
        0x80: "€", 0x82: "‚", 0x83: "ƒ", 0x84: "„", 0x85: "…", 0x86: "†", 0x87: "‡", 0x88: "ˆ",
        0x89: "‰", 0x8A: "Š", 0x8B: "‹", 0x8C: "Œ", 0x8E: "Ž", 0x91: "‘", 0x92: "’", 0x93: "“",
        0x94: "”", 0x95: "•", 0x96: "–", 0x97: "—", 0x98: "˜", 0x99: "™", 0x9A: "š", 0x9B: "›",
        0x9C: "œ", 0x9E: "ž", 0x9F: "Ÿ"
    ]

    /// C0 controls other than tab, line feed and carriage return; DEL; C1 controls.
    private static func isControl(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x09, 0x0A, 0x0D: return false
        case 0x00...0x1F, 0x7F...0x9F: return true
        default: return false
        }
    }

    private static let named: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": "\u{00A0}",
        "ensp": "\u{2002}", "emsp": "\u{2003}", "thinsp": "\u{2009}",
        "zwnj": "\u{200C}", "zwj": "\u{200D}", "shy": "\u{00AD}",
        "ndash": "–", "mdash": "—", "hellip": "…", "bull": "•", "middot": "·",
        "lsquo": "‘", "rsquo": "’", "sbquo": "‚", "ldquo": "“", "rdquo": "”", "bdquo": "„",
        "laquo": "«", "raquo": "»", "lsaquo": "‹", "rsaquo": "›",
        "copy": "©", "reg": "®", "trade": "™", "deg": "°", "plusmn": "±", "times": "×", "divide": "÷",
        "euro": "€", "pound": "£", "cent": "¢", "yen": "¥", "sect": "§", "para": "¶",
        "dagger": "†", "Dagger": "‡", "prime": "′", "Prime": "″", "larr": "←", "rarr": "→",
        "uarr": "↑", "darr": "↓", "frac12": "½", "frac14": "¼", "frac34": "¾", "iexcl": "¡",
        "iquest": "¿", "aacute": "á", "eacute": "é", "iacute": "í", "oacute": "ó", "uacute": "ú",
        "Aacute": "Á", "Eacute": "É", "Iacute": "Í", "Oacute": "Ó", "Uacute": "Ú",
        "agrave": "à", "egrave": "è", "ograve": "ò", "auml": "ä", "euml": "ë", "ouml": "ö", "uuml": "ü",
        "Auml": "Ä", "Ouml": "Ö", "Uuml": "Ü", "ntilde": "ñ", "Ntilde": "Ñ", "ccedil": "ç", "szlig": "ß"
    ]

    /// Characters that take no space and mean nothing: zero-width space, word joiner, BOM, soft
    /// hyphen and the combining grapheme joiner.
    private static let invisible: Set<Unicode.Scalar> = ["\u{200B}", "\u{2060}", "\u{FEFF}", "\u{00AD}", "\u{034F}"]
    /// The zero-width non-joiner and joiner shape the characters on either side (emoji sequences
    /// such as 👨‍💻, Persian and Indic words), so they are kept between two visible characters and
    /// dropped only where they join nothing, as preview-text padding does.
    private static let joiners: Set<Unicode.Scalar> = ["\u{200C}", "\u{200D}"]

    private static func stripInvisible(_ text: String) -> String {
        let scalars = Array(text.unicodeScalars)
        guard scalars.contains(where: { invisible.contains($0) || joiners.contains($0) || isControl($0) }) else {
            return text
        }
        var result = String.UnicodeScalarView()
        for (index, scalar) in scalars.enumerated() where !invisible.contains(scalar) && !isControl(scalar) {
            if joiners.contains(scalar) {
                let next = scalars[(index + 1)...].first { !invisible.contains($0) && !isControl($0) }
                guard let previous = result.last, joinable(previous), let next, joinable(next) else { continue }
            }
            result.append(scalar)
        }
        return String(result)
    }

    private static func joinable(_ scalar: Unicode.Scalar) -> Bool {
        !joiners.contains(scalar) && !scalar.properties.isWhitespace
    }

    // MARK: - Whitespace

    /// Non-breaking and other spaces become plain ones; each line is trimmed and its spaces
    /// collapsed; more than one blank line in a row becomes one.
    private static func tidy(_ text: String) -> String {
        let spaces = CharacterSet.whitespaces
        var lines: [String] = []
        var blank = 0
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        for raw in normalized.components(separatedBy: "\n") {
            let line = raw.components(separatedBy: spaces).filter { !$0.isEmpty }.joined(separator: " ")
            if line.isEmpty {
                blank += 1
                if blank == 1, !lines.isEmpty { lines.append("") }
            } else {
                blank = 0
                lines.append(line)
            }
        }
        while lines.last == "" { lines.removeLast() }
        return lines.joined(separator: "\n")
    }

    // MARK: - Regular expressions

    private static func replace(_ pattern: String, in text: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(
            in: text, range: range, withTemplate: NSRegularExpression.escapedTemplate(for: template))
    }
}
