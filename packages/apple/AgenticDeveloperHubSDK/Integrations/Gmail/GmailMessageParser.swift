import Foundation

/// Turns a Gmail `format=full` message into an `EmailMessage`.
public enum GmailMessageParser {

    /// - Parameter now: the date given to a message that carries neither `internalDate` nor a
    ///   readable `Date` header, so it sorts as new rather than as 1970.
    public static func parse(
        _ dto: GmailMessageDTO, connectionId: String, existingId: String?, now: Date = Date()
    ) -> EmailMessage {
        let headers = dto.payload?.headers ?? []
        let labelIds = dto.labelIds ?? []
        var content = Content()
        if let payload = dto.payload { walk(payload, into: &content) }
        return EmailMessage(
            id: existingId ?? UUID().uuidString.lowercased(),
            connectionId: connectionId,
            externalId: dto.id,
            threadId: dto.threadId,
            fromAddress: header("From", in: headers) ?? "",
            toAddresses: splitAddresses(header("To", in: headers)),
            ccAddresses: splitAddresses(header("Cc", in: headers)),
            subject: header("Subject", in: headers) ?? "",
            snippet: dto.snippet ?? "",
            bodyText: content.text,
            bodyHtml: content.html,
            labelIds: labelIds,
            internalDate: IntegrationClock.string(
                from: date(fromEpochMillis: dto.internalDate) ?? date(fromHeader: header("Date", in: headers)) ?? now),
            historyId: dto.historyId,
            attachments: content.attachments,
            mailClass: MailClassifier.classify(labelIds: labelIds)
        )
    }

    // MARK: - Parts

    private struct Content {
        var text: String?
        var html: String?
        var attachments: [EmailAttachmentRef] = []
    }

    /// - Parameter inBody: whether `part` is still the message's own content. A named part
    ///   or an embedded `message/rfc822` is something the message carries — a bounce's
    ///   original, a forwarded `.eml` — and nothing inside it is this message's body, though
    ///   the files inside it are still listed.
    private static func walk(_ part: GmailPart, into content: inout Content, inBody: Bool = true) {
        let mime = (part.mimeType ?? "").lowercased()
        let filename = part.filename ?? ""
        let childrenInBody = inBody && filename.isEmpty && mime != "message/rfc822"
        if !filename.isEmpty, let attachmentId = part.body?.attachmentId {
            content.attachments.append(EmailAttachmentRef(
                attachmentId: attachmentId, filename: filename,
                mimeType: part.mimeType ?? "application/octet-stream", size: part.body?.size ?? 0
            ))
        } else if !filename.isEmpty {
            // A named part is a file even when Gmail inlined it; it is never the message body.
        } else if !inBody {
            // Inside an attachment or an embedded message: not this message's text.
        } else if mime == "text/plain", content.text == nil, let decoded = decodeBody(part) {
            content.text = decoded
        } else if mime == "text/html", content.html == nil, let decoded = decodeBody(part) {
            content.html = decoded
        }
        for child in part.parts ?? [] { walk(child, into: &content, inBody: childrenInBody) }
    }

    private static func decodeBody(_ part: GmailPart) -> String? {
        guard let encoded = part.body?.data, let data = base64URLDecode(encoded) else { return nil }
        let charset = header("Content-Type", in: part.headers ?? []).flatMap(charsetName)
        if let charset, let encoding = stringEncoding(ianaName: charset),
           let string = String(data: data, encoding: encoding) {
            return string
        }
        return String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1)
    }

    static func base64URLDecode(_ string: String) -> Data? {
        var base64 = string.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        return Data(base64Encoded: base64)
    }

    private static func charsetName(fromContentType value: String) -> String? {
        for piece in value.split(separator: ";").dropFirst() {
            let pair = piece.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if pair.count == 2, pair[0].lowercased() == "charset" {
                return pair[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            }
        }
        return nil
    }

    private static func stringEncoding(ianaName: String) -> String.Encoding? {
        let cfEncoding = CFStringConvertIANACharSetNameToEncoding(ianaName as CFString)
        guard cfEncoding != kCFStringEncodingInvalidId else { return nil }
        return String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
    }

    // MARK: - Headers and dates

    private static func header(_ name: String, in headers: [GmailHeader]) -> String? {
        headers.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.value
    }

    /// Splits on commas that are outside double quotes.
    static func splitAddresses(_ value: String?) -> [String] {
        guard let value else { return [] }
        var parts: [String] = []
        var current = ""
        var inQuotes = false
        var escaped = false
        for char in value {
            if escaped {
                escaped = false
                current.append(char)
            } else if char == "\\" && inQuotes {
                escaped = true
                current.append(char)
            } else if char == "\"" {
                inQuotes.toggle()
                current.append(char)
            } else if char == "," && !inQuotes {
                parts.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        parts.append(current)
        return parts.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private static func date(fromEpochMillis value: String?) -> Date? {
        guard let millis = value.flatMap(Double.init) else { return nil }
        return Date(timeIntervalSince1970: millis / 1000)
    }

    /// Reads an RFC 5322 `Date` header, with or without the weekday and a trailing comment.
    private static func date(fromHeader value: String?) -> Date? {
        guard var value = value?.trimmingCharacters(in: .whitespaces), !value.isEmpty else { return nil }
        if let comment = value.firstIndex(of: "(") {
            value = value[..<comment].trimmingCharacters(in: .whitespaces)
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in ["EEE, d MMM yyyy HH:mm:ss Z", "d MMM yyyy HH:mm:ss Z", "EEE, d MMM yyyy HH:mm Z"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }
}
