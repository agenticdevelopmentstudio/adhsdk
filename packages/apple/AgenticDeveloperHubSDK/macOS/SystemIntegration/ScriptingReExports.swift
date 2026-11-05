// `MainActorScriptCommand` and `AppleScriptRunner` moved down into
// AgenticDeveloperHubSDKScripting so an app can be scriptable without linking this
// framework's heavy dependency set. Consumers that reach them through
// `import AgenticDeveloperHubSDKMacOS` keep working — that is what `@_exported` is
// for; it costs a consumer nothing. (Same pattern as
// `CoreMacOS/Theme/ThemeUIReExports.swift`.)
//
// This file sits in `SystemIntegration/` rather than next to the code it
// re-exports: `macOS/Scripting/` is now excluded from this target wholesale,
// so a file placed there would not be compiled into it at all.
@_exported import AgenticDeveloperHubSDKScripting
