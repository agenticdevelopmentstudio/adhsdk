import Foundation

/// The JSON shape the MCP tools and the `--json` flag both print.
enum MailJSON {
    static func encode<Value: Encodable>(_ value: Value) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value), let text = String(bytes: data, encoding: .utf8) else {
            return "{}"
        }
        return text
    }
}

/// Reads a `since`/`until` value: `YYYY-MM-DD` is expanded to the start or end of that UTC day,
/// a full ISO-8601 timestamp is kept as given, anything else is rejected.
enum MailDateBound {
    enum Edge { case start, end }

    static func normalize(_ text: String, edge: Edge) -> String? {
        if isDateOnly(text) {
            return text + (edge == .start ? "T00:00:00.000Z" : "T23:59:59.999Z")
        }
        return isTimestamp(text) ? text : nil
    }

    private static func isDateOnly(_ text: String) -> Bool {
        guard text.count == 10 else { return false }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: text) != nil
    }

    private static func isTimestamp(_ text: String) -> Bool {
        for options: ISO8601DateFormatter.Options in [
            [.withInternetDateTime], [.withInternetDateTime, .withFractionalSeconds]
        ] {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = options
            if formatter.date(from: text) != nil { return true }
        }
        return false
    }
}
