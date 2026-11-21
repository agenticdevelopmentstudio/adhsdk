// `Note` moved down to the Markdown tier so a daemon or CLI can build one
// without AppKit. Re-exporting Markdown here keeps every caller that reached
// `Note` through `AgenticDeveloperHubSDKMacOS` compiling unchanged.
@_exported import AgenticDeveloperHubSDKMarkdown
