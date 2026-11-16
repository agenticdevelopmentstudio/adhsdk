
**Decision**: A window is keyed by the canonical top level, resolved through git before its row is looked up.
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

**Decision**: The commit pane's divider is autosaved per repository.
**Rationale**: Two repositories open side by side would otherwise move each other's dividers, and the last one closed would win for every window.
**Approved**: pending

**Decision**: The Git window is the project window over a `.gitWindow` row, its panes fixed on the composable-tabs layout.
**Rationale**: One window class carries the toolbar, search, title, frames and terminals for every window kind; the Git window supplies only its panes and its session.
**Approved**: pending

**Decision**: A folder chosen in no repository gets an alert window of its own, not a sheet.
**Rationale**: No window exists yet to attach a sheet to; ordering it front without activating, and without a modal loop, keeps quiet presentation intact and every other window live.
**Approved**: pending

**Decision**: The watcher reads the git directory and the common directory with two separate `rev-parse` calls.
**Rationale**: One call prints both on separate lines, which a path containing a newline would split wrongly; each answer is read whole, trimming only git's final newline.
**Approved**: pending

**Decision**: An existing window opened with `activates` false is returned untouched.
**Rationale**: Restore and scripts must never take the foreground; `ProjectWindowManager.openStandaloneWindow` shows, orders front and activates an open window only when asked to activate, and the feature wires a window's session only when it opens it.
**Approved**: pending

**Decision**: The Git window keeps its rows with `StandaloneWindowRows`, as the File Browser and Document windows do, rather than a bookkeeping set of its own.
**Rationale**: One copy of the canonical spelling, the row lookup and the restore list; it also deletes a closed window's row and saved frame, and at launch every row not about to reopen, so the database does not keep a row for every repository ever opened.
**Approved**: pending

**Decision**: Questions go through a `GitActionPresenting` protocol, with `NSAlert` sheets as its one AppKit implementation.
**Rationale**: The session's rules (what to ask before a hard reset, what to show after a failure) can be tested with a fake that answers instantly; a sheet keeps the question on the repository it concerns and never runs a modal loop that would stall the other windows.
**Approved**: pending

**Decision**: `Open` on a worktree or submodule row goes straight to `onOpenDirectory`, outside the one-action funnel.
**Rationale**: It runs no git and changes nothing in this repository, so making it wait for, or be dropped by, an action in progress would only get in the way.
**Approved**: pending

**Decision**: An empty `Folder` for a new worktree becomes `<parent of root>/<root's name>-<branch>`, beside the repository.
**Rationale**: It is where a worktree is usually put by hand, it never lands inside the working tree (where it would show as untracked), and a `/` in the branch made `-` keeps it one folder.
**Approved**: pending

**Decision**: The window's reviews provider is owned by its repository model (`GitRepositoryModel(reviews:)`), and the session reads it from there.
**Rationale**: The model owns the review loader and answers `review(for:)` for the history, so one owner keeps the provider and its cache together; the session only wires the detail and the change stream.
**Approved**: pending
