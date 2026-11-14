
**Decision**: The window set is keyed by the canonical top level, resolved through git before the set is asked.
**Rationale**: A window is a repository, not a directory; resolving first means a subdirectory and its root can never become two windows.
**Approved**: pending

**Decision**: The feature builds one highlighter, lazily, on the first window.
**Rationale**: The JavaScriptCore engine and its WASM are expensive; one per window would multiply both, and building at launch would cost every launch that never opens a git window. Building late also lets the extensions' grammars be loaded by then.
**Approved**: pending

**Decision**: The window re-checks its selection after every model change rather than relying on the sidebar.
**Rationale**: The sidebar only reports a selection that vanished; a branch whose tip moved, or a stash whose index shifted, is the same row to it but a different commit to the window.
**Approved**: pending

**Decision**: The app passes the File Types mapping's raw language name, and the feature maps it to a language id through the grammar registry.
**Rationale**: The mapping stores display names (`C++`, `Shell Script`), not ids; only the registry knows its ids and aliases, so the mapping belongs beside it, and a name it cannot map falls through so the extension rules still apply.
**Approved**: pending

**Decision**: The divider layout is autosaved per repository.
**Rationale**: Two repositories open side by side would otherwise move each other's dividers, and the last one closed would win for every window.
**Approved**: pending

**Decision**: The watcher reads the git directory and the common directory with two separate `rev-parse` calls.
**Rationale**: One call prints both on separate lines, which a path containing a newline would split wrongly; each answer is read whole, trimming only git's final newline.
**Approved**: pending

**Decision**: An existing window opened with `activates` false is returned untouched.
**Rationale**: Restore and scripts must never take the foreground; the keyed window set's bring-forward always activates, so the feature answers that case itself.
**Approved**: pending
