// Re-exported (not merely imported): MarkdownDocument, MarkdownText, Frontmatter
// and friends live in AgenticDeveloperHubSDK, but every consumer of this
// module — including its own test target, which never imports
// AgenticDeveloperHubSDK directly — reaches them through
// `AgenticDeveloperHubSDKMarkdown`. Mirrors `Core/Theme/ThemeReExports.swift`'s
// re-export of the same module for the theme model.
@_exported import AgenticDeveloperHubSDK
