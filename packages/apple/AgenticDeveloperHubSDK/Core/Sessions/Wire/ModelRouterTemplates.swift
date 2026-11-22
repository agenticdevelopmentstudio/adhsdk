import Foundation

extension Sessions {

    /// A Claude Code version: 1–4 dot-separated whole numbers, compared numerically,
    /// missing trailing parts read as 0 ("2.1" == "2.1.0").
    public struct ClaudeCodeVersion: Comparable, Hashable, Sendable, CustomStringConvertible {
        public let parts: [Int]
        public let description: String

        public init?(_ text: String) {
            let pieces = text.split(separator: ".", omittingEmptySubsequences: false)
            guard (1...4).contains(pieces.count) else { return nil }
            var parts: [Int] = []
            for piece in pieces {
                guard !piece.isEmpty, piece.allSatisfy(\.isASCII), piece.allSatisfy(\.isNumber),
                      let value = Int(piece) else { return nil }
                parts.append(value)
            }
            self.parts = parts
            self.description = text
        }

        /// The version in `claude-cli/<version>`, up to the first space or "(".
        public static func fromUserAgent(_ userAgent: String?) -> ClaudeCodeVersion? {
            guard let userAgent, let range = userAgent.range(of: "claude-cli/") else { return nil }
            let token = userAgent[range.upperBound...].prefix { $0 != " " && $0 != "(" }
            return ClaudeCodeVersion(String(token))
        }

        private var padded: [Int] { parts + Array(repeating: 0, count: 4 - parts.count) }

        public static func < (lhs: Self, rhs: Self) -> Bool { lhs.padded.lexicographicallyPrecedes(rhs.padded) }
        public static func == (lhs: Self, rhs: Self) -> Bool { lhs.padded == rhs.padded }
        public func hash(into hasher: inout Hasher) { hasher.combine(padded) }
    }

    public enum ModelRouterTemplateDecodeError: Error, Equatable, Sendable {
        case unreadable
        case newerFormat(Int)
        /// This many of a format-2 file's request definitions can't be read.
        case unreadableRequests(Int)
        /// One of a format-3 template's four sections is present but can't be read.
        case unreadableSection(String)

        public var reason: String {
            switch self {
            case .unreadable: return "not a template file"
            case .newerFormat(let format): return "made for a newer Stenographer (format \(format))"
            case .unreadableRequests(let count):
                return "\(count) of its request definitions can't be read, so the file was not imported"
            case .unreadableSection(let section):
                return "its \(section) can't be read, so the file was not imported"
            }
        }
    }

    /// One request template, in four parts: the tiers (smallest first), the
    /// requests it recognizes, which tier each request goes to, and what serves
    /// each tier. It covers a range of Claude Code versions.
    public struct ModelRouterTemplateDTO: Codable, Sendable, Equatable, Identifiable {
        public struct VersionRange: Codable, Sendable, Equatable {
            public var from: String
            public var through: String

            public init(from: String, through: String) {
                self.from = from
                self.through = through
            }
        }

        public static let currentFormat = 3
        public static let builtInPrefix = "builtin."

        public var format: Int
        public var id: String
        public var name: String
        public var claudeCode: VersionRange
        /// Part 1: the tiers, smallest first. The order is the only ranking
        /// routing compares by.
        public var tiers: [ModelTierDTO]
        /// Part 2: the requests, tried in order; the first that matches is the request.
        public var requests: [ModelRequestKindDTO]
        /// Part 3: request id → tier id. `unclassified` names the tier for a request none of `requests` matches.
        public var requestTiers: [String: String]
        /// Part 4: tier id → target, `claude:<haiku|sonnet|opus>` or `provider:<uuid>[/<model>]`.
        public var tierTargets: [String: String]

        public init(
            format: Int = ModelRouterTemplateDTO.currentFormat, id: String, name: String,
            claudeCode: VersionRange, tiers: [ModelTierDTO] = ModelRouterTemplateDTO.defaultTiers,
            requests: [ModelRequestKindDTO], requestTiers: [String: String]? = nil,
            tierTargets: [String: String] = ModelRouterTemplateDTO.defaultTierTargets
        ) {
            self.format = format
            self.id = id
            self.name = name
            self.claudeCode = claudeCode
            self.tiers = tiers
            self.requests = requests
            self.requestTiers = requestTiers ?? Self.defaultRequestTiers(for: requests)
            self.tierTargets = tierTargets
        }

        private enum CodingKeys: String, CodingKey {
            case format, id, name, requests, tiers
            case claudeCode = "claude_code"
            /// The same key after the XPC/HTTP decoder's snake-case conversion has renamed it.
            case convertedClaudeCode = "claudeCode"
            case requestTiers = "request_tiers"
            case convertedRequestTiers = "requestTiers"
            case tierTargets = "tier_targets"
            case convertedTierTargets = "tierTargets"
            /// Format 2's tier for unclassified requests; read, never written.
            case unclassifiedTier = "unclassified_tier"
            case convertedUnclassifiedTier = "unclassifiedTier"
        }

        /// Format 2's request: the definition plus the tier it went to.
        private struct LegacyRequest: Decodable {
            let request: ModelRequestKindDTO
            let tier: String?

            private enum Keys: String, CodingKey { case tier }

            init(from decoder: Decoder) throws {
                request = try ModelRequestKindDTO(from: decoder)
                let tier = try decoder.container(keyedBy: Keys.self).decodeIfPresent(String.self, forKey: .tier)
                // Present but not one of the three tiers drops the element, as format 2 did.
                if let tier, !ModelRouterTemplateDTO.defaultTiers.contains(where: { $0.id == tier }) {
                    throw DecodingError.dataCorruptedError(
                        forKey: .tier, in: try decoder.container(keyedBy: Keys.self), debugDescription: "not a tier")
                }
                self.tier = tier
            }
        }

        /// Format 1 keeps its id, name and range and takes the built-in's four
        /// parts. Format 2 keeps its requests (element by element: a bad one is
        /// dropped, never the template) and splits each one's tier into
        /// `request_tiers`, with the default tiers and each tier served by the
        /// Claude model of its size. Format 3 reads each part; a part that is
        /// missing gets the default, and one that can't be read throws
        /// `.unreadableSection`, never a template short of it.
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let stored = try container.decode(Int.self, forKey: .format)
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            if let range = try container.decodeIfPresent(VersionRange.self, forKey: .claudeCode) {
                claudeCode = range
            } else {
                claudeCode = try container.decode(VersionRange.self, forKey: .convertedClaudeCode)
            }
            format = max(stored, Self.currentFormat)
            switch stored {
            case ..<2:
                tiers = Self.defaultTiers
                requests = Self.builtInRequests
                requestTiers = Self.defaultRequestTiers(for: Self.builtInRequests)
                tierTargets = Self.defaultTierTargets
            case 2:
                tiers = Self.defaultTiers
                tierTargets = Self.defaultTierTargets
                let raw = try? container.decodeIfPresent([LossyDecoded<LegacyRequest>].self, forKey: .requests)
                let legacy = raw.flatMap { $0 }?.compactMap(\.value) ?? []
                requests = legacy.map(\.request)
                var mapped: [String: String] = [:]
                for item in legacy {
                    mapped[item.request.id] = item.tier ?? Self.defaultTierId(forRequest: item.request.id)
                }
                // Absent reads as Heavy; present but not a tier throws.
                let unclassified = try container.decodeIfPresent(String.self, forKey: .unclassifiedTier)
                    ?? container.decodeIfPresent(String.self, forKey: .convertedUnclassifiedTier) ?? "heavy"
                guard Self.defaultTiers.contains(where: { $0.id == unclassified }) else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .unclassifiedTier, in: container, debugDescription: "not a tier")
                }
                mapped[ModelRequestKindDTO.unclassifiedId] = unclassified
                requestTiers = mapped
            default:
                func section<T: Decodable>(_ type: T.Type, _ keys: [CodingKeys], _ title: String) throws -> T? {
                    do {
                        for key in keys {
                            if let value = try container.decodeIfPresent(type, forKey: key) { return value }
                        }
                        return nil
                    } catch {
                        throw ModelRouterTemplateDecodeError.unreadableSection(title)
                    }
                }
                tiers = try section([ModelTierDTO].self, [.tiers], "tiers") ?? Self.defaultTiers
                requests = try section([ModelRequestKindDTO].self, [.requests], "requests") ?? Self.builtInRequests
                requestTiers = try section([String: String].self, [.requestTiers, .convertedRequestTiers],
                                           "request tiers") ?? Self.defaultRequestTiers(for: requests)
                tierTargets = try section([String: String].self, [.tierTargets, .convertedTierTargets],
                                          "tier models") ?? Self.defaultTierTargets
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(format, forKey: .format)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(claudeCode, forKey: .claudeCode)
            try container.encode(tiers, forKey: .tiers)
            try container.encode(requests, forKey: .requests)
            try container.encode(requestTiers, forKey: .requestTiers)
            try container.encode(tierTargets, forKey: .tierTargets)
        }

        public var isBuiltIn: Bool { id.hasPrefix(Self.builtInPrefix) }

        public var versionText: String {
            claudeCode.from == claudeCode.through ? claudeCode.from : "\(claudeCode.from) – \(claudeCode.through)"
        }

        // MARK: - Reading the four parts

        /// The tier `requestId` goes to (`unclassified` for a request nothing
        /// matched): its own entry, else unclassified's.
        public func tierId(forRequest requestId: String) -> String? {
            requestTiers[requestId] ?? requestTiers[ModelRequestKindDTO.unclassifiedId]
        }

        public func tier(_ id: String) -> ModelTierDTO? { tiers.first { $0.id == id } }

        /// Where `id` sits in the ranking, smallest first.
        public func rank(ofTier id: String) -> Int? { tiers.firstIndex { $0.id == id } }

        /// What serves the tier, nil when its target is missing or malformed.
        public func target(forTier id: String) -> ModelTierTarget? { tierTargets[id].flatMap(ModelTierTarget.init) }

        /// The names of everything still sent to `tierId`, requests first and Unclassified last.
        public func names(mappedTo tierId: String) -> [String] {
            var names = requests.filter { requestTiers[$0.id] == tierId }.map(\.name)
            if requestTiers[ModelRequestKindDTO.unclassifiedId] == tierId {
                names.append(ModelRequestKindDTO.unclassifiedName)
            }
            return names
        }

        /// Why `tierId` can't be removed — something still goes to it — or nil.
        public func removalProblem(tierId: String) -> String? {
            let names = names(mappedTo: tierId)
            guard !names.isEmpty else { return nil }
            let tierName = tier(tierId)?.name ?? tierId
            let list = ListFormatter.localizedString(byJoining: names)
            let verb = names.count == 1 ? "goes" : "go"
            let pronoun = names.count == 1 ? "it" : "them"
            return "\(list) still \(verb) to \(tierName). Choose another tier for \(pronoun) first."
        }

        // MARK: - Files

        /// Formats 1 to 3 load (1 and 2 are converted); a higher one is
        /// `.newerFormat`. Unlike stored data, a file is all or nothing: a
        /// format-2 file with any request it can't read is `.unreadableRequests`,
        /// and a format-3 part that can't be read is `.unreadableSection`.
        public static func decodeFile(_ data: Data) -> Result<ModelRouterTemplateDTO, ModelRouterTemplateDecodeError> {
            guard let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                return .failure(.unreadable)
            }
            if let format = object["format"] as? Int, format > currentFormat { return .failure(.newerFormat(format)) }
            let template: ModelRouterTemplateDTO
            do {
                template = try JSONDecoder().decode(ModelRouterTemplateDTO.self, from: data)
            } catch let error as ModelRouterTemplateDecodeError {
                return .failure(error)
            } catch {
                return .failure(.unreadable)
            }
            if let format = object["format"] as? Int, format == 2, let raw = object["requests"] {
                guard let listed = raw as? [Any] else { return .failure(.unreadable) }
                if listed.count > template.requests.count {
                    return .failure(.unreadableRequests(listed.count - template.requests.count))
                }
            }
            return .success(template)
        }

        public func encodedFile() -> Data {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return (try? encoder.encode(self)) ?? Data()
        }

        // MARK: - Defaults

        /// Light, Standard, Heavy: the tiers every template started with.
        public static let defaultTiers: [ModelTierDTO] = [
            ModelTierDTO(id: "light", name: "Light"),
            ModelTierDTO(id: "standard", name: "Standard"),
            ModelTierDTO(id: "heavy", name: "Heavy")
        ]

        /// Each default tier served by the Claude model of its size.
        public static let defaultTierTargets: [String: String] = [
            "light": ModelTierTarget.claude(.haiku).text,
            "standard": ModelTierTarget.claude(.sonnet).text,
            "heavy": ModelTierTarget.claude(.opus).text
        ]

        /// The default tier for a request id: each known kind's own, the
        /// housekeeping and search fallbacks light, command subagents standard,
        /// anything else (and unclassified) heavy.
        public static func defaultTierId(forRequest id: String) -> String {
            if let known = builtInCatalog.first(where: { $0.request.id == id }) { return known.tier.rawValue }
            return "heavy"
        }

        /// Every request, and unclassified, at its default tier.
        public static func defaultRequestTiers(for requests: [ModelRequestKindDTO]) -> [String: String] {
            let unclassified = ModelRequestKindDTO.unclassifiedId
            var mapped = [unclassified: defaultTierId(forRequest: unclassified)]
            for request in requests { mapped[request.id] = defaultTierId(forRequest: request.id) }
            return mapped
        }

        /// A default tier of the built-in template.
        public enum DefaultTier: String, Sendable { case light, standard, heavy }

        private static func known(
            _ id: String, _ name: String, _ thread: ModelThreadKind?, system: String, _ tier: DefaultTier
        ) -> (request: ModelRequestKindDTO, tier: DefaultTier) {
            (ModelRequestKindDTO(
                id: id, name: name, when: ModelRouteConditionsDTO(thread: thread, system: system)), tier)
        }

        private static func known(
            _ id: String, _ name: String, _ thread: ModelThreadKind?, message: String, _ tier: DefaultTier
        ) -> (request: ModelRequestKindDTO, tier: DefaultTier) {
            (ModelRequestKindDTO(
                id: id, name: name, when: ModelRouteConditionsDTO(thread: thread, message: message)), tier)
        }

        /// The requests Claude Code 2.1.302 sends, read from its own prompts, each
        /// recognized by a sentence of the instructions it writes for that request
        /// (or of the last message, for a request that reuses your conversation's
        /// instructions). Tried in order, so the three fallbacks come last: any
        /// other request with no tools, any other subagent that can't run commands,
        /// and any other subagent that can.
        public static let builtInCatalog: [(request: ModelRequestKindDTO, tier: DefaultTier)] = [
            known("explore-subagent", "Explore subagent", .subagent, system:
                  "You are a file search specialist for Claude Code, Anthropic's official CLI", .light),
            known("plan-subagent", "Plan subagent", .subagent, system:
                  "You are a software architect and planning specialist for Claude Code.", .heavy),
            known("general-purpose-subagent", "General-purpose subagent", .subagent, system:
                  "You are an agent for Claude Code, Anthropic's official CLI for Claude. Given", .standard),
            known("statusline-setup-subagent", "Status line setup subagent", .subagent, system:
                  "You are a status line setup agent for Claude Code.", .standard),
            known("claude-code-guide-subagent", "Claude Code guide subagent", .subagent, system:
                  "You are the Claude guide agent. Your primary responsibility is helping users", .light),
            known("web-reading-subagent", "Web reading subagent", .subagent, system:
                  "You are a web-reading specialist for Claude Code, Anthropic's official CLI", .light),
            known("teammate-agent", "Agent team teammate", .subagent, system:
                  "You are a teammate in this session's agent team.", .heavy),
            known("workflow-subagent", "Workflow script subagent", .subagent, system:
                  "You are a subagent spawned by a workflow orchestration script.", .standard),
            known("hook-agent-verifier", "Hook agent verifier", .subagent, system:
                  "You are verifying a stop condition in Claude Code.", .standard),
            known("hook-agent-evaluator", "Hook agent evaluator", .subagent, system:
                  "Your task is to evaluate the condition described in the user message.", .standard),
            known("comment-thread-analyst-subagent", "Comment analyst subagent", .subagent, message:
                  "Follow your workflow and output the analysis brief.", .standard),
            known("worker-fork", "Worker fork subagent", .subagent, message:
                  "You are a worker fork. The transcript above is the parent's history", .heavy),
            known("observer-paired", "Background observer (paired agent)", .side, system:
                  "You are a background observer paired with the agent", .standard),
            known("observer-worker", "Background observer (worker)", .side, system:
                  "You are a background observer of the worker", .standard),
            known("helpful-observer", "\"You should know\" observer", .side, system:
                  "You are a helpful observer whose goal is to help the human better understand", .standard),
            known("compaction-system", "Compaction", .side, system:
                  "You are a helpful AI assistant tasked with summarizing conversations.", .heavy),
            known("session-title", "Session title", .side, system:
                  "You are naming a coding session so the user can pick it out of a long list", .light),
            known("tool-use-summary", "Tool use summary label", .side, system:
                  "Write a short summary label describing what these tool calls accomplished.", .light),
            known("web-search-tool", "Web search tool", .side, system:
                  "You run a web search for another Claude model, which is waiting on the result", .light),
            known("hook-prompt-evaluator", "Hook prompt evaluator", .side, system:
                  "You are evaluating a hook in Claude Code. The user's text says what to check.", .standard),
            known("hook-stop-condition", "Stop-condition hook evaluator", .side, system:
                  "You are evaluating a stop-condition hook in Claude Code.", .standard),
            known("auto-mode-classifier", "Auto mode permission classifier", .side, system:
                  "You are a security monitor for autonomous AI coding agents.", .heavy),
            known("auto-mode-critique", "Auto mode rules critique", .side, system:
                  "You are an expert reviewer of auto mode classifier rules for Claude Code.", .standard),
            known("subagent-config-classifier", "Subagent config classifier", .side, system:
                  "You read a Claude Code user's own configuration (their CLAUDE.md instructions", .standard),
            known("agent-summary", "Background agent progress label", .side, system:
                  "You write a 3-5 word progress label for a background agent", .light),
            known("feedback-issue-title", "Bug report issue title", .side, system:
                  "Generate a concise, technical issue title (max 80 chars) for a public", .light),
            known("artifact-comment-triage", "Artifact comment triage", .side, system:
                  "You classify artifact comment threads for dispatch.", .light),
            known("artifact-comment-fast-ack", "Artifact comment acknowledgement", .side, system:
                  "You write one short acknowledgement sentence for an artifact comment thread.", .light),
            known("artifact-comment-reply", "Artifact comment reply", .side, system:
                  "You write single comment replies on artifact comment threads.", .standard),
            known("compaction-message", "Compaction (instruction)", .side, message:
                  "Your task is to create a detailed summary of the conversation so far", .heavy),
            known("side-question", "Side question (/btw)", .side, message:
                  "This is a side question from the user. You must answer this question directly", .standard),
            known("away-summary", "Away recap", .side, message:
                  "The user stepped away and is coming back. Recap in under 40 words", .light),
            known("prompt-suggestion", "Prompt suggestion", .side, message:
                  "[SUGGESTION MODE: Suggest what the user might naturally type next into", .light),
            known("rename-session-name", "Session rename (/rename)", .side, message:
                  "Generate a short kebab-case name (2-4 words) that captures the main topic", .light),
            known("teleport-title", "Teleport title and branch", .side, message:
                  "Please generate a title and branch name for this session", .light),
            known("web-fetch-apply", "Web fetch summarizer", .side, message:
                  "Provide a concise response based only on the content above", .light),
            known("extract-memories", "Memory extraction", .side, message:
                  "You are now acting as the memory extraction subagent.", .standard),
            known("auto-dream", "Memory consolidation (dream)", .side, message:
                  "You are performing a dream", .standard),
            known("agent-namer", "Background job label", .side, message:
                  "2-4 word lowercase label for this job.", .light),
            known("insights-facets", "Insights session facets", .side, message:
                  "Analyze this Claude Code session and extract structured facets.", .light),
            known("insights-summary", "Insights transcript chunk summary", .side, message:
                  "Summarize this portion of a Claude Code session transcript.", .light),
            (ModelRequestKindDTO(
                id: "background", name: "Background task", when: ModelRouteConditionsDTO(thread: .side)),
             .light),
            (ModelRequestKindDTO(
                id: "search-subagent", name: "Search subagent",
                when: ModelRouteConditionsDTO(thread: .subagent, commands: false)), .light),
            (ModelRequestKindDTO(
                id: "command-subagent", name: "Command subagent",
                when: ModelRouteConditionsDTO(thread: .subagent, commands: true)), .standard)
        ]

        /// The request definitions of the built-in template, tried in order.
        public static let builtInRequests: [ModelRequestKindDTO] = builtInCatalog.map(\.request)

        public static let builtIns: [ModelRouterTemplateDTO] = [
            ModelRouterTemplateDTO(
                id: "builtin.claude-code.2.1.296", name: "Claude Code 2.1.296",
                claudeCode: VersionRange(from: "2.1.296", through: "2.1.296"), requests: builtInRequests)
        ]
    }

    public enum ModelRouterTemplateValidation {
        public static let nameMissing = "A template needs a name."
        public static let nameTaken = "Another template already has that name."
        public static let maxNameLength = 80
        public static let nameTooLong = "A template name can be at most 80 characters."
        public static let nameHasControls =
            "A template name can't hold control characters, text-direction controls or line breaks."
        public static let badId = "A template id is letters, digits, dots, dashes or underscores."
        public static let badVersion = "A Claude Code version is whole numbers separated by dots, like 2.1.296."
        public static let backwardsRange = "The first Claude Code version must not be after the last."
        public static let builtInReadOnly = "Built-in templates can't be changed; duplicate one instead."
        public static let noSuchTemplate = "That template no longer exists."
        public static let badRequestId =
            "A request id is lowercase letters, digits and dashes, and can't be unclassified."
        public static let duplicateRequestId = "Two requests have the same id."
        public static let requestNameMissing = "Every request needs a name."
        public static let requestNameTaken = "Two requests have the same name."
        public static let requestNameBad =
            "A request name can be at most 80 characters, with no control characters or line breaks."
        public static let maxMatchTextLength = 400
        public static let matchTextBad =
            "The text a request is recognized by can be at most 400 characters, with no control characters."
        public static let noTiers = "A template needs at least one tier."
        public static let badTierId = "A tier id is lowercase letters, digits and dashes."
        public static let duplicateTierId = "Two tiers have the same id."
        public static let tierNameMissing = "Every tier needs a name."
        public static let tierNameTaken = "Two tiers have the same name."
        public static let tierNameBad =
            "A tier name can be at most 80 characters, with no control characters or line breaks."
        public static let requestTierMissing = "Every request, and Unclassified, needs a tier."
        public static let requestTierUnknown = "A request goes to a tier the template doesn't have."
        public static let requestTierStray = "The request tiers name a request the template doesn't have."
        public static let tierTargetMissing = "Every tier needs a model."
        public static let tierTargetBad = "A tier's model must be a Claude model or an LLM Provider configuration."
        public static let tierTargetStray = "The tier models name a tier the template doesn't have."

        /// A denylist, so emoji (variation selectors, ZWJ sequences) and accents
        /// typed as combining marks stay allowed: only control characters (Cc),
        /// the bidi controls (U+200E, U+200F, U+202A–U+202E, U+2066–U+2069) and
        /// line and paragraph separators (Zl, Zp) are refused.
        public static func isRefusedInName(_ scalar: Unicode.Scalar) -> Bool {
            switch scalar.value {
            case 0x200E, 0x200F, 0x202A...0x202E, 0x2066...0x2069: return true
            default: break
            }
            switch scalar.properties.generalCategory {
            case .control, .lineSeparator, .paragraphSeparator: return true
            default: return false
            }
        }

        public static func problem(_ template: ModelRouterTemplateDTO, others: [ModelRouterTemplateDTO]) -> String? {
            let name = template.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty { return nameMissing }
            // The name is printed raw by `steno router` and copied into every
            // routing-log row, so nothing may drive a terminal, reorder the text
            // around it, break a line or bloat a row.
            if template.name.unicodeScalars.contains(where: isRefusedInName) { return nameHasControls }
            if template.name.count > maxNameLength { return nameTooLong }
            if others.contains(where: {
                $0.id != template.id && $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    .caseInsensitiveCompare(name) == .orderedSame
            }) { return nameTaken }
            guard let from = ClaudeCodeVersion(template.claudeCode.from),
                  let through = ClaudeCodeVersion(template.claudeCode.through)
            else { return badVersion }
            if through < from { return backwardsRange }
            return tiersProblem(template.tiers) ?? requestsProblem(template.requests) ?? mappingProblem(template)
        }

        /// Tier names land in the routing log the same way request names do.
        private static func tiersProblem(_ tiers: [ModelTierDTO]) -> String? {
            guard !tiers.isEmpty else { return noTiers }
            var ids = Set<String>()
            var names = Set<String>()
            for tier in tiers {
                guard ModelRequestKindDTO.isValidId(tier.id) else { return badTierId }
                guard ids.insert(tier.id).inserted else { return duplicateTierId }
                let name = tier.name.trimmingCharacters(in: .whitespacesAndNewlines)
                if name.isEmpty { return tierNameMissing }
                if tier.name.unicodeScalars.contains(where: isRefusedInName) || tier.name.count > maxNameLength {
                    return tierNameBad
                }
                guard names.insert(name.lowercased()).inserted else { return tierNameTaken }
            }
            return nil
        }

        /// Request names land in the routing log the same way template names do.
        private static func requestsProblem(_ requests: [ModelRequestKindDTO]) -> String? {
            var ids = Set<String>()
            var names = Set<String>()
            for request in requests {
                guard ModelRequestKindDTO.isValidId(request.id) else { return badRequestId }
                guard ids.insert(request.id).inserted else { return duplicateRequestId }
                let name = request.name.trimmingCharacters(in: .whitespacesAndNewlines)
                if name.isEmpty { return requestNameMissing }
                if request.name.unicodeScalars.contains(where: isRefusedInName) || request.name.count > maxNameLength {
                    return requestNameBad
                }
                guard names.insert(name.lowercased()).inserted else { return requestNameTaken }
                for text in [request.when.system, request.when.message].compactMap({ $0 })
                where !isValidMatchText(text) { return matchTextBad }
            }
            return nil
        }

        /// The text a request is recognized by: at most `maxMatchTextLength`, no control characters.
        public static func isValidMatchText(_ text: String) -> Bool {
            text.count <= maxMatchTextLength && !text.unicodeScalars.contains(where: isRefusedInName)
        }

        /// Every request and Unclassified go to a tier the template has, and every tier has a valid model.
        private static func mappingProblem(_ template: ModelRouterTemplateDTO) -> String? {
            let tierIds = Set(template.tiers.map(\.id))
            let requestIds = Set(template.requests.map(\.id)).union([ModelRequestKindDTO.unclassifiedId])
            for id in requestIds.sorted() {
                guard let tier = template.requestTiers[id] else { return requestTierMissing }
                guard tierIds.contains(tier) else { return requestTierUnknown }
            }
            if !Set(template.requestTiers.keys).isSubset(of: requestIds) { return requestTierStray }
            for tier in template.tiers {
                guard let text = template.tierTargets[tier.id] else { return tierTargetMissing }
                guard ModelTierTarget(text) != nil else { return tierTargetBad }
            }
            if !Set(template.tierTargets.keys).isSubset(of: tierIds) { return tierTargetStray }
            return nil
        }
    }

    public enum ModelRouterTemplateSelector {
        public struct Selection: Equatable, Sendable {
            public let template: ModelRouterTemplateDTO
            public let isFallback: Bool

            public init(template: ModelRouterTemplateDTO, isFallback: Bool) {
                self.template = template
                self.isFallback = isFallback
            }
        }

        private static func range(_ template: ModelRouterTemplateDTO) -> (ClaudeCodeVersion, ClaudeCodeVersion)? {
            guard let from = ClaudeCodeVersion(template.claudeCode.from),
                  let through = ClaudeCodeVersion(template.claudeCode.through)
            else { return nil }
            return (from, through)
        }

        /// The template whose range covers `version`; failing that, the one reaching the latest version.
        public static func select(
            _ templates: [ModelRouterTemplateDTO], preferred: Set<String>, version: ClaudeCodeVersion?
        ) -> Selection? {
            func before(_ lhs: ModelRouterTemplateDTO, _ rhs: ModelRouterTemplateDTO) -> Bool {
                let lhsPreferred = preferred.contains(lhs.id), rhsPreferred = preferred.contains(rhs.id)
                if lhsPreferred != rhsPreferred { return lhsPreferred }
                if lhs.isBuiltIn != rhs.isBuiltIn { return lhs.isBuiltIn }
                let order = lhs.name.caseInsensitiveCompare(rhs.name)
                if order != .orderedSame { return order == .orderedAscending }
                return lhs.id < rhs.id
            }
            if let version {
                let covered = templates.filter {
                    guard let (from, through) = range($0) else { return false }
                    return from <= version && version <= through
                }
                if let pick = covered.min(by: before) { return Selection(template: pick, isFallback: false) }
            }
            let ranged = templates.compactMap { item in range(item).map { (item, $0.1) } }
            guard let latest = ranged.map(\.1).max() else { return nil }
            let pick = ranged.filter { $0.1 == latest }.map(\.0).min(by: before)
            return pick.map { Selection(template: $0, isFallback: true) }
        }

        public static func overlaps(_ lhs: ModelRouterTemplateDTO, _ rhs: ModelRouterTemplateDTO) -> Bool {
            guard let (lhsFrom, lhsThrough) = range(lhs), let (rhsFrom, rhsThrough) = range(rhs) else { return false }
            return lhsFrom <= rhsThrough && rhsFrom <= lhsThrough
        }
    }
}
