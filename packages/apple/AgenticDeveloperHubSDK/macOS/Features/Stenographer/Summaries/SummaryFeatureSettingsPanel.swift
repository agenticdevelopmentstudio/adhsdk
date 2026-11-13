import AppKit
import AgenticDeveloperHubSDKCore

/// The settings topic of a window the AI summaries feed — Sessions or
/// Conversations: the summaries switch, the same one Settings › AI › Summaries
/// holds, so the window that shows summaries is where they can be turned on.
@MainActor
public final class SummaryFeatureSettingsPanel: ComposableSettings.SettingsPanelViewController {

    /// Which window the panel is for; it names the panel and its help.
    public enum Feature: Sendable {
        case sessions
        case conversations

        var title: String { self == .sessions ? "Sessions" : "Conversations" }
        var symbol: String { self == .sessions ? "list.bullet.rectangle" : "bubble.left.and.bubble.right" }
    }

    private let feature: Feature

    public init(feature: Feature) {
        self.feature = feature
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: feature.title,
            icon: NSImage(systemSymbolName: feature.symbol, accessibilityDescription: nil)
        ))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var searchKeywords: [String] {
        [feature.title.lowercased(), "summary", "summaries", "ai"]
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        ComposableSettings.PanelHelp(topics: [
            .init(
                title: "AI Summaries",
                body: "With this on, the daemon writes a short title for each Claude Code session, "
                    + "and the \(feature.title) window shows it. The provider, model and prompt "
                    + "are under Settings › AI › Summaries; this is the same switch."
            )
        ])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        addGroup(AISummariesPluginControls.makeSummariesGroup())
    }
}
