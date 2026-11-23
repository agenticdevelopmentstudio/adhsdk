// `ProjectDatabase`, `GitRepo` and the repo-state snapshot moved down to the
// Database tier so adhd can keep the project registry without AppKit.
// Re-exporting Database here keeps every caller that reached them through
// `AgenticDeveloperHubSDKMacOS` compiling unchanged.
@_exported import AgenticDeveloperHubSDKDatabase
