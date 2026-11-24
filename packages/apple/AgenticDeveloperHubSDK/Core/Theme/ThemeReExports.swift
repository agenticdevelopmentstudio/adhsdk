// The theme model now lives in AgenticDeveloperHubSDK, which ships to
// customers on its own. Re-exported here so every existing call site —
// Temporal's log window and timeline, Stenographer, the settings panels —
// keeps resolving `SemanticPalette` through AgenticDeveloperHubSDKCore.
@_exported import AgenticDeveloperHubSDK
