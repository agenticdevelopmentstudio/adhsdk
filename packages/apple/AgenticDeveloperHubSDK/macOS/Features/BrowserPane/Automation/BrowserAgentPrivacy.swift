import Foundation
import AgenticDeveloperHubSDKCore

/// What a browser pane's Agent Privacy setting means for the model tools at
/// the moment a call runs.
///
/// - `off`: the tools see the page as it is.
/// - `enabled`: every reply and error is concealed with the privacy words before a
///   model reads it, and what a model types or navigates to is revealed back
///   to the real words — the private terminal's rule, applied to a page. A
///   stand-in is written in the case of the word it replaces, as the page
///   itself is drawn (`BrowserPageWordFilter`); a real word is written exactly
///   as the pair gives it, because its case is part of it ("OpenAI", a
///   case-sensitive path) and the alias a model typed says nothing about it.
/// - `unavailable`: the setting is on but the words cannot be read (no vault,
///   or the keychain refused them without a prompt). The pane is closed to
///   models until they can be, rather than handed over unconcealed
///   (`fail-fast`).
public enum BrowserAgentPrivacy: Sendable, Equatable {
    case off
    case enabled(TextSubstitutionFilter)
    case unavailable

    public var isOn: Bool { self != .off }

    /// The tools that cannot be concealed: a screenshot is pixels, a click by
    /// coordinate is driven off one, and `browser_evaluate` can read the
    /// page's own data and return it in any shape. A private pane refuses
    /// them outright rather than leak through them.
    public static let refusedToolNames: Set<String> = [
        "browser_screenshot", "browser_click_at", "browser_evaluate"
    ]

    static let unavailableRefusal =
        "Agent Privacy is on for this browser pane, but the privacy words could not be read, "
        + "so the pane is closed to models until they can be."

    static func refusal(for tool: String) -> String {
        "\(tool) is refused on this browser pane: Agent Privacy is on, and \(tool) cannot be concealed."
    }

    /// `text` as a model may see it.
    public func concealing(_ text: String) -> String {
        switch self {
        case .off: text
        case .enabled(let filter): filter.concealing(text, matchingCase: true)
        case .unavailable: "(concealed)"
        }
    }

    /// `text` as the page should receive it, each real word as the pair
    /// gives it.
    public func revealing(_ text: String) -> String {
        if case .enabled(let filter) = self { return filter.revealing(text) }
        return text
    }
}
