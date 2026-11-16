import Foundation

/// `AgentPageWalker.js` and the finder it records selectors with, loaded
/// into the automation world (`BrowserScriptWorld.automation`) beside the
/// snapshot runtime whose ref table the walker shares.
public enum AgentPageWalkerRuntime {
    /// Must equal `VERSION` in `AgentPageWalker.js`.
    public static let version = 2

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
/// page, never partial content. No store (`hiddenItems` nil) is no
/// exclusions, as an empty list is (recipe edge case "Missing file").
@MainActor
public struct AgentPageSource {
    public static let defaultTimeoutMs = 1500

    private let driver: BrowserPageDriver
    private let hiddenItems: BrowserHiddenItemsStore?
    private let privacy: () -> BrowserAgentPrivacy
    private let hideImages: () -> Bool
    private let timeoutMs: Int

    public init(engine: BrowserEngine, hiddenItems: BrowserHiddenItemsStore?,
                privacy: @escaping () -> BrowserAgentPrivacy, hideImages: @escaping () -> Bool) {
        self.init(driver: engine, hiddenItems: hiddenItems, privacy: privacy, hideImages: hideImages)
    }

    /// Any page driver (a bare web view's, in tests), and the walk's budget.
    init(driver: BrowserPageDriver, hiddenItems: BrowserHiddenItemsStore?,
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

    public func read(options: BrowserSnapshotOptions) async -> AgentPageReading {
        let builder = AgentPageBuilder(privacy: privacy(), hideImages: hideImages())
        let url = driver.url
        guard BrowserAutomation.isDrivable(url?.absoluteString ?? "about:blank") else {
            return failed(builder, BrowserAutomationError.localFile)
        }

        var excludes: [String] = []
        if let hiddenItems {
            do {
                excludes = try await hiddenItems.perform { try $0.enabledSelectors(list: .agent, for: url) }
            } catch {
                // A list that exists but cannot be read must not fail open.
                return failed(builder, error)
            }
        }

        let raw: Any?
        do {
            try await AgentPageWalkerRuntime.install(on: driver)
            let arguments: [String: Any] = [
                "allowlist": try builder.allowlist.jsonString(),
                "excludeSelectors": excludes,
                "scopeRef": options.scope ?? NSNull(),
                "interactiveOnly": options.interactiveOnly,
                "maxDepth": options.depth ?? 0,
                "timeoutMs": timeoutMs
            ]
            raw = try await driver.callAsyncFunction(
                body: "return globalThis.__adkAgentWalk({ allowlist, excludeSelectors, scopeRef, "
                    + "interactiveOnly, maxDepth, timeoutMs })",
                arguments: arguments, world: .automation)
        } catch {
            return failed(builder, error)
        }
        guard let json = raw as? String else {
            return AgentPageReading(page: builder.build(payload: nil, error: nil), generation: nil,
                                    warnings: [], failure: nil)
        }
        let data = Data(json.utf8)
        let page = builder.build(payload: data, error: nil)
        let extras = try? JSONDecoder().decode(WalkExtras.self, from: data)
        return AgentPageReading(page: page, generation: page.unavailableReason == nil ? extras?.generation : nil,
                                warnings: extras?.warnings ?? [], failure: nil)
    }

    private func failed(_ builder: AgentPageBuilder, _ error: Error) -> AgentPageReading {
        let automation = error as? BrowserAutomationError
        return AgentPageReading(page: builder.build(payload: nil, error: error), generation: nil, warnings: [],
                                failure: automation ?? .script(error.localizedDescription))
    }

    /// The payload keys the builder does not read.
    private struct WalkExtras: Decodable {
        let generation: Int?
        let warnings: [String]?
    }
}
