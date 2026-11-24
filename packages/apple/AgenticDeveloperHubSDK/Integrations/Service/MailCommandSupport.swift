import Foundation

/// The JSON shape the MCP tools and the `--json` flag both print.
enum MailJSON {
    static func encode<Value: Encodable>(_ value: Value) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        guard let text = String(bytes: data, encoding: .utf8) else {
            throw EncodingError.invalidValue(value, .init(codingPath: [], debugDescription: "not UTF-8"))
        }
        return text
    }
}

/// Reads a `since`/`until` value. `YYYY-MM-DD` becomes the start or end of that UTC day; a full
/// ISO-8601 timestamp is converted to UTC (`yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`), because the store
/// compares UTC strings lexically. Anything else, including a date that does not exist, is rejected.
enum MailDateBound {
    enum Edge { case start, end }

    static func normalize(_ text: String, edge: Edge) -> String? {
        if let valid = isRealDate(text) {
            return valid ? text + (edge == .start ? "T00:00:00.000Z" : "T23:59:59.999Z") : nil
        }
        return timestamp(text).map(IntegrationClock.string(from:))
    }

    /// `nil` when `text` is not shaped `YYYY-MM-DD`; otherwise whether that date exists.
    private static func isRealDate(_ text: String) -> Bool? {
        let parts = text.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
              text.allSatisfy({ $0 == "-" || $0.isASCII && $0.isNumber }),
              let year = Int(parts[0]), let month = Int(parts[1]), let day = Int(parts[2]) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: components) else { return false }
        let round = calendar.dateComponents([.year, .month, .day], from: date)
        return round.year == year && round.month == month && round.day == day
    }

    private static func timestamp(_ text: String) -> Date? {
        for options: ISO8601DateFormatter.Options in [
            [.withInternetDateTime, .withFractionalSeconds], [.withInternetDateTime]
        ] {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = options
            if let date = formatter.date(from: text) { return date }
        }
        return nil
    }
}
