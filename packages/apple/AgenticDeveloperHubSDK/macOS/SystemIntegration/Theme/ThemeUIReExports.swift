// The AppKit theme UI (ThemeManager, Themeable, ThemePaletteObserver, and the
// Themed* view family) moved to AgenticDeveloperHubSDKUI, which ships to
// customers on its own — see that framework's SourcesUI/macOS/Theme/.
// Re-exported here so every existing call site keeps resolving them through
// AgenticDeveloperHubSDKMacOS without a new import.
//
// This mirrors Core/Theme/ThemeReExports.swift, which does the same for the
// Foundation-only theme model (`@_exported import AgenticDeveloperHubSDK`)
// in AgenticDeveloperHubSDKCore. This one is AppKit, so it lives here in
// AgenticDeveloperHubSDKMacOS instead, next to the `ThemeManager()` convenience init.
@_exported import AgenticDeveloperHubSDKUI
