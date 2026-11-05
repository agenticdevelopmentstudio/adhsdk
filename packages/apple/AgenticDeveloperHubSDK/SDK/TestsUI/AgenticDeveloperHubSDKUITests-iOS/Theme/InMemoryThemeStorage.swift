import Foundation
import AgenticDeveloperHubSDK

/// A `ThemeStorage` that keeps the active theme and custom themes in memory for
/// the duration of a test — mirrors
/// `AgenticDeveloperHubSDKUITests/Theme/InMemoryThemeStorage.swift`, duplicated
/// here because one test bundle can't see another's types.
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
