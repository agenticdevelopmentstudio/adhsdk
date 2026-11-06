import Foundation

public extension Notice {

    private enum CodingKeys: String, CodingKey {
        case id, timestamp, source, title, subtitle, body, details, app, level, urgency, category
        case metadata, actions, expiresAt, ttl, key, state, stateAt, snoozedUntil, response
    }

    /// Lenient on the way in, exact on the way out. A client posting
    /// `{"source":"ci","title":"Build failed"}` gets an id, a timestamp,
    /// `.info` and `.fyi` for free; `source` and `title` have no sensible
    /// default, so a request missing either fails at the boundary rather than
    /// storing a nameless notice. An unknown `urgency` or a malformed action
    /// fails too, rather than silently becoming something else.
    ///
    /// `details` is accepted when `body` is absent. `ttl` (seconds) is
    /// resolved against `timestamp` unless `expiresAt` is given.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        let actions = try container.decodeIfPresent([Action].self, forKey: .actions) ?? []
        var seen = Set<String>()
        for action in actions where !seen.insert(action.id).inserted {
            throw NoticeDecodingError.duplicateActionID(action.id)
        }
        var expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        if expiresAt == nil, let ttl = try container.decodeIfPresent(Double.self, forKey: .ttl) {
            expiresAt = timestamp.addingTimeInterval(ttl)
        }
        let body = try container.decodeIfPresent(String.self, forKey: .body)
            ?? container.decodeIfPresent(String.self, forKey: .details)
        self.init(
            id: try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString,
            timestamp: timestamp,
            source: try container.decode(String.self, forKey: .source),
            title: try container.decode(String.self, forKey: .title),
            subtitle: try container.decodeIfPresent(String.self, forKey: .subtitle),
            body: body,
            app: try container.decodeIfPresent(String.self, forKey: .app),
            level: try container.decodeIfPresent(Level.self, forKey: .level) ?? .info,
            urgency: try container.decodeIfPresent(Urgency.self, forKey: .urgency) ?? .fyi,
            category: try container.decodeIfPresent(String.self, forKey: .category),
            metadata: try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:],
            actions: actions,
            expiresAt: expiresAt,
            key: try container.decodeIfPresent(String.self, forKey: .key),
            state: try container.decodeIfPresent(Lifecycle.self, forKey: .state) ?? .unread,
            stateAt: try container.decodeIfPresent(Date.self, forKey: .stateAt),
            snoozedUntil: try container.decodeIfPresent(Date.self, forKey: .snoozedUntil),
            response: try container.decodeIfPresent(NoticeResponse.self, forKey: .response)
        )
    }

    /// Encodes `body` (never `details`) and `expiresAt` (never `ttl`).
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(source, forKey: .source)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encodeIfPresent(body, forKey: .body)
        try container.encodeIfPresent(app, forKey: .app)
        try container.encode(level, forKey: .level)
        try container.encode(urgency, forKey: .urgency)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encode(metadata, forKey: .metadata)
        try container.encode(actions, forKey: .actions)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try container.encodeIfPresent(key, forKey: .key)
        try container.encode(state, forKey: .state)
        try container.encodeIfPresent(stateAt, forKey: .stateAt)
        try container.encodeIfPresent(snoozedUntil, forKey: .snoozedUntil)
        try container.encodeIfPresent(response, forKey: .response)
    }
}
