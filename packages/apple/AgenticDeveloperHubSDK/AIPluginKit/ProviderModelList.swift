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
    /// Within a family the newest release date wins; on a tie (an alias and its
    /// dated snapshot share a date) the undated alias wins, because it is the name
    /// a person would type and it tracks the snapshot.
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
        return current.isDatedSnapshot && !model.isDatedSnapshot
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

    private static func firstCapture(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }
}
