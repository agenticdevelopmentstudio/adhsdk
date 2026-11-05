import Foundation
@testable import AgenticDeveloperHubSDK

/// A `ThemeStorage` that keeps custom themes in memory for the duration of a
/// test. Two `ThemeStore`s sharing one instance see the same themes, which is
/// how the round-trip test stands in for "quit and relaunch" without touching
/// the host's real preferences.
@MainActor
final class InMemoryThemeStorage: ThemeStorage {
    var customThemes: [ColorTheme]
    var activeThemeID: String?
    var onExternalChange: (() -> Void)?

    init(customThemes: [ColorTheme] = [], activeThemeID: String? = nil) {
        self.customThemes = customThemes
        self.activeThemeID = activeThemeID
    }
}
