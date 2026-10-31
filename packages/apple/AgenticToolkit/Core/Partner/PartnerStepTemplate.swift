import Foundation

/// Fills `{key}` placeholders in step commands.
public enum PartnerStepTemplate {
    // swiftlint:disable:next force_try
    private static let placeholder = try! NSRegularExpression(pattern: #"\{(\w+)\}"#)

    /// Replaces each `{key}` that has a value; unknown keys stay as written.
    ///
    /// One pass over the original command: a value is never scanned again, so a value that itself contains
    /// `{key}` (a commit subject someone else wrote, say) is typed as written, not substituted.
    public static func fill(_ command: String, values: [String: String]) -> String {
        let source = command as NSString
        var result = ""
        var cursor = 0
        for match in placeholder.matches(in: command, range: NSRange(location: 0, length: source.length)) {
            let key = source.substring(with: match.range(at: 1))
            guard let value = values[key] else { continue }
            result += source.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
            result += value
            cursor = match.range.location + match.range.length
        }
        result += source.substring(from: cursor)
        return result
    }

    /// A terminal step is a shell command line, so each value goes in as one shell word (`shellQuoted`); a
    /// Claude step is a prompt, and its values are typed as written.
    public static func fill(_ steps: [PartnerJobStep], values: [String: String]) -> [PartnerJobStep] {
        let quoted = values.mapValues(shellQuoted)
        return steps.map { step in
            var filled = step
            filled.command = fill(step.command, values: step.environment == .terminal ? quoted : values)
            return filled
        }
    }

    /// `value` as a single zsh word: as written when every character is one no shell treats specially, so
    /// `claude --model opus` still reads naturally, and single-quoted otherwise (`opus[1m]` would be a glob).
    public static func shellQuoted(_ value: String) -> String {
        if !value.isEmpty, value.unicodeScalars.allSatisfy(plainWord.contains) { return value }
        return "'" + value.replacingOccurrences(of: "'", with: #"'\''"#) + "'"
    }

    /// No `=` (a leading one is zsh's command-path expansion) and no `~`.
    private static let plainWord = CharacterSet(
        charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-./:@+,")
}
