#if canImport(AgenticDeveloperHubSDKCore)
import AgenticDeveloperHubSDKCore
import Foundation

/// One header field as the client sent it. Order and the name's case are kept.
struct HTTPHeaderField: Equatable, Sendable {
    let name: String
    let value: String
}

struct RouterRequestHead: Equatable, Sendable {
    let method: String
    /// Origin-form only: always starts with "/".
    let target: String
    let version: String
    let fields: [HTTPHeaderField]

    /// The target without its query.
    var path: String { String(target.prefix { $0 != "?" }) }

    func values(_ name: String) -> [String] {
        let wanted = name.lowercased()
        return fields.filter { $0.name.lowercased() == wanted }.map(\.value)
    }

    func value(_ name: String) -> String? { values(name).first }

    var expectsContinue: Bool { value("expect")?.lowercased() == "100-continue" }
}

/// A request the router answers itself, because it cannot be forwarded safely.
enum RequestRejection: Error, Equatable, Sendable {
    case badRequest(String)
    case payloadTooLarge
    case headersTooLarge
    case notImplemented(String)

    var status: Int {
        switch self {
        case .badRequest: return 400
        case .payloadTooLarge: return 413
        case .headersTooLarge: return 431
        case .notImplemented: return 501
        }
    }

    /// Fixed text for the response body. Never echoes request bytes.
    var reason: String {
        switch self {
        case .badRequest: return "Bad Request"
        case .payloadTooLarge: return "Payload Too Large"
        case .headersTooLarge: return "Request Header Fields Too Large"
        case .notImplemented: return "Not Implemented"
        }
    }
}

enum RequestParseEvent: Equatable, Sendable {
    /// The head is in: the caller may answer `Expect: 100-continue` now.
    case head(RouterRequestHead)
    /// The whole request, body de-chunked.
    case complete(RouterRequestHead, Data)
}

/// An incremental, binary-safe HTTP/1.1 request parser for one request.
///
/// Strict where a lenient parser would let one request be read two ways:
/// - `Content-Length` together with `Transfer-Encoding` → 400;
/// - any transfer coding other than plain `chunked` → 501;
/// - obs-fold, a bare CR or LF, a NUL or other control byte in the head → 400;
/// - a target that is not origin-form (does not start with "/") → 400.
struct RouterRequestParser {
    static let maxBodyBytes = 64 * 1024 * 1024
    static let maxHeaderBytes = 64 * 1024
    private static let maxChunkLine = 1024
    private static let chunkLineTooLong = RequestRejection.badRequest("chunk size line too long")
    private static let crlf: [UInt8] = [13, 10]
    private static let headEnd: [UInt8] = [13, 10, 13, 10]

    private enum Phase: Equatable {
        case head
        case fixed(remaining: Int)
        case chunkSize
        case chunkData(remaining: Int)
        case chunkEnd
        case trailers
        case done
    }

    private let bodyLimit: Int
    private let headerLimit: Int
    private var phase = Phase.head
    private var buffer: [UInt8] = []
    private var cursor = 0
    /// Where the next search for the end of the head starts.
    private var scanFrom = 0
    /// Where the next search for the end of a chunk-size or trailer line starts.
    private var lineScanFrom = 0
    private var head: RouterRequestHead?
    /// Built in place and handed over as is: one copy of the body, never two.
    private var body = Data()
    private var trailerBytes = 0

    /// Body bytes to reserve against the router's in-flight body budget once
    /// the head is in: the declared `Content-Length`, else 0. A chunked body's
    /// size is not known up front, so it reserves nothing here and grows its
    /// reservation as bytes arrive (``growsBody``, ``bytesHeld``).
    private(set) var bodyReservation = 0

    /// The body cap this parser enforces.
    var maxBody: Int { bodyLimit }

    /// Reading a chunked body: its reservation must grow with ``bytesHeld``.
    var growsBody: Bool {
        switch phase {
        case .chunkSize, .chunkData, .chunkEnd, .trailers: return true
        case .head, .fixed, .done: return false
        }
    }

    /// Bytes of this request's body held in memory: de-chunked so far plus
    /// received and not yet parsed.
    var bytesHeld: Int { body.count + buffer.count - cursor }

    init(
        maxBodyBytes: Int = RouterRequestParser.maxBodyBytes,
        maxHeaderBytes: Int = RouterRequestParser.maxHeaderBytes
    ) {
        self.bodyLimit = maxBodyBytes
        self.headerLimit = maxHeaderBytes
    }

    var isComplete: Bool { phase == .done }

    mutating func feed(_ data: Data) throws -> [RequestParseEvent] {
        guard phase != .done else { return [] }
        buffer.append(contentsOf: data)
        var events: [RequestParseEvent] = []
        while try advance(&events) {}
        compact()
        return events
    }

    /// One step of the state machine; false when it needs more bytes.
    private mutating func advance(_ events: inout [RequestParseEvent]) throws -> Bool {
        switch phase {
        case .head:
            return try readHead(&events)
        case .fixed(let remaining):
            let taken = takeBody(upTo: remaining)
            guard taken > 0 else { return false }
            if remaining == taken { finish(&events) } else { phase = .fixed(remaining: remaining - taken) }
            return true
        case .chunkSize:
            guard let line = try readLine(limit: Self.maxChunkLine, overflow: Self.chunkLineTooLong) else {
                return false
            }
            let size = try Self.chunkSize(line)
            guard body.count + size <= bodyLimit else { throw RequestRejection.payloadTooLarge }
            phase = size == 0 ? .trailers : .chunkData(remaining: size)
            return true
        case .chunkData(let remaining):
            let taken = takeBody(upTo: remaining)
            guard taken > 0 else { return false }
            phase = remaining == taken ? .chunkEnd : .chunkData(remaining: remaining - taken)
            return true
        case .chunkEnd:
            guard buffer.count - cursor >= 2 else { return false }
            guard buffer[cursor] == 13, buffer[cursor + 1] == 10 else {
                throw RequestRejection.badRequest("chunk not followed by CRLF")
            }
            cursor += 2
            phase = .chunkSize
            return true
        case .trailers:
            guard let line = try readLine(limit: headerLimit - trailerBytes,
                                         overflow: .headersTooLarge) else { return false }
            trailerBytes += line.count + 2
            guard trailerBytes <= headerLimit else { throw RequestRejection.headersTooLarge }
            if line.isEmpty { finish(&events) }
            return true
        case .done:
            return false
        }
    }

    private mutating func readHead(_ events: inout [RequestParseEvent]) throws -> Bool {
        guard let end = find(Self.headEnd, from: max(cursor, scanFrom)) else {
            scanFrom = max(cursor, buffer.count - 3)
            if buffer.count - cursor > headerLimit { throw RequestRejection.headersTooLarge }
            return false
        }
        guard end + 4 - cursor <= headerLimit else { throw RequestRejection.headersTooLarge }
        let parsed = try Self.parseHead(Array(buffer[cursor..<end]))
        cursor = end + 4
        head = parsed
        events.append(.head(parsed))
        phase = try framing(parsed)
        if phase == .done { finish(&events) }
        return phase != .done
    }

    private mutating func framing(_ head: RouterRequestHead) throws -> Phase {
        let codings = head.values("transfer-encoding")
        let lengths = head.values("content-length")
        if !codings.isEmpty && !lengths.isEmpty {
            throw RequestRejection.badRequest("content-length with transfer-encoding")
        }
        if !codings.isEmpty {
            let tokens = codings.joined(separator: ",").split(separator: ",")
                .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \t")).lowercased() }
                .filter { !$0.isEmpty }
            guard tokens == ["chunked"] else { throw RequestRejection.notImplemented("transfer-encoding") }
            return .chunkSize
        }
        guard !lengths.isEmpty else { return .done }
        let parts = lengths.joined(separator: ",").split(separator: ",", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \t")) }
        var declared: Int?
        for part in parts {
            guard !part.isEmpty, part.count <= 18, part.allSatisfy({ $0.isASCII && $0.isNumber }),
                  let value = Int(part), declared == nil || declared == value else {
                throw RequestRejection.badRequest("content-length")
            }
            declared = value
        }
        let length = declared ?? 0
        guard length <= bodyLimit else { throw RequestRejection.payloadTooLarge }
        if length == 0 { return .done }
        bodyReservation = length
        body.reserveCapacity(length)
        return .fixed(remaining: length)
    }

    private mutating func finish(_ events: inout [RequestParseEvent]) {
        phase = .done
        guard let head else { return }
        events.append(.complete(head, body))
        // Drop the parser's reference so the event's `Data` is the only owner
        // and nothing ever triggers a copy-on-write of the body.
        body = Data()
    }

    private mutating func takeBody(upTo wanted: Int) -> Int {
        let taken = min(wanted, buffer.count - cursor)
        guard taken > 0 else { return 0 }
        buffer[cursor..<(cursor + taken)].withUnsafeBufferPointer { body.append($0) }
        cursor += taken
        return taken
    }

    /// The bytes up to the next CRLF (consumed), or nil if it has not arrived.
    /// A line longer than `limit` throws `overflow`. The scan resumes where the
    /// last feed stopped, so a line trickled in byte by byte is scanned once.
    private mutating func readLine(limit: Int, overflow: RequestRejection) throws -> [UInt8]? {
        guard let end = find(Self.crlf, from: max(cursor, lineScanFrom)) else {
            if buffer.count - cursor > max(0, limit) { throw overflow }
            lineScanFrom = max(cursor, buffer.count - 1)
            return nil
        }
        guard end - cursor <= max(0, limit) else { throw overflow }
        let line = Array(buffer[cursor..<end])
        cursor = end + 2
        lineScanFrom = 0
        return line
    }

    private func find(_ needle: [UInt8], from start: Int) -> Int? {
        let last = buffer.count - needle.count
        guard last >= 0, start <= last else { return nil }
        var index = start
        while index <= last {
            if buffer[index] == needle[0] {
                var offset = 1
                while offset < needle.count && buffer[index + offset] == needle[offset] { offset += 1 }
                if offset == needle.count { return index }
            }
            index += 1
        }
        return nil
    }

    private mutating func compact() {
        if cursor == buffer.count {
            buffer.removeAll(keepingCapacity: buffer.count <= 1 << 20)
        } else if cursor > 1 << 16 {
            buffer.removeFirst(cursor)
        } else {
            return
        }
        scanFrom = max(0, scanFrom - cursor)
        lineScanFrom = max(0, lineScanFrom - cursor)
        cursor = 0
    }

    // MARK: - Head

    private static func parseHead(_ bytes: [UInt8]) throws -> RouterRequestHead {
        var lines: [[UInt8]] = []
        var start = 0
        var index = 0
        while index < bytes.count {
            if bytes[index] == 13 && index + 1 < bytes.count && bytes[index + 1] == 10 {
                lines.append(Array(bytes[start..<index]))
                index += 2
                start = index
            } else {
                index += 1
            }
        }
        lines.append(Array(bytes[start..<bytes.count]))
        guard let requestLine = lines.first else { throw RequestRejection.badRequest("empty head") }
        for line in lines where line.contains(where: { $0 < 0x20 && $0 != 0x09 || $0 == 0x7F }) {
            throw RequestRejection.badRequest("control byte in head")
        }
        let (method, target, version) = try parseRequestLine(requestLine)
        var fields: [HTTPHeaderField] = []
        for line in lines.dropFirst() {
            fields.append(try parseField(line))
        }
        return RouterRequestHead(method: method, target: target, version: version, fields: fields)
    }

    private static func parseRequestLine(_ line: [UInt8]) throws -> (String, String, String) {
        let parts = line.split(separator: 0x20, omittingEmptySubsequences: false)
        guard parts.count == 3 else { throw RequestRejection.badRequest("request line") }
        let method = String(bytes: parts[0], encoding: .utf8) ?? ""
        let target = String(bytes: parts[1], encoding: .utf8) ?? ""
        let version = String(bytes: parts[2], encoding: .utf8) ?? ""
        guard !method.isEmpty, parts[0].allSatisfy(isTokenByte) else { throw RequestRejection.badRequest("method") }
        guard target.hasPrefix("/"), !parts[1].contains(where: { $0 > 0x7E }) else {
            throw RequestRejection.badRequest("target")
        }
        guard version == "HTTP/1.1" || version == "HTTP/1.0" else { throw RequestRejection.badRequest("version") }
        return (method, target, version)
    }

    private static func parseField(_ line: [UInt8]) throws -> HTTPHeaderField {
        guard let first = line.first, first != 0x20, first != 0x09 else {
            throw RequestRejection.badRequest("obs-fold or empty field line")
        }
        guard let colon = line.firstIndex(of: 0x3A), colon > 0 else { throw RequestRejection.badRequest("field") }
        let name = line[..<colon]
        guard name.allSatisfy(isTokenByte) else { throw RequestRejection.badRequest("field name") }
        var value = line[(colon + 1)...]
        while let lead = value.first, lead == 0x20 || lead == 0x09 { value = value.dropFirst() }
        while let tail = value.last, tail == 0x20 || tail == 0x09 { value = value.dropLast() }
        // Field values are opaque octets. One that is not UTF-8 is read as
        // ISO-8859-1, which maps every byte, so it is forwarded rather than
        // emptied: the proxy never changes a header it has no reason to touch.
        let text = String(bytes: value, encoding: .utf8) ?? String(bytes: value, encoding: .isoLatin1) ?? ""
        return HTTPHeaderField(name: String(bytes: name, encoding: .utf8) ?? "", value: text)
    }

    private static func isTokenByte(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x30...0x39, 0x41...0x5A, 0x61...0x7A: return true
        default: return Array("!#$%&'*+-.^_`|~".utf8).contains(byte)
        }
    }

    private static func chunkSize(_ line: [UInt8]) throws -> Int {
        let sizePart = line.split(separator: 0x3B, maxSplits: 1, omittingEmptySubsequences: false).first ?? []
        let sizeString = String(bytes: sizePart, encoding: .utf8) ?? ""
        let text = sizeString.trimmingCharacters(in: CharacterSet(charactersIn: " \t"))
        guard !text.isEmpty, text.count <= 15, text.allSatisfy(\.isHexDigit), let size = Int(text, radix: 16) else {
            throw RequestRejection.badRequest("chunk size")
        }
        return size
    }
}
#endif
