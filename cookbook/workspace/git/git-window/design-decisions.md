
**Decision**: The window set is keyed by the canonical top level, resolved through git before the set is asked.
**Rationale**: A window is a repository, not a directory; resolving first means a subdirectory and its root can never become two windows.
**Approved**: pending

**Decision**: The feature builds one highlighter, lazily, on the first window.
**Rationale**: The JavaScriptCore engine and its WASM are expensive; one per window would multiply both, and building at launch would cost every launch that never opens a git window. Building late also lets the extensions' grammars be loaded by then.
**Approved**: pending

**Decision**: The window re-checks its selection after every model change rather than relying on the sidebar.
**Rationale**: The sidebar only reports a selection that vanished; a branch whose tip moved, or a stash whose index shifted, is the same row to it but a different commit to the window.
**Approved**: pending

**Decision**: The file-type override is validated against the grammar registry inside the feature.
**Rationale**: The File Types mapping stores names typed by the user; only a value that is a language id the registry knows can colour anything, and an unknown override would otherwise stop the extension rules from applying.
**Approved**: pending

**Decision**: An existing window opened with `activates` false is returned untouched.
**Rationale**: Restore and scripts must never take the foreground; the keyed window set's bring-forward always activates, so the feature answers that case itself.
**Approved**: pending
