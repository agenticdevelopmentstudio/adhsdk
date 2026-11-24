
- **Data collected**: The shell's keystrokes and output, the privacy words and the authentication result; the words are the real text and the alias, which can be secrets.
- **Storage**: The controller stores nothing on disk. The words are kept by the vault in the keychain; the controller holds the loaded filter only through the vault and the session.
- **Transmission**: None by the controller; the window is excluded from screen capture while revealed, and there is no scripting or URL surface.
- **Retention**: The filter lives as long as the vault and the session; the process ends when the pane content is discarded.
- **Purpose**: Keeping a terminal's contents unreadable by anything outside the app and by anyone at the screen until the Mac owner authenticates, with output shown under aliases.

