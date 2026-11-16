import AppKit
import Foundation
import OSLog
import WebKit

/// One message from the picker script: a `pick` with its candidate selectors,
/// or a `cancel` (Esc pressed in the page). Recipe
/// `workspace/browser/element-picker`.
public struct BrowserPickCandidate: Decodable, Sendable, Equatable {
    public enum Kind: String, Decodable, Sendable {
        case pick
        case cancel
    }

    public var kind: Kind
    /// Finder's shortest unique selector; `nil` when none could be computed
    /// (shadow roots, SVG `use`, frames), which refuses the pick.
    public var thisItem: String?
    /// The tag and stable class names; `nil` when it would be the same as
    /// `thisItem` or could not be computed.
    public var allLikeIt: String?
    /// How many elements `allLikeIt` matches.
    public var allLikeItCount: Int
    /// How many elements the page has.
    public var pageElementCount: Int
    /// The lowercase tag and up to 60 characters of text, e.g. `div "Sponsored stories"`.
    public var label: String
    /// The nearest `data-adk-ref`, present in the agent preview's markup.
    public var ref: String?

    public init(kind: Kind, thisItem: String?, allLikeIt: String?, allLikeItCount: Int,
                pageElementCount: Int, label: String, ref: String?) {
        self.kind = kind
        self.thisItem = thisItem
        self.allLikeIt = allLikeIt
        self.allLikeItCount = allLikeItCount
        self.pageElementCount = pageElementCount
        self.label = label
        self.ref = ref
    }

    private enum CodingKeys: String, CodingKey {
        case kind, thisItem, allLikeIt, allLikeItCount, pageElementCount, label, ref
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kind = try container.decode(Kind.self, forKey: .kind)
        thisItem = try container.decodeIfPresent(String.self, forKey: .thisItem)
        allLikeIt = try container.decodeIfPresent(String.self, forKey: .allLikeIt)
        allLikeItCount = try container.decodeIfPresent(Int.self, forKey: .allLikeItCount) ?? 0
        pageElementCount = try container.decodeIfPresent(Int.self, forKey: .pageElementCount) ?? 0
        label = try container.decodeIfPresent(String.self, forKey: .label) ?? ""
        ref = try container.decodeIfPresent(String.self, forKey: .ref)
    }

    /// The All items like it choice is offered only for a looser selector that
    /// matches at most half of the page's elements.
    public var allLikeItAllowed: Bool {
        allLikeIt != nil && allLikeItCount <= pageElementCount / 2
    }
}

/// The selecting-mode script on one web view: outlines the element under the
/// pointer, swallows the page's clicks and reports picks. The vendored finder
/// and the picker run in their own content world, `adk-element-picker`, so
/// the page's scripts cannot see, call or replace them.
@MainActor
public final class BrowserElementPicker: NSObject, WKScriptMessageHandler {
    public static let contentWorldName = "adk-element-picker"
    public static let messageHandlerName = "adkitchenPicker"

    /// Made once and kept: on macOS 26 a second `WKContentWorld.world(name:)`
    /// with the same name is a fresh world, so every call passes this object.
    public static let world: WKContentWorld = .world(name: contentWorldName)

    private static let logger = Logger(subsystem: "AgenticDeveloperHubSDK", category: "BrowserPane")

    /// `vendor/finder.js`: defines `__adkFinder` on the global object of the
    /// world that evaluates it. The automation world loads it too.
    public static var finderSource: String {
        get throws { try resource("finder") }
    }

    /// `BrowserElementPicker.js`: needs `__adkFinder` in the same world first.
    public static var pickerSource: String {
        get throws { try resource("BrowserElementPicker") }
    }

    private static func resource(_ name: String) throws -> String {
        guard let url = Bundle(for: BrowserElementPicker.self).url(forResource: name, withExtension: "js") else {
            throw BrowserAutomationError.runtimeMissing
        }
        return try String(contentsOf: url, encoding: .utf8)
    }

    public let list: BrowserHiddenItemList
    private weak var webView: WKWebView?
    private let onPick: (BrowserPickCandidate) -> Void
    private let onCancel: () -> Void
    private(set) var isRunning = false
    private(set) var isPaused = false

    public init(webView: WKWebView, list: BrowserHiddenItemList,
                onPick: @escaping (BrowserPickCandidate) -> Void,
                onCancel: @escaping () -> Void) {
        self.webView = webView
        self.list = list
        self.onPick = onPick
        self.onCancel = onCancel
        super.init()
    }

    /// Adds the handler and evaluates the finder and the picker in the
    /// picker's world. Starting a running picker does nothing.
    public func start() async throws {
        guard !isRunning, let webView else { return }
        let controller = webView.configuration.userContentController
        let finder = try Self.finderSource
        let picker = try Self.pickerSource
        controller.removeScriptMessageHandler(forName: Self.messageHandlerName, contentWorld: Self.world)
        controller.add(self, contentWorld: Self.world, name: Self.messageHandlerName)
        isRunning = true
        isPaused = false
        do {
            // `;true` gives each evaluation a value WebKit can return.
            _ = try await webView.evaluateJavaScript(finder + "\n;true", in: nil, contentWorld: Self.world)
            _ = try await webView.evaluateJavaScript(picker + "\n;true", in: nil, contentWorld: Self.world)
        } catch {
            Self.logger.error("The element picker failed to install: \(error.localizedDescription, privacy: .public)")
            stop()
            throw error
        }
    }

    /// No outline and no picks until `resume()`; page clicks stay swallowed.
    public func pause() {
        guard isRunning else { return }
        isPaused = true
        run("globalThis.__adkPicker && globalThis.__adkPicker.pause(); true")
    }

    public func resume() {
        guard isRunning else { return }
        isPaused = false
        run("globalThis.__adkPicker && globalThis.__adkPicker.resume(); true")
    }

    /// Removes the outline, the listeners and the message handler.
    public func stop() {
        guard isRunning else { return }
        isRunning = false
        isPaused = false
        run("globalThis.__adkPicker && globalThis.__adkPicker.stop(); true")
        webView?.configuration.userContentController
            .removeScriptMessageHandler(forName: Self.messageHandlerName, contentWorld: Self.world)
    }

    private func run(_ script: String) {
        webView?.evaluateJavaScript(script, in: nil, in: Self.world) { result in
            if case .failure(let error) = result {
                Self.logger.error("Element picker call failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    public func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage) {
        guard isRunning else { return }
        handle(body: message.body)
    }

    /// Decodes one message body and routes it. A pick with no This item
    /// selector is refused with a beep and selecting continues.
    func handle(body: Any) {
        guard let candidate = Self.decode(body) else { return }
        switch candidate.kind {
        case .cancel:
            onCancel()
        case .pick:
            guard !isPaused else { return }
            guard candidate.thisItem != nil else {
                NSSound.beep()
                return
            }
            onPick(candidate)
        }
    }

    static func decode(_ body: Any) -> BrowserPickCandidate? {
        guard JSONSerialization.isValidJSONObject(body),
              let data = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        return try? JSONDecoder().decode(BrowserPickCandidate.self, from: data)
    }
}
