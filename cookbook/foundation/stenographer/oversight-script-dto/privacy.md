
- **Data collected**: A script holds the author's rules and prompts; `systemPrompt` and `reasonTemplate` may contain user-written text, and `injectText` is text typed into a terminal session.
- **Storage**: None here; the daemon's script store persists scripts.
- **Transmission**: Over XPC and HTTP between app, CLI and daemon; the confirmation prompt is later sent to a model by the daemon.
- **Retention**: Not set by these types.

