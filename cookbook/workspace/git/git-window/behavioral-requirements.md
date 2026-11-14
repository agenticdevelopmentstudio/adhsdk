
### Feature

- **window-key-canonical**: A window's key MUST be the repository top level `GitClient.topLevel(of:)` reports for the requested path, standardised and with symlinks resolved, so a subdirectory, the root, and a symlinked spelling of either open one window.
- **one-window-per-key**: Opening a key that already has a window MUST return that window's controller and MUST NOT build a second; with `activates` true it brings the window forward and activates the app unless presentation is quiet, with `activates` false it leaves the window where it is.
- **non-repository-refused**: Opening a path that is not inside a repository (or does not exist) MUST log the client's failure by `GitClientError.logDescription(of:)` and return nil, opening nothing and remembering nothing.
- **open-windows-remembered**: The keys of open windows MUST persist in `open_git_window_roots` in the order first opened; a window the user closes MUST be forgotten; a window closed while the app terminates MUST NOT be.
- **restore-quietly**: `restoreOpenWindows()` MUST reopen every remembered key without activating the app, and MUST forget a key whose directory no longer exists.
- **shared-highlighter**: Every window MUST share one `GitSyntaxColoring`, built on the first window over a grammar registry whose sources are, in order, the user grammars directory, the extensions' grammars (a snapshot taken then), and the bundled grammars.
- **missing-resources-uncoloured**: When the TextMate resources are missing (nil) or the highlighter cannot be built, the feature MUST log it once and every window MUST show code uncoloured.
- **file-type-override-validated**: The injected file-type override MUST be consulted for a file's language, but only a value the grammar registry knows as a language id is used; anything else falls through to the name and extension rules.
- **commands**: The feature MUST register `git.action.openWindow` (asks for a folder, then opens it) and `git.action.openWindowForPath` (opens its first argument, a path string; no argument or a non-string does nothing), and contribute File > New > `New Git Window…` at order 45 bound to `git.action.openWindow`.

### Window

- **window-identity**: The window id MUST be `git:<key>`, the title the top level's folder name, and the subtitle the current branch (`detached HEAD` when there is none), refreshed after every refs change; a failed branch read is logged and keeps the last subtitle.
- **layout**: The content MUST be a three-column split, autosaved: the sidebar, the centre, and a right column that is itself a horizontal-divider split of the commit detail over the bottom pane (diff, blame or file history).
- **centre-follows-sidebar**: The centre MUST show the working copy while the sidebar's Working Copy row is selected (including when the sidebar falls back to it after its selection vanished), and the history otherwise.
- **ref-scrolls-history**: Selecting a branch or tag MUST show the history and select the ref's target commit there; when the commit is not loaded, nothing is selected and the selection is applied after a later history change loads it.
- **stash-shows-commit**: Selecting a stash MUST show the history and load the stash's commit (`git log` of the stash id, one commit) into the commit detail; a failed load is logged and shown as a plain error label.
- **directory-opens-window**: Choosing a submodule or worktree row MUST open (or bring forward) that directory's own git window through the feature.
- **history-selection-shows-detail**: A commit selected in the history MUST be shown in the commit detail, and the bottom pane MUST return to the diff and clear.
- **file-shows-diff**: A file chosen in the commit detail MUST show the diff `.commit(<id>, paths:)` for that file (its old path too, for a rename); a file cleared MUST clear the diff.
- **working-copy-target**: While the working copy is the centre, a working-copy selection MUST show its target's diff and nil MUST clear it.
- **blame-and-history**: Blame or History requested from the diff (or from the file history's own diff) MUST swap the bottom pane to the blame of that path at that revision, or the file history of that path; choosing a commit in the blame, or a parent link in the commit detail, MUST select that commit in the history.
- **refresh-reapplies-selection**: After each model change the window MUST reload the views the change concerns (refs: sidebar; history: history; working copy or operation: working copy) and then re-check its own selection: a ref whose target moved re-selects the new target, a stash whose id changed reloads it, and one that vanished leaves the sidebar's fallback in charge.
- **search-drives-history**: Text in the toolbar search field MUST be handed to the history's `setQuery(_:)` as typed.
- **refresh-button**: Refresh MUST ask the model to reload every part, then reload the visible views.
- **latest-call-wins**: Each asynchronous load the window starts (the subtitle, a stash's commit) MUST carry a generation the window owns, and a result for an older generation MUST be dropped.
- **close-stops-model**: Closing the window MUST stop the model's watcher and tell the feature, unless the app is terminating.
- **confines-to-ui-thread**: The feature and the window MUST be usable only on the UI thread.
