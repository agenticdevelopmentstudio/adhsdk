import Foundation

/// The one JSON dialect the agents framework stores and serves: ISO-8601 dates
/// and sorted keys, so a stored row, an HTTP body and a test fixture read the
/// same. Public so a client of the HTTP surface (a CLI) decodes it the same
/// way. Each call returns a fresh coder, because `JSONEncoder` and
/// `JSONDecoder` are not `Sendable`.
public enum AgentsJSON {

    public static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    public static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    public static func encode<Value: Encodable>(_ value: Value) throws -> Data {
        try encoder().encode(value)
    }

    public static func encodeString<Value: Encodable>(_ value: Value) throws -> String {
        String(bytes: try encode(value), encoding: .utf8) ?? ""
    }

    public static func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
        try decoder().decode(type, from: data)
    }

    public static func decode<Value: Decodable>(_ type: Value.Type, from string: String) throws -> Value {
        try decode(type, from: Data(string.utf8))
    }
}
