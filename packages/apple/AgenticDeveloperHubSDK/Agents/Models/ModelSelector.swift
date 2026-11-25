import Foundation

/// How a consumer names the model it wants: by role ("smart"), resolved to the
/// first enabled entry holding it, or by a specific entry with an optional
/// model override.
///
/// Wire JSON is flat: `{"type":"role","role":"smart"}` or
/// `{"type":"config","id":"<uuid>","model":"…"}` (`model` omitted for the
/// entry's default).
public enum ModelSelector: Codable, Sendable, Equatable {
    case role(String)
    case config(id: UUID, model: String?)

    private enum CodingKeys: String, CodingKey {
        case type, role, id, model
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "role":
            self = .role(try container.decode(String.self, forKey: .role))
        case "config":
            self = .config(
                id: try container.decode(UUID.self, forKey: .id),
                model: try container.decodeIfPresent(String.self, forKey: .model))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container, debugDescription: "Unknown model selector type '\(type)'")
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .role(let role):
            try container.encode("role", forKey: .type)
            try container.encode(role, forKey: .role)
        case let .config(id, model):
            try container.encode("config", forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(model, forKey: .model)
        }
    }
}
