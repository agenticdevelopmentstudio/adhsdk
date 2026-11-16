//
//  BrowserAgentViewMode.swift
//  AgenticDeveloperHubSDK
//
//  Recipe: workspace/browser/agent-views (spec section 2.4).
//

import AgenticDeveloperHubSDKCore
import AppKit
import WebKit

/// What a browser tab shows: the website itself, or the page the agent
/// receives — rendered (Agent preview) or as source (Agent source).
///
/// Per tab and never persisted: a new tab, and every tab after a relaunch,
/// starts on `.website`.
public enum BrowserAgentViewMode: String, CaseIterable, Sendable {
    case website, agentPreview, agentSource

    /// The SF Symbol the mode's segment shows; segments carry no titles.
    public var symbol: String {
        switch self {
        case .website: return "globe"
        case .agentPreview: return "eye"
        case .agentSource: return "chevron.left.forwardslash.chevron.right"
        }
    }

    /// The segment's tooltip, the only words the control carries.
    public var toolTip: String {
        let bundle = Bundle(for: BrowserAutomationBundleAnchor.self)
        switch self {
        case .website:
            return NSLocalizedString(
                "browser.agent-view.website.tooltip", bundle: bundle,
                value: "Website — the page as it is", comment: "Agent view segment tooltip")
        case .agentPreview:
            return NSLocalizedString(
                "browser.agent-view.preview.tooltip", bundle: bundle,
                value: "Agent preview — what the agent can see, with privacy filters applied",
                comment: "Agent view segment tooltip")
        case .agentSource:
            return NSLocalizedString(
                "browser.agent-view.source.tooltip", bundle: bundle,
                value: "Agent source — the page the agent receives, as source",
                comment: "Agent view segment tooltip")
        }
    }

    /// The segment image's accessibility description.
    public var accessibilityLabel: String {
        let bundle = Bundle(for: BrowserAutomationBundleAnchor.self)
        switch self {
        case .website:
            return NSLocalizedString(
                "browser.agent-view.website.label", bundle: bundle, value: "Website", comment: "Agent view segment")
        case .agentPreview:
            return NSLocalizedString(
                "browser.agent-view.preview.label", bundle: bundle, value: "Agent preview",
                comment: "Agent view segment")
        case .agentSource:
            return NSLocalizedString(
                "browser.agent-view.source.label", bundle: bundle, value: "Agent source",
                comment: "Agent view segment")
        }
    }

    /// The segment index of this mode, in `allCases` order.
    var segment: Int { Self.allCases.firstIndex(of: self) ?? 0 }

    /// The mode at `segment`, `.website` for an index out of range.
    static func mode(atSegment segment: Int) -> BrowserAgentViewMode {
        allCases.indices.contains(segment) ? allCases[segment] : .website
    }
}

extension NSSegmentedControl {
    /// The Agent view control (`browser.agent-view`): one image segment per
    /// mode, each with its tooltip, selecting exactly one.
    static func browserAgentViewControl(target: AnyObject?, action: Selector?) -> NSSegmentedControl {
        let modes = BrowserAgentViewMode.allCases
        let control = NSSegmentedControl()
        control.segmentCount = modes.count
        control.trackingMode = .selectOne
        control.segmentStyle = .texturedRounded
        control.controlSize = .small
        for (index, mode) in modes.enumerated() {
            let image = NSImage(systemSymbolName: mode.symbol, accessibilityDescription: mode.accessibilityLabel)
            control.setImage(image, forSegment: index)
            control.setLabel("", forSegment: index)
            control.setToolTip(mode.toolTip, forSegment: index)
            control.setImageScaling(.scaleProportionallyDown, forSegment: index)
        }
        control.selectedSegment = BrowserAgentViewMode.website.segment
        control.setAccessibilityIdentifier("browser.agent-view")
        control.target = target
        control.action = action
        return control
    }
}

/// One tab's agent views: the mode, the preview and source controllers
/// (made the first time they are wanted), and the rebuild that fills them.
///
/// Rebuilds are coalesced (`refresh-coalesced`): every trigger inside
/// `interval` collapses into one read. A rebuild that finishes after a newer
/// one started is discarded, and leaving the agent modes cancels a pending
/// one, so a slow read can never paint over a newer page or a Website tab.
@MainActor
final class BrowserAgentViews {

    /// The settings whose change rebuilds the agent views: they change what
    /// the agent receives.
    static let refreshSettingNames: Set<String> = [
        UserSettings.browserAgentPrivacy.name, UserSettings.browserPrivacyHideImages.name
    ]

    private(set) var mode: BrowserAgentViewMode = .website

    /// How many rebuilds have started, for tests of coalescing and refresh.
    private(set) var rebuildCount = 0

    /// The page last shown, `nil` before the first rebuild finishes.
    private(set) var shownPage: AgentPage?

    private let interval: TimeInterval
    private let read: @MainActor () async -> AgentPage
    private let makeRuleList: @MainActor () async throws -> WKContentRuleList
    private var generation = 0
    private var pending: Task<Void, Never>?
    private var running: Task<Void, Never>?

    private(set) lazy var preview = BrowserAgentPreviewViewController(ruleList: makeRuleList)
    private(set) lazy var source = BrowserAgentSourceViewController()

    init(interval: TimeInterval = 0.25,
         ruleList: @escaping @MainActor () async throws -> WKContentRuleList
            = BrowserAgentPreviewViewController.defaultRuleList,
         read: @escaping @MainActor () async -> AgentPage) {
        self.interval = interval
        self.makeRuleList = ruleList
        self.read = read
    }

    /// The view the tab shows in place of its page, `nil` for `.website`.
    var contentView: NSView? {
        switch mode {
        case .website: return nil
        case .agentPreview: return preview.view
        case .agentSource: return source.view
        }
    }

    /// Switches the mode. Entering an agent mode rebuilds at once; Website
    /// cancels whatever was pending, and the page underneath is untouched.
    /// Moving between the two agent modes shows the last page at once, as it
    /// is still the current one. Coming from Website it shows the blank page
    /// until the rebuild lands: the page, its address or its agent list may
    /// have changed since, and an earlier page must never pass for this one.
    func setMode(_ newMode: BrowserAgentViewMode) {
        guard newMode != mode else { return }
        let previous = mode
        mode = newMode
        cancelPending()
        guard newMode != .website else { return }
        if previous == .website {
            shownPage = nil
            display(.blank)
        } else if let shownPage {
            show(shownPage)
        }
        startRebuild()
    }

    /// Asks for a rebuild, coalesced over `interval`. Nothing in Website mode.
    func setNeedsRefresh() {
        guard mode != .website else { return }
        pending?.cancel()
        let delay = UInt64(max(interval, 0) * 1_000_000_000)
        pending = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled, let self else { return }
            self.pending = nil
            self.startRebuild()
        }
    }

    /// Rebuilds now, skipping the coalescing delay (a tab coming to the front).
    func rebuildNow() {
        guard mode != .website else { return }
        pending?.cancel()
        pending = nil
        startRebuild()
    }

    /// Cancels a pending or running rebuild; called on Website and tab close.
    func cancelPending() {
        pending?.cancel()
        pending = nil
        running?.cancel()
        running = nil
        generation += 1
    }

    private func startRebuild() {
        generation += 1
        rebuildCount += 1
        let mine = generation
        running = Task { @MainActor [weak self] in
            guard let self else { return }
            let page = await self.read()
            guard !Task.isCancelled, mine == self.generation, self.mode != .website else { return }
            self.running = nil
            self.show(page)
        }
    }

    private func show(_ page: AgentPage) {
        shownPage = page
        display(page)
    }

    private func display(_ page: AgentPage) {
        switch mode {
        case .website: break
        case .agentPreview: preview.show(page)
        case .agentSource: source.show(page)
        }
    }
}
