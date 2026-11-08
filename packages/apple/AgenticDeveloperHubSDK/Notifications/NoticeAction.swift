import Foundation

/// Thrown by `Notice.init(from:)` when the actions are not usable. Callers
/// map it to a 400 rather than storing a notice with a dead button.
public enum NoticeDecodingError: Error, Equatable {
    /// The action with this id has a `url` that is not an absolute URL.
    case malformedAction(String)
    /// The action with this id opens a scheme on `Notice.Action.refusedURLSchemes`.
    case refusedURL(String)
    /// Two actions share this id.
    case duplicateActionID(String)
}

public extension Notice {

    /// One thing the user can do about a notice. Never a script path: it
    /// either opens a URL or reports back to the poster as a callback.
    struct Action: Codable, Sendable, Equatable {

        public enum Kind: Sendable, Equatable {
            /// Open this URL.
            case open(URL)
            /// Tell the poster the user chose this action.
            case callback
            /// Ask the user for text, then tell the poster.
            case reply(placeholder: String?)
        }

        /// Unique within the notice.
        public var id: String
        public var label: String
        public var kind: Kind

        public init(id: String, label: String, kind: Kind) {
            self.id = id
            self.label = label
            self.kind = kind
        }

        /// Schemes an open action may never use, compared without case. Any
        /// local process can post a notice, so its button must not become a
        /// way to open a file or app on disk (`file`), mount or browse a
        /// share (`afp`, `smb`, `cifs`, `nfs`, `ftp`, `ftps`, `webdav`,
        /// `webdavs`), or run inline content (`data`, `javascript`,
        /// `vbscript`, `blob`). A denylist rather than an allowlist, because
        /// an app's own deep link (`slack://`, `x-github-client://`) is the
        /// point of the feature.
        public static let refusedURLSchemes: Set<String> = [
            "file", "afp", "smb", "cifs", "nfs", "ftp", "ftps", "webdav", "webdavs",
            "data", "javascript", "vbscript", "blob"
        ]

        /// True when `url` has a scheme and it is not refused.
        public static func isOpenable(_ url: URL) -> Bool {
            guard let scheme = url.scheme?.lowercased(), !scheme.isEmpty else { return false }
            return !refusedURLSchemes.contains(scheme)
        }

        private enum CodingKeys: String, CodingKey {
            case id, label, url, reply, placeholder
        }

        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let id = try container.decode(String.self, forKey: .id)
            self.id = id
            self.label = try container.decode(String.self, forKey: .label)
            if let raw = try container.decodeIfPresent(String.self, forKey: .url) {
                guard let url = URL(string: raw), url.scheme?.isEmpty == false else {
                    throw NoticeDecodingError.malformedAction(id)
                }
                guard Self.isOpenable(url) else { throw NoticeDecodingError.refusedURL(id) }
                self.kind = .open(url)
            } else if try container.decodeIfPresent(Bool.self, forKey: .reply) == true {
                self.kind = .reply(placeholder: try container.decodeIfPresent(String.self, forKey: .placeholder))
            } else {
                self.kind = .callback
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(label, forKey: .label)
            switch kind {
            case .open(let url):
                try container.encode(url.absoluteString, forKey: .url)
            case .callback:
                break
            case .reply(let placeholder):
                try container.encode(true, forKey: .reply)
                try container.encodeIfPresent(placeholder, forKey: .placeholder)
            }
        }
    }
}
