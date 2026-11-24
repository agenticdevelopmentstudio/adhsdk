import Foundation

/// The one JSON coding configuration notices use, everywhere.
///
/// HTTP bodies, XPC payloads and the on-disk store must agree on how dates
/// are spelled, or a timestamp read back over the wrong path decodes to the
/// wrong instant — silently, because both spellings are valid JSON.
public enum NoticeCoding {

    public static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    public static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
