import AppKit
import AgenticDeveloperHubSDKCore

/// The General row of the Sessions or AI Conversations settings topic: how
/// that window behaves. Its summaries are the topic's AI Summaries row
/// (`AISummariesSettingsPanel(feature:)`), one per feature.
@MainActor
public final class SummaryFeatureSettingsPanel: ComposableSettings.SettingsPanelViewController {

    /// Which window the panel is for; it names the panel's settings and help.
    public enum Feature: Sendable {
        case sessions
        case conversations

        var title: String { self == .sessions ? "Sessions" : "AI Conversations" }
    }

    private let feature: Feature

    public init(feature: Feature) {
        self.feature = feature
        super.init(with: ComposableSettings.SettingsPanelDescriptor(
            title: "General",
            icon: NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        ))
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override var searchKeywords: [String] {
        switch feature {
        case .sessions: ["sessions", "always on top", "float", "transparency", "opacity", "filter"]
        case .conversations: ["conversations", "always on top", "float", "work output", "thinking"]
        }
    }

    public override var helpContent: ComposableSettings.PanelHelp? {
        var topics: [ComposableSettings.PanelHelp.Topic] = [
            .init(
                title: "Always on Top",
                body: "With this on, the \(feature.title) window floats above every other "
                    + "window, so it stays in sight while you work elsewhere."
            )
        ]
        switch feature {
        case .sessions:
            topics.append(.init(
                title: "Transparency",
                body: "How opaque the Sessions window is. Lower values let what is behind "
                    + "it show through."
            ))
        case .conversations:
            topics.append(.init(
                title: "Work Output",
                body: "The agent's narration of what it is doing, and its thinking, shown "
                    + "beside what it said to you. Off, the window shows the conversation "
                    + "alone, which is far easier to read."
            ))
        }
        return ComposableSettings.PanelHelp(topics: topics)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        let group = ComposableSettings.GroupView(withTitle: "Window")
        switch feature {
        case .sessions:
            group.addSettingSubview(ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
                title: "Always on top",
                setting: UserSettings.stenographerSessionsWindowAlwaysOnTop
            )))
            group.addSettingSubview(ComposableSettings.CaptionedSliderView(
                viewModel: ComposableSettings.RangeViewModel<Double>(
                    title: "Transparency",
                    setting: UserSettings.stenographerSessionsWindowTransparency,
                    minValue: 0.3, maxValue: 1.0
                ),
                formatter: { "\(Int((1.0 - $0) * 100))% transparent" }
            ))
        case .conversations:
            group.addSettingSubview(ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
                title: "Show work output",
                setting: UserSettings.stenographerConversationsShowWorkOutput
            )))
            group.addSettingSubview(ComposableSettings.CheckboxView(with: ComposableSettings.ViewModel<Bool>(
                title: "Always on top",
                setting: UserSettings.stenographerConversationsAlwaysOnTop
            )))
        }
        addGroup(group)
    }
}
