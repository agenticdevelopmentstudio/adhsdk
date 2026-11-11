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
/// - `conflicting`: the setting is on, but a stand-in contains a real word
///   ("Alice = Bob; Bob = Alice", "Fred = Ed", "a = b; b = c"). The page is
///   drawn through the words once, and a model's reads are concealed again on
///   top, to catch what the page script skips (a textarea, an editor); that
///   second pass is harmless only when no stand-in holds a real word, so with
///   these words it would rewrite stand-ins and hand models the real words.
///   The pane is closed to models, and its page drawn as it is, until the
///   words are changed.
public enum BrowserAgentPrivacy: Sendable, Equatable {
    case off
    case enabled(TextSubstitutionFilter)
    case unavailable
    case conflicting

    /// `.enabled(filter)`, or `.conflicting` when concealing with `filter`
    /// twice would not give what concealing once does.
    public static func checking(_ filter: TextSubstitutionFilter) -> BrowserAgentPrivacy {
        filter.standInsHoldRealWords ? .conflicting : .enabled(filter)
    }

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

    static let conflictingRefusal =
        "Agent Privacy is on for this browser pane, but one privacy word's stand-in contains another's real word, "
        + "so the pane is closed to models until the privacy words are changed."

    /// The sentence a tool call is refused with, or `nil` when the pane is
    /// open to the call as far as Agent Privacy goes.
    func closedRefusal() -> String? {
        switch self {
        case .unavailable: Self.unavailableRefusal
        case .conflicting: Self.conflictingRefusal
        case .off, .enabled: nil
        }
    }

    static func refusal(for tool: String) -> String {
        "\(tool) is refused on this browser pane: Agent Privacy is on, and \(tool) cannot be concealed."
    }

    /// `text` as a model may see it. A real word is also concealed in the
    /// forms an address writes it in (`TextSubstitutionFilter.includingURLForms`),
    /// since replies and `browser_list` carry addresses as they are encoded.
    public func concealing(_ text: String) -> String {
        switch self {
        case .off: text
        case .enabled(let filter): filter.includingURLForms.concealing(text, matchingCase: true)
        case .unavailable, .conflicting: "(concealed)"
        }
    }

    /// `text` as the page should receive it, each real word as the pair
    /// gives it. Only whole aliases are revealed: what is revealed goes into a
    /// page or onto the network, and an alias's letters inside a longer word
    /// or a host name ("Sam" in samsung.com) are not the alias.
    public func revealing(_ text: String) -> String {
        if case .enabled(let filter) = self { return filter.revealing(text, wholeWords: true) }
        return text
    }
}

extension TextSubstitutionFilter {

    /// Whether some pair's alias contains some pair's real text, ignoring
    /// case. When none does, concealing is idempotent: what one pass wrote
    /// holds no real word for a second pass to find.
    public var standInsHoldRealWords: Bool {
        let reals = pairs.map { $0.real.lowercased() }
        return pairs.contains { pair in
            let alias = pair.alias.lowercased()
            return reals.contains { alias.contains($0) }
        }
    }

    /// The pairs, plus each pair again in the forms a URL writes a word in
    /// when that differs from the word: every character but the unreserved
    /// ones percent-escaped ("Zoë" as "Zo%C3%AB", a space as "%20"), and the
    /// same with a space as "+", as a form's query string has it. The alias is
    /// written in the same form, so a concealed address stays an address.
    /// Matching ignores case, which covers lower-case escapes too.
    public var includingURLForms: TextSubstitutionFilter {
        var extra: [Pair] = []
        for pair in pairs {
            for form in [Self.percentEscaped, Self.formEscaped] {
                let real = form(pair.real)
                if real != pair.real { extra.append(Pair(alias: form(pair.alias), real: real)) }
            }
        }
        return extra.isEmpty ? self : TextSubstitutionFilter(pairs: pairs + extra)
    }

    /// RFC 3986's unreserved characters, the only ones never escaped.
    private static let unreserved = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

    private static func percentEscaped(_ text: String) -> String {
        text.addingPercentEncoding(withAllowedCharacters: unreserved) ?? text
    }

    private static func formEscaped(_ text: String) -> String {
        (text.addingPercentEncoding(withAllowedCharacters: unreserved.union(CharacterSet(charactersIn: " "))) ?? text)
            .replacingOccurrences(of: " ", with: "+")
    }
}
