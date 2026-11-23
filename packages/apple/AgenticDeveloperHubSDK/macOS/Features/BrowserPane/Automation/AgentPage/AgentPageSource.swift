import Foundation
import AgenticDeveloperHubSDKDatabase

/// `AgentPageWalker.js` and the finder it records selectors with, loaded
/// into the automation world (`BrowserScriptWorld.automation`) beside the
/// snapshot runtime whose ref table the walker shares.
public enum AgentPageWalkerRuntime {
    /// Must equal `VERSION` in `AgentPageWalker.js`.
    public static let version = 7

    public static var source: String {
        get throws {
            guard let url = Bundle(for: BrowserAutomationBundleAnchor.self)
                .url(forResource: "AgentPageWalker", withExtension: "js") else {
                throw BrowserAutomationError.runtimeMissing
            }
            return try String(contentsOf: url, encoding: .utf8)
        }
    }

    /// A function body that defines `__adkFinder` and `__adkAgentWalk` on the
    /// world's global object, once per document. Both scripts assign to
    /// `globalThis`, so running them inside a function body (as every engine's
    /// `callAsyncFunction` does) still leaves them defined for the next call.
    @MainActor
    static var installBody: String {
        get throws {
            let finder = try BrowserElementPicker.finderSource
            let walker = try source
            return "if (globalThis.__adkAgentWalkVersion === \(version) "
                + "&& typeof globalThis.__adkAgentWalk === 'function'"
                + " && typeof globalThis.__adkFinder === 'function') { return true; }\n;\n"
                + finder + "\n;\n" + walker + "\n;\nreturn true;"
        }
    }

    /// Installs the snapshot runtime, then the finder and the walker, in the
    /// automation world of `driver`'s current document. Idempotent.
    @MainActor
    public static func install(on driver: BrowserPageDriver) async throws {
        try await driver.installAutomationRuntime()
        _ = try await driver.callAsyncFunction(body: try installBody, arguments: [:], world: .automation)
    }
}

/// One walk's result: the agent's page, and what the tools beside the page
/// need — the generation its refs belong to (absent when the walk failed)
/// and the walk's warnings (agent-list selectors the page could not
/// evaluate). `failure` keeps an automation error the tool should say in its
/// own words (a local file), rather than the page's generic reason.
public struct AgentPageReading: Sendable {
    public let page: AgentPage
    public let generation: Int?
    public let warnings: [String]
    public let failure: BrowserAutomationError?
}

/// The one entry point to the agent's view of a page (the Agent Page Builder
/// recipe, `single-gatekeeper`): walks the page with the site's enabled
/// agent-list selectors excluded and hands the payload to
/// `AgentPageBuilder`, which re-validates and conceals it. Every failure —
/// the walker missing, throwing, outliving its timeout, or returning what
/// does not decode, and the agent list failing to read — is the unavailable
/// page, never partial content. No store (`hiddenItems` nil) is the
/// unavailable page too: at runtime the shared store is nil only when its
/// database could not be opened, and an agent list that cannot be read must
/// not fail open. The excludes are bound to the page actually walked: the
/// walk reports its address, and a page whose agent list differs from the
/// one applied is walked once more with its own, then refused.
@MainActor
public struct AgentPageSource {
    public static let defaultTimeoutMs = 1500

    private let driver: BrowserPageDriver
    private let hiddenItems: (any BrowserHiddenItemsStoring)?
    private let privacy: () -> BrowserAgentPrivacy
    private let hideImages: () -> Bool
    private let timeoutMs: Int

    public init(engine: BrowserEngine, hiddenItems: (any BrowserHiddenItemsStoring)?,
                privacy: @escaping () -> BrowserAgentPrivacy, hideImages: @escaping () -> Bool) {
        self.init(driver: engine, hiddenItems: hiddenItems, privacy: privacy, hideImages: hideImages)
    }

    /// Any page driver (a bare web view's, in tests), and the walk's budget.
    init(driver: BrowserPageDriver, hiddenItems: (any BrowserHiddenItemsStoring)?,
         privacy: @escaping () -> BrowserAgentPrivacy, hideImages: @escaping () -> Bool,
         timeoutMs: Int = AgentPageSource.defaultTimeoutMs) {
        self.driver = driver
        self.hiddenItems = hiddenItems
        self.privacy = privacy
        self.hideImages = hideImages
        self.timeoutMs = timeoutMs
    }

    public func agentPage(options: BrowserSnapshotOptions) async -> AgentPage {
        await read(options: options).page
    }

    /// The depth the snapshot rendering should apply to a page this source
    /// walked: none, since the walk already cut the tree at `options.depth`
    /// DOM levels as the legacy snapshot did (0 or less is unlimited).
    public static func renderingOptions(_ options: BrowserSnapshotOptions) -> BrowserSnapshotOptions {
        var rendering = options
        rendering.depth = nil
        return rendering
    }

    /// `keepingRefs`: a reading walk (text, find, wait_for, the focused
    /// element) that leaves the ref table and generation of the agent's last
    /// snapshot as they are, so the refs it holds stay valid; elements new
    /// since then get fresh refs. A snapshot walks without it.
    public func read(options: BrowserSnapshotOptions, keepingRefs: Bool = false) async -> AgentPageReading {
        let builder = AgentPageBuilder(privacy: privacy(), hideImages: hideImages())
        guard let hiddenItems else { return failed(builder, AgentPageSourceError.agentListUnavailable) }
        var readURL = driver.url
        for _ in 0..<Self.walkAttempts {
            guard BrowserAutomation.isDrivable(readURL?.absoluteString ?? "about:blank") else {
                return failed(builder, BrowserAutomationError.localFile)
            }
            let excludes: [String]
            let json: String
            do {
                excludes = try await agentSelectors(hiddenItems, for: readURL)
                guard let walked = try await walk(builder: builder, excludes: excludes, options: options,
                                                  keepingRefs: keepingRefs) else {
                    return AgentPageReading(page: builder.build(payload: nil, error: nil), generation: nil,
                                            warnings: [], failure: nil)
                }
                json = walked
            } catch {
                return failed(builder, error)
            }
            let data = Data(json.utf8)
            let extras = try? JSONDecoder().decode(WalkExtras.self, from: data)
            // A failure payload carries no address and no content: nothing to bind.
            guard let walkedAddress = extras?.url else { return await reading(builder, data, extras) }
            if walkedAddress == readURL?.absoluteString { return await reading(builder, data, extras) }
            // The page changed between reading the list and walking. The walk
            // stands only if the walked page's own list is the one applied.
            let walkedURL = URL(string: walkedAddress)
            guard BrowserAutomation.isDrivable(walkedURL?.absoluteString ?? "about:blank") else {
                return failed(builder, BrowserAutomationError.localFile)
            }
            do {
                let walkedExcludes = try await agentSelectors(hiddenItems, for: walkedURL)
                if Set(walkedExcludes) == Set(excludes) { return await reading(builder, data, extras) }
            } catch {
                return failed(builder, error)
            }
            readURL = walkedURL
        }
        return failed(builder, AgentPageSourceError.pageChanged)
    }

    /// Two walks: the second covers one navigation between reading the
    /// list and walking; a page still moving after that is refused.
    static let walkAttempts = 2

    private func agentSelectors(_ store: any BrowserHiddenItemsStoring, for url: URL?) async throws -> [String] {
        try await store.enabledSelectors(list: .agent, for: url)
    }

    /// The walker's JSON for the current document, or nil when it returned
    /// something other than a string.
    private func walk(builder: AgentPageBuilder, excludes: [String],
                      options: BrowserSnapshotOptions, keepingRefs: Bool = false) async throws -> String? {
        try await AgentPageWalkerRuntime.install(on: driver)
        let arguments: [String: Any] = [
            "allowlist": try builder.allowlist.jsonString(),
            "excludeSelectors": excludes,
            "scopeRef": options.scope ?? NSNull(),
            "interactiveOnly": options.interactiveOnly,
            "maxDepth": options.depth ?? 0,
            "timeoutMs": timeoutMs,
            "keepRefs": keepingRefs,
            "hideImages": builder.hideImages
        ]
        let raw = try await driver.callAsyncFunction(
            body: "return globalThis.__adkAgentWalk({ allowlist, excludeSelectors, scopeRef, "
                + "interactiveOnly, maxDepth, timeoutMs, keepRefs, hideImages })",
            arguments: arguments, world: .automation)
        return raw as? String
    }

    /// The decode, the tree build and the concealment run off the main
    /// actor: a large page would otherwise cost frames on every read.
    private func reading(_ builder: AgentPageBuilder, _ data: Data, _ extras: WalkExtras?) async -> AgentPageReading {
        let page = await Task.detached(priority: .userInitiated) { builder.build(payload: data, error: nil) }.value
        return AgentPageReading(page: page, generation: page.unavailableReason == nil ? extras?.generation : nil,
                                warnings: extras?.warnings ?? [], failure: nil)
    }

    private func failed(_ builder: AgentPageBuilder, _ error: Error) -> AgentPageReading {
        let automation = error as? BrowserAutomationError
        return AgentPageReading(page: builder.build(payload: nil, error: error), generation: nil, warnings: [],
                                failure: automation ?? .script(error.localizedDescription))
    }

    /// The payload keys the builder does not read.
    private struct WalkExtras: Decodable, Sendable {
        let url: String?
        let generation: Int?
        let warnings: [String]?
    }
}

/// Why `AgentPageSource` withheld a page before or after walking it.
enum AgentPageSourceError: Error, CustomStringConvertible {
    /// No hidden-items store: its database could not be opened.
    case agentListUnavailable
    /// The page kept changing under the walk, so no agent list could be
    /// bound to it.
    case pageChanged

    var description: String {
        switch self {
        case .agentListUnavailable: "the agent's hidden-items list could not be opened."
        case .pageChanged: "the page changed while it was being read."
        }
    }
}

extension AgentPageSourceError: LocalizedError {
    var errorDescription: String? { description }
}

/// What the browser tools read the agent's page through: `AgentPageSource`
/// in the app, a spy in tests (the recipe's `single-gatekeeper` check).
@MainActor
protocol AgentPageReader {
    func read(options: BrowserSnapshotOptions, keepingRefs: Bool) async -> AgentPageReading
}

extension AgentPageSource: AgentPageReader {}

extension AgentPageSource {
    /// The source every reader of a pane's page builds — the browser tools
    /// and the Agent preview and Agent source views alike (`dry`): the
    /// agent list, `privacy` as the read runs under it, and the pane's
    /// effective Hide Images (`WebBrowserPaneViewController.agentHidesImages`,
    /// which the tools receive as `BrowserPaneHandle.hidesImages`). Built
    /// afresh for each read, so each read sees the settings of its moment.
    static func reading(_ driver: BrowserPageDriver, hiddenItems: (any BrowserHiddenItemsStoring)?,
                        privacy: BrowserAgentPrivacy, hideImages: Bool) -> AgentPageSource {
        AgentPageSource(driver: driver, hiddenItems: hiddenItems, privacy: { privacy }, hideImages: { hideImages })
    }

    /// The Hide Images value this source builds under, for tests that pin
    /// the tools and the agent views to one value.
    var hidesImages: Bool { hideImages() }
}
