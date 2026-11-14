---
id: 6a830cf8-0b95-4ffd-b175-f5cf481490c4
title: "Git Window"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "One window per repository, keyed by its canonical top level: the refs sidebar, the history or the working copy, and the commit detail over the diff, with search and Refresh in the toolbar; the feature that opens, remembers and restores those windows, shares one syntax highlighter between them and registers the commands that open them."
platforms:
  - swift
  - macos
tags:
  - git
  - window
  - ui
  - history
  - diff
  - syntax-highlighting
depends-on:
  - bdd3a72d-8810-439b-bad7-ec16233cb2a3
  - a2394ca0-3988-410b-9fc8-e0c9e253fc94
  - 274f0727-b9b3-4fd3-9dea-b7e1bfbe92fc
  - 6708bfd4-5b29-4bf9-b180-05904873906e
  - add92e9b-94e5-412c-970f-5ea8e2eb9eed
related:
  - 92f11498-2cb2-4b04-92b9-560d9f2de6ee
references: []
approved-by: ""
approved-date: ""
---

# Git Window
## Overview

A git window shows one repository. `GitWindowFeature` owns every git window: it turns any directory inside a repository into the repository's canonical top level, keeps one window per top level through a [keyed window set](cookbook:274f0727-b9b3-4fd3-9dea-b7e1bfbe92fc) that remembers which were open and reopens them at launch, builds one [syntax highlighter](cookbook:6708bfd4-5b29-4bf9-b180-05904873906e) for all of them from the [TextMate resources](cookbook:add92e9b-94e5-412c-970f-5ea8e2eb9eed), and registers the two commands that open a window (with a chooser, or on a given path) and the File > New menu item.

`GitWindowController` is one window: a [repository model](cookbook:a2394ca0-3988-410b-9fc8-e0c9e253fc94) on its top level, kept current by a watcher, and the [git views](cookbook:bdd3a72d-8810-439b-bad7-ec16233cb2a3) in an autosaved three-column split (`GitWindowSplitViewController`): the refs sidebar; the history, or the working copy while the sidebar's Working Copy row is selected; and the commit detail over the diff, whose bottom pane swaps to a blame or a file history on request. The controller routes every view's delegate call to the view it concerns, so no view knows another. The toolbar (`GitWindowToolbar`) holds the history search field and Refresh.

The branch card's [branch management](cookbook:92f11498-2cb2-4b04-92b9-560d9f2de6ee) offers "Open in Git Window" when the open-for-path command is registered.
## Behavioral Requirements

### Feature

- **window-key-canonical**: A window's key MUST be the repository top level `GitClient.topLevel(of:)` reports for the requested path, standardised and with symlinks resolved, so a subdirectory, the root, and a symlinked spelling of either open one window.
- **one-window-per-key**: Opening a key that already has a window MUST return that window's controller and MUST NOT build a second; with `activates` true it brings the window forward and activates the app unless presentation is quiet, with `activates` false it leaves the window where it is.
- **non-repository-refused**: Opening a path that is not inside a repository (or does not exist) MUST log the client's failure by `GitClientError.logDescription(of:)` and return nil, opening nothing and remembering nothing.
- **open-windows-remembered**: The keys of open windows MUST persist in `open_git_window_roots` in the order first opened; a window the user closes MUST be forgotten; a window closed while the app terminates MUST NOT be.
- **restore-quietly**: `restoreOpenWindows()` MUST reopen every remembered key without activating the app, and MUST forget a key whose directory no longer exists.
- **shared-highlighter**: Every window MUST share one `GitSyntaxColoring`, built on the first window over a grammar registry whose sources are, in order, the user grammars directory, the extensions' grammars (a snapshot taken then), and the bundled grammars.
- **missing-resources-uncoloured**: When the TextMate resources are missing (nil) or the highlighter cannot be built, the feature MUST log it once and every window MUST show code uncoloured.
- **file-type-override-validated**: The injected file-type override MUST be consulted for a file's language, and the name it returns (the File Types mapping stores display names such as `C++` or `Shell Script`) MUST be mapped to a language id through the grammar registry's ids and aliases, exactly or with spaces and punctuation other than `+` and `#` dropped; a name the registry cannot map falls through to the name and extension rules.
- **commands**: The feature MUST register `git.action.openWindow` (asks for a folder, then opens it) and `git.action.openWindowForPath` (opens its first argument, a path string; no argument or a non-string does nothing), and contribute File > New > `New Git Window…` at order 45 bound to `git.action.openWindow`.

### Window

- **window-identity**: The window id MUST be `git:<key>`, the title the top level's folder name, and the subtitle the current branch (`detached HEAD` when there is none), refreshed after every refs change; a failed branch read is logged and keeps the last subtitle.
- **layout**: The content MUST be a three-column split, autosaved once per repository (the autosave names carry the top level's path): the sidebar, the centre, and a right column that is itself a horizontal-divider split of the commit detail over the bottom pane (diff, blame or file history).
- **centre-follows-sidebar**: The centre MUST show the working copy while the sidebar's Working Copy row is selected (including when the sidebar falls back to it after its selection vanished), and the history otherwise.
- **ref-scrolls-history**: Selecting a branch or tag MUST show the history and select the ref's target commit there; when the commit is not loaded, nothing is selected and the selection is applied after a later history change loads it.
- **stash-shows-commit**: Selecting a stash MUST show the history and load the stash's commit (`git log` of the stash id, one commit) into the commit detail; a failed load is logged and shown as a plain error label.
- **directory-opens-window**: Choosing a submodule or worktree row MUST open (or bring forward) that directory's own git window through the feature.
- **history-selection-shows-detail**: A commit selected in the history MUST be shown in the commit detail, and the bottom pane MUST return to the diff and clear.
- **file-shows-diff**: A file chosen in the commit detail MUST show the diff `.commit(<id>, paths:)` for that file (its old path too, for a rename); a file cleared MUST clear the diff.
- **working-copy-target**: While the working copy is the centre, a working-copy selection MUST show its target's diff and nil MUST clear it.
- **blame-and-history**: Blame or History requested from the diff (or from the file history's own diff) MUST swap the bottom pane to the blame of that path at that revision, or the file history of that path; choosing a commit in the blame, or a parent link in the commit detail, MUST select that commit in the history.
- **refresh-reapplies-selection**: After each model change the window MUST reload the views the change concerns (refs: sidebar; history: history; working copy or operation: working copy) and only then re-check its own selection, once per change: a ref whose target moved re-selects the new target, counted as applied only once the history holds and selects that commit (so a commit picked by hand survives a Refresh that moved nothing), a stash whose id changed reloads it, and one that vanished leaves the sidebar's fallback in charge. The bottom pane MUST follow too: a working-copy diff or a blame of the working file reloads on a working-copy or operation change, and a file history reloads on a history change.
- **search-drives-history**: Text in the toolbar search field MUST be handed to the history's `setQuery(_:)` as typed.
- **refresh-button**: Refresh MUST ask the model to reload every part, then reload the visible views, the bottom pane included, and re-check the selection without forgetting what was applied.
- **latest-call-wins**: Each asynchronous load the window starts (the subtitle, a stash's commit) MUST carry a generation the window owns, and a result for an older generation MUST be dropped.
- **close-stops-model**: Closing the window MUST stop the model's watcher and tell the feature, unless the app is terminating.
- **confines-to-ui-thread**: The feature and the window MUST be usable only on the UI thread.
## Appearance

A titled, closable, miniaturizable, resizable window, 1200 x 760 points by default and at least 720 x 440, with a unified toolbar: a flexible space, the search field (placeholder `Search history`), then Refresh (`arrow.clockwise`). The title bar shows the folder name over the branch as its subtitle. Columns: sidebar about 220 points (160-360), centre at least 360, right column at least 320; in the right column the commit detail takes about 40 % of the height. Every pane is the git views' own, themed by them.
## States

- **Opening**: the window shows at once, empty, and fills as the model's first refresh lands.
- **Working Copy selected**: the centre is the working copy.
- **Stash load failed**: the commit detail is cleared and a plain error label shows the failure's description; selecting anything else hides it.
- **Repository deleted underneath**: the model keeps its last state and logs; the window keeps showing it until closed.
- **Highlighting unavailable**: diffs and blame show uncoloured text.
## Accessibility

The window carries `git-window`. Its split carries `git.window.split`, the right column `git.window.right`, the centre container `git.window.centre`, the bottom container `git.window.bottom`, the error label `git.window.error`; the toolbar's search field `git.window.search` and Refresh `git.window.refresh`. The panes keep the git views' own identifiers.
## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-window-001 | window-key-canonical, one-window-per-key | A temporary repository with a subdirectory `sub`; open `sub`, then the root, both with `activates` false | The same controller both times; its window id is `git:` + the canonical root path; the remembered list holds that one path. |
| git-window-002 | non-repository-refused | A temporary directory that is not a repository; open it | nil; the remembered list is unchanged. |
| git-window-003 | commands | Branch management for a checkout, with a registry that holds `git.action.openWindowForPath` | Its commands include `branch.action.openGitWindow.<checkout id>` titled `Open in Git Window`; running it executes the open-for-path command with the checkout's directory path. |
| git-window-004 | commands | The same, with a registry that does not hold it | No such command. |
| git-window-005 | refresh-reapplies-selection, ref-scrolls-history | `main` selected; a new commit on it, reported as refs and history at once | The history and the commit detail both show the new tip. |
| git-window-006 | refresh-reapplies-selection, refresh-button | `main` selected and an older commit picked in the history; Refresh | The older commit stays selected and shown. |
| git-window-007 | centre-follows-sidebar | A branch selected, then deleted; a refs change | Selection Working Copy, the centre the working copy, the detail empty. |
| git-window-008 | stash-shows-commit | A stash whose id git cannot read is selected | The detail is hidden and the error label `git.window.error` shows git's message. |
| git-window-009 | refresh-reapplies-selection, refresh-button | A working-copy diff of a modified file; the file edited again, then a working-copy change; edited again, then Refresh | The diff shows the new text both times. |
| git-window-010 | refresh-reapplies-selection | A blame of the working file; the file edited, then a working-copy change | The blame shows the new text. |
| git-window-011 | refresh-reapplies-selection | A file history of `a.txt`; a new commit to it, then a history change | One more entry. |
| git-window-012 | search-drives-history | Two commits; a `sha:` search for the older one's prefix, then a message search | The older commit is selected; then the model's query is the parsed message search and only the matching commit is listed. |
| git-window-013 | window-identity | Subtitle `main`; the repository's `.git` moved away; the subtitle read again | The subtitle is still `main`. |
| git-window-014 | file-type-override-validated | Names `C++`, `C#`, `Shell Script`, `bash`, an unknown name, a blank name | `cpp`, `csharp`, `shellscript`, `shellscript` (an alias), nil, nil. |
| git-window-015 | commands | Open Git Window for Path run with no argument, then with a number | No window opens and nothing is remembered. |
## Edge Cases

- **Symlinked spelling**: `/tmp/r` and `/private/tmp/r` resolve to one key and one window.
- **Linked worktree**: its own top level, so its own window; the watcher watches its git directory and the common directory.
- **Submodule row**: opens the submodule's own window, keyed by its own top level.
- **Remembered root gone**: dropped at restore.
- **Remembered root no longer a repository**: dropped at restore, since it no longer resolves.
- **Detached HEAD**: subtitle `detached HEAD`.
- **Two repositories open side by side**: each keeps its own divider positions.
- **A repository path containing a newline**: the watcher reads each directory with its own `rev-parse`, so the path is not split.
- **Refresh with nothing changed**: a commit picked by hand in the history stays selected.
- **Fast typing in search**: the history view serialises queries; the window only forwards text.
- **Quick selection changes**: generations drop stale stash and subtitle loads; the views drop their own.
- **Offline / disconnected state**: Not applicable: no network.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `commandRegistry` | `CommandRegistry` | none | Where the two commands register. |
| `resources` | `TextMateResources?` | none | The bundled TextMate directory (`Contents/Resources/TextMate`); nil shows code uncoloured. |
| `userGrammarsDirectory` | `URL` | none | User grammars, ahead of every other source (`~/.agenticdeveloperkitchen/Grammars` in the Kitchen). |
| `extensionGrammars` | `() -> GrammarSource?` | none | The extensions' grammars, read when the highlighter is built. |
| `fileTypeOverride` | `@Sendable (URL) -> String?` | none | The app's File Types mapping: the language name the user chose for the file's extension, mapped to a language id through the grammar registry. |
| `client` | `GitClient` | `.shared` | Every git call. |
| `openRoots` | `UserSetting<[String]>` | `UserSettings.openGitWindowRoots` (`open_git_window_roots`) | Where the open windows are remembered. |
## Deep Linking

Not applicable: the window defines no URL scheme or route; scripts reach it through `perform command "git.action.openWindowForPath" with arguments {"<path>"}`.
## Localization

The menu item (`New Git Window…`), command titles, toolbar labels (`Search history`, `Refresh`), `detached HEAD` and the folder chooser's `Open` button are English literals today; ref names and paths are shown verbatim.
## Accessibility Options

The panes follow the theme's fonts; the window adds no text of its own beyond the title and subtitle.
## Feature Flags

Not applicable: the window contains no feature-flag reference.
## Analytics

Not applicable: the window contains no analytics call.
## Privacy

The window shows local repository data only and sends nothing anywhere; the remembered list holds local paths.
## Logging

Under the `Loggable` categories of `GitWindowFeature`, `GitWindowController` and `GitDeferredRepositoryWatcher` (the last for its directories): a path refused as not a repository, missing TextMate resources or a highlighter that cannot be built (once), a failed branch read, a failed stash load and a watcher that could not resolve its directories, each at error level and by `GitClientError.logDescription` where the error is git's.
## Platform Notes

- **SwiftUI**: a `WindowGroup(for: URL.self)` with a `NavigationSplitView`; this toolkit's windows are AppKit.
- **Compose**: not applicable (desktop git windows only).
- **React/Web**: not applicable.
- **AppKit / UIKit**: AppKit: `@MainActor public final class GitWindowFeature: AppFeature`, `public final class GitWindowController: SingleWindowController`, `GitWindowSplitViewController: ThemedSplitViewController`, the toolbar from `WindowToolbarBuilder`, all in `AgenticDeveloperHubSDKMacOS` (`macOS/Features/Git/Window/`). The window spec persists the frame only: the keyed window set, not the window manager, decides what reopens. UIKit: not applicable.
- **WinUI 3**: a window with a `SplitView`.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Window/` | confirmed (1.0.1) |

## Design Decisions

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
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| adc.check.best-practices.separation-of-concerns | passed | Best Practices |
| adc.check.best-practices.unit-test-coverage | passed | Best Practices |

`separation-of-concerns` passes because the feature owns windows and the highlighter, the controller only routes between views it does not implement, and the views keep their own logic. `unit-test-coverage` passes: `GitWindowFeatureTests` covers canonical keys, one window per key and the refusal of a non-repository, and `BranchControllerTests` the branch card's command; the views and the model have their own suites.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Selection and the bottom pane follow model changes; per-repository autosave; override names mapped through the registry |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
