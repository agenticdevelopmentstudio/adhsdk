import Foundation

/// One model a provider serves, as its model source reports it.
///
/// `family` and `releaseDate` are what make "the latest version" answerable:
/// `claude-opus-5-5` and `claude-opus-4-8` are one family, and the newer release
/// supersedes the older. A source that can't say (a bare OpenAI-style `/models`
/// listing, a descriptor's static list) leaves both nil, and such a model is
/// never treated as superseded.
public struct ProviderModel: Codable, Sendable, Equatable {
    public let id: String
    public let displayName: String?
    public let family: String?
    /// `yyyy-MM-dd`, so release dates order as strings.
    public let releaseDate: String?

    public init(id: String, displayName: String? = nil, family: String? = nil,
                releaseDate: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.family = family
        self.releaseDate = releaseDate
    }

    /// True for a pinned snapshot id (`claude-haiku-4-5-20251001`): the same model
    /// as its undated alias, which is the one to offer.
    public var isDatedSnapshot: Bool {
        id.range(of: #"-\d{8}$"#, options: .regularExpression) != nil
    }
}

/// Every model a provider serves, and the latest version of each model family.
///
/// The list is ordered newest release first when the source gives dates, so the
/// models a person most likely wants lead it; undated models keep the source's
/// order after them.
public struct ProviderModelList: Codable, Sendable, Equatable {
    public let models: [ProviderModel]

    public init(models: [ProviderModel]) {
        // Stable sort: newest release first, undated entries after in source order.
        self.models = models.enumerated().sorted { lhs, rhs in
            switch (lhs.element.releaseDate, rhs.element.releaseDate) {
            case let (left?, right?) where left != right: return left > right
            case (.some, nil): return true
            case (nil, .some): return false
            default: return lhs.offset < rhs.offset
            }
        }.map(\.element)
    }

    /// A list with nothing known beyond the names: every model is current.
    public init(ids: [String]) {
        self.init(models: ids.map { ProviderModel(id: $0) })
    }

    public var isEmpty: Bool { models.isEmpty }

    /// Every model id, newest first.
    public var allIDs: [String] { models.map(\.id) }

    /// The newest model of each family, plus every model whose family is unknown.
    ///
    /// Within a family the newest release date wins. Without dates (a seed list,
    /// or a source that gives none) the higher version in the id wins, so
    /// `claude-sonnet-4-5` beats `claude-3-5-sonnet` whatever order they came in.
    /// On a full tie (an alias and its dated snapshot) the undated alias wins,
    /// because it is the name a person would type and it tracks the snapshot.
    public var latestIDs: [String] {
        var newest: [String: ProviderModel] = [:]
        for model in models {
            guard let family = model.family else { continue }
            guard let current = newest[family] else { newest[family] = model; continue }
            if Self.isNewer(model, than: current) { newest[family] = model }
        }
        let keep = Set(newest.values.map(\.id))
        return models.filter { $0.family == nil || keep.contains($0.id) }.map(\.id)
    }

    /// True when the list holds superseded versions to hide.
    public var hasOlderVersions: Bool { latestIDs.count < models.count }

    private static func isNewer(_ model: ProviderModel, than current: ProviderModel) -> Bool {
        let left = model.releaseDate ?? "", right = current.releaseDate ?? ""
        if left != right { return left > right }
        let newVersion = version(of: model.id), currentVersion = version(of: current.id)
        if newVersion != currentVersion { return currentVersion.lexicographicallyPrecedes(newVersion) }
        return current.isDatedSnapshot && !model.isDatedSnapshot
    }

    /// The version numbers in an id, in order — `claude-3-5-sonnet-20241022` →
    /// `[3, 5]`, `claude-opus-5-5` → `[5, 5]`. Runs of eight or more digits are
    /// snapshot dates, not versions, and are left out.
    static func version(of id: String) -> [Int] {
        id.split { !$0.isNumber }.compactMap { $0.count < 8 ? Int($0) : nil }
    }
}

/// The family of an Anthropic model id, for sources (the Anthropic API) that
/// report ids without one.
///
/// Two naming eras: `claude-opus-5-5` / `claude-haiku-4-5-20251001` (name before
/// version) and `claude-3-5-sonnet-20241022` (version before name). Both resolve
/// to `claude-<name>`, the spelling models.dev uses, so the two sources agree.
public enum AnthropicModelFamily {
    public static func family(of id: String) -> String? {
        let lower = id.lowercased()
        for pattern in [#"^claude-([a-z]+)-\d"#, #"^claude-\d+(?:-\d+)?-([a-z]+)"#] {
            if let name = firstCapture(pattern, in: lower) { return "claude-\(name)" }
        }
        return nil
    }

    /// The family a bare alias names — `opus` → `claude-opus` — or nil when `id`
    /// is not one. The Claude CLI takes these and runs the newest of the family.
    public static func aliasFamily(of id: String) -> String? {
        let lower = id.trimmingCharacters(in: .whitespaces).lowercased()
        guard lower.range(of: #"^[a-z]+$"#, options: .regularExpression) != nil,
              lower != "claude" else { return nil }
        return "claude-\(lower)"
    }

    /// The name a person reads: `claude-opus-5-5` → `Opus 5.5`,
    /// `claude-3-5-sonnet-20241022` → `Sonnet 3.5 (2024-10-22)`, `opus` → `Opus`.
    /// Nil for an id in neither naming era.
    public static func displayName(of id: String) -> String? {
        let lower = id.trimmingCharacters(in: .whitespaces).lowercased()
        if aliasFamily(of: lower) != nil { return lower.capitalized }
        // name, major, minor, date — or major, minor, name, date for the old era.
        if let parts = captures(#"^claude-([a-z]+)-(\d+)(?:-(\d{1,2}))?(?:-(\d{8}))?$"#, in: lower) {
            return format(name: parts[0], major: parts[1], minor: parts[2], date: parts[3])
        }
        if let parts = captures(#"^claude-(\d+)(?:-(\d{1,2}))?-([a-z]+)(?:-(\d{8}))?$"#, in: lower) {
            return format(name: parts[2], major: parts[0], minor: parts[1], date: parts[3])
        }
        return nil
    }

    private static func format(name: String?, major: String?, minor: String?, date: String?) -> String? {
        guard let name, let major else { return nil }
        var text = name.capitalized + " " + major
        if let minor { text += "." + minor }
        if let date, date.count == 8 {
            let chars = Array(date)
            text += " (\(String(chars[0..<4]))-\(String(chars[4..<6]))-\(String(chars[6..<8])))"
        }
        return text
    }

    private static func firstCapture(_ pattern: String, in text: String) -> String? {
        captures(pattern, in: text)?.first ?? nil
    }

    /// Every capture group of `pattern`'s first match (nil for a group that did
    /// not participate), or nil when nothing matches.
    private static func captures(_ pattern: String, in text: String) -> [String?]? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
        else { return nil }
        return (1..<match.numberOfRanges).map { index in
            Range(match.range(at: index), in: text).map { String(text[$0]) }
        }
    }
}
