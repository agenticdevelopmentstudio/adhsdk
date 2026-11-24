---
id: 6a830cf8-0b95-4ffd-b175-f5cf481490c4
title: "Git Window"
type: ingredient
version: 2.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-16
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "One window per repository, keyed by its canonical top level: the overview (refs sidebar), the history or the working copy, and the commit detail over the diff with terminals under it, on the project window's composable-tabs layout; the feature that opens, remembers and restores those windows, shares one syntax highlighter between them and registers the commands that open them."
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
  - 7f1b8bef-e78e-4cac-be55-c948fe9062e5
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

A git window shows one repository. `GitWindowFeature` owns every git window: it turns any directory inside a repository into the repository's canonical top level, keeps one window per top level, a `.gitWindow` row kept by the [standalone window rows](cookbook:7f1b8bef-e78e-4cac-be55-c948fe9062e5) the File Browser and Document windows share, which remember which were open so they reopen at launch, builds one [syntax highlighter](cookbook:6708bfd4-5b29-4bf9-b180-05904873906e) for all of them from the [TextMate resources](cookbook:add92e9b-94e5-412c-970f-5ea8e2eb9eed), and registers the two commands that open a window (with a chooser, or on a given path) and the File > New menu item.

A Git window is the project window's `ComposableTabsWindowController` over a `.gitWindow` row of the projects database, opened by `ProjectWindowManager.openStandaloneWindow` with no tab bars and the fixed panes of `GitWindowPanes`. Its state is one `GitWindowSession`: a [repository model](cookbook:a2394ca0-3988-410b-9fc8-e0c9e253fc94) on its top level, kept current by a watcher, and the [git views](cookbook:bdd3a72d-8810-439b-bad7-ec16233cb2a3) in three panes: the overview (the refs sidebar, with Refresh and the busy spinner in its title bar); the history, or the working copy while the sidebar's Working Copy row is selected; and the commit, the commit detail over a bottom pane that shows the diff and swaps to a blame or a file history on request, with a terminal region under it when the host gives terminals. The session routes every view's delegate call to the view it concerns, so no view knows another. The window's search field reaches the history through its pane, and the toolbar carries, ahead of it, the six verbs of `GitWindowToolbar` (Fetch, Pull, Push, Branch, Stash, Pop), which forward to the session's actions.

The branch card's [branch management](cookbook:92f11498-2cb2-4b04-92b9-560d9f2de6ee) offers "Open in Git Window" when the open-for-path command is registered.
## Behavioral Requirements

### Feature

- **window-key-canonical**: A window's key MUST be the repository top level `GitClient.topLevel(of:)` reports for the requested path, standardised and with symlinks resolved, so a subdirectory, the root, and a symlinked spelling of either open one window.
- **one-window-per-key**: Opening a key that already has a window MUST return that window's controller and MUST NOT build a second; with `activates` true it brings the window forward and activates the app unless presentation is quiet, with `activates` false it leaves the window where it is.
- **non-repository-refused**: Opening a path that is not inside a repository (or does not exist) MUST log the client's failure by `GitClientError.logDescription(of:)` and return nil, opening nothing and remembering nothing. When the path is the folder the user chose in New Git Window…, the feature MUST also tell them: an informational alert `<folder name> is not in a Git repository` with one OK button, shown in its own window (there is none to attach a sheet to) without a modal loop and without activating the app, ordered front, and made key only when presentation is not quiet; OK closes it, and a second such alert replaces the first. The open-for-path command and the branch card only log.
- **open-windows-remembered**: The keys of open windows MUST persist in `open_git_window_roots` in the order first opened; a window the user closes MUST be forgotten, and its `.gitWindow` row and saved frame deleted a turn later (`StandaloneWindowRows.discard`); a window closed while the app terminates MUST NOT be.
- **restore-quietly**: `restoreOpenWindows()` MUST forget every remembered key that is no longer a repository's top level (a directory holding `.git`), then delete every `.gitWindow` row whose path is not remembered (`discardForgottenRows`), then reopen every remembered key without activating the app, forgetting one that does not open. With no layout it MUST restore nothing and forget nothing. Opening a window that is already open without activating MUST return it where it is, neither shown nor ordered front.
- **shared-highlighter**: Every window MUST share one `GitSyntaxColoring`, built on the first window over a grammar registry whose sources are, in order, the user grammars directory, the extensions' grammars (a snapshot taken then), and the bundled grammars.
- **missing-resources-uncoloured**: When the TextMate resources are missing (nil) or the highlighter cannot be built, the feature MUST log it once and every window MUST show code uncoloured.
- **file-type-override-validated**: The injected file-type override MUST be consulted for a file's language, and the name it returns (the File Types mapping stores display names such as `C++` or `Shell Script`) MUST be mapped to a language id through the grammar registry's ids and aliases, exactly or with spaces and punctuation other than `+` and `#` dropped; a name the registry cannot map falls through to the name and extension rules.
- **commands**: The feature MUST register `git.action.openWindow` (asks for a folder, then opens it) and `git.action.openWindowForPath` (opens its first argument, a path string; no argument or a non-string does nothing), and contribute File > New > `New Git Window…` at order 45 bound to `git.action.openWindow`; it MUST also register **undo-command**.

### Window

- **window-identity**: The window MUST be the project window over the key's `.gitWindow` row (inserted the first time, named after the top level's folder), so its id is the project window's `projectWindow.<row id>`; its title MUST be `Git: <name> → <branch>`, or `Git: <name>` before the branch is known or with none (a detached HEAD), read again after every refs change.
- **layout**: The content MUST be the `GitWindowPanes` layout: overview | (history | right), each Git pane fixed and one of its kind, where right is the commit pane alone, or, with terminals, the commit pane over a terminal region that offers the host's terminal family and the Command Log (`git.commandLog`, "Command Log", `list.bullet.rectangle`, at most one, the session's `GitCommandLogViewController` over the repository's top level and its worktrees) and always keeps one terminal. Inside the commit pane the commit detail sits over the bottom pane (diff, blame or file history) in a horizontal-divider split, `git.window.right`, autosaved once per repository (its autosave name carries the top level's path).
- **centre-follows-sidebar**: The centre MUST show the working copy while the sidebar's Working Copy row is selected (including when the sidebar falls back to it after its selection vanished), and the history otherwise.
- **ref-scrolls-history**: Selecting a branch or tag MUST show the history and select the ref's target commit there; when the commit is not loaded, nothing is selected and the selection is applied after a later history change loads it.
- **reflog-row**: The sidebar's Workspace section MUST hold a `Reflog` row (`git.sidebar.reflog`, `clock.arrow.circlepath`) after Working Copy, with no menu. Selecting it MUST show the [reflog browser](cookbook:bdd3a72d-8810-439b-bad7-ec16233cb2a3) in the centre (titled `Reflog`) over HEAD's newest 200 entries, clear the commit detail and the diff, and reload the entries on every refs or history change and on Refresh while it stays selected, the newest read superseding an older one; selecting an entry MUST load its commit into the detail. Its menu's intents run through the funnel: Soft and Mixed resets at once, Hard after the same confirmation as **commit-actions**, Check Out (detached) as `.checkoutDetached`, and Create Branch Here… asking for the name as New Branch does. A search typed while it is selected first selects the checked-out branch, as over the working copy.
- **stash-shows-commit**: Selecting a stash MUST show the history and load the stash's commit (`git log` of the stash id, one commit) into the commit detail; a failed load is logged and shown as a plain error label.
- **directory-opens-window**: Choosing a submodule or worktree row, or its menu's `Open` (`.openDirectory`), MUST open (or bring forward) that directory's own git window through the feature (`onOpenDirectory`). `Open` runs no git, so it bypasses the funnel and works while an action runs.
- **history-selection-shows-detail**: A commit selected in the history MUST be shown in the commit detail, and the bottom pane MUST return to the diff and clear.
- **file-shows-diff**: A file chosen in the commit detail MUST show the diff `.commit(<id>, paths:)` for that file (its old path too, for a rename); a file cleared MUST clear the diff.
- **working-copy-target**: While the working copy is the centre, a working-copy selection MUST show its target's diff and nil MUST clear it.
- **blame-and-history**: Blame or History requested from the diff (or from the file history's own diff) MUST swap the bottom pane to the blame of that path at that revision, or the file history of that path; choosing a commit in the blame, or a parent link in the commit detail, MUST select that commit in the history.
- **refresh-reapplies-selection**: After each model change the window MUST reload the views the change concerns (refs: sidebar; history: history; working copy or operation: working copy) and only then re-check its own selection, once per change: a ref whose target moved re-selects the new target, counted as applied only once the history holds and selects that commit (so a commit picked by hand survives a Refresh that moved nothing), a stash whose id changed reloads it, and one that vanished leaves the sidebar's fallback in charge. The bottom pane MUST follow too: a working-copy diff or a blame of the working file reloads on a working-copy or operation change, and a file history reloads on a history change.
- **search-drives-history**: The history pane MUST be the window's searchable pane (placeholder `Search History`), and text searched there MUST be handed to the history's `setQuery(_:)` as typed; a search typed over the working copy first selects the checked-out branch, so the history it filters is the one on screen; on a detached HEAD, which has no branch row, it MUST show the history with no sidebar row selected.
- **refresh-button**: Refresh, a button in the overview pane's title bar after the busy spinner, MUST ask the model to reload every part, then reload the visible views, the bottom pane included, and re-check the selection without forgetting what was applied.
- **latest-call-wins**: Each asynchronous load the window starts (the subtitle, a stash's commit) MUST carry a generation the window owns, and a result for an older generation MUST be dropped.
- **close-stops-model**: Closing the window MUST cancel the running search and action (a cancelled action shows nothing), stop the model's watcher, drop the window's session and toolbar, and tell the feature, unless the app is terminating.
- **confines-to-ui-thread**: The feature and the window MUST be usable only on the UI thread.

### Agent sessions

- **sessions-provider-optional**: The feature MUST take an optional `GitSessionsProviding` (`sessions:`, default nil) and hand it to every window it builds; with nil (ADTerminal, tests, no daemon) no window shows any agent session, neither the commit detail's section nor the branch menu's submenu. The window MUST never write to the provider.
- **sessions-cache**: A window with a provider MUST keep one `GitAgentSessionCache` over its top level and its worktrees (read again at each fetch), read once when the model has started and again when the commit detail or a branch menu asks, at most once every 60 seconds and never while a read is in flight, each read covering the last 90 days. A read that changes the sessions MUST re-match the commit shown.
- **sessions-commit-branch**: The branch a commit is matched on MUST be the first local branch whose tip it is, else the selected sidebar ref when that is a local branch, else unknown; its date is the committer date.
- **sessions-open**: The feature's `onOpenAgentSession` MUST reach every open window's commit detail and refs sidebar, and every window built later; nil leaves the sessions shown but unclickable.

### Reviews

- **reviews-provider-optional**: The feature MUST take an optional `GitReviewsProviding` (`reviews:`, default nil) and hand it to the repository model of every window it builds; with nil no window shows a review, neither a history badge nor the commit detail's section, and nothing listens for changes. The window MUST never write to the provider; in the Kitchen it is `PartnerGitReviews` over the Coding Partner's store, built only when that store opened.
- **reviews-lookup**: A window with a provider MUST give its commit detail a `reviewLookup` that answers from the model's cache and, on a miss, asks for that commit in add mode, and MUST re-read the detail's review on every `.history` change, so a review that lands shows without reselecting.
- **reviews-changes**: A window with a provider MUST listen to the provider's `changes()` from start until `stop()`, and on each tick invalidate the model's reviews, ask again for the history's visible rows and ask again for the commit the detail shows; what is shown stays until its new value lands.
- **reviews-open**: The feature's `onOpenReview` MUST reach every open window's commit detail and every window built later, and only while the window has a provider; nil leaves the section shown without its `Open in Coding Partner` button. In the Kitchen it shows the Coding Partner window (`coding-partner`) and selects the review's session when the review has one.

### Toolbar

- **toolbar-verbs**: The window's toolbar MUST carry, after the project window's title item and ahead of the search field and help, eight icon buttons in order: `git.toolbar.fetch` "Fetch" `arrow.down.circle`, `git.toolbar.pull` "Pull" `arrow.down.to.line`, `git.toolbar.push` "Push" `arrow.up.to.line`, `git.toolbar.branch` "Branch" `arrow.triangle.branch`, `git.toolbar.stash` "Stash" `tray.and.arrow.down`, `git.toolbar.pop` "Pop" `tray.and.arrow.up`, `git.toolbar.undo` "Undo" `arrow.uturn.backward`, `git.toolbar.commandLog` "Command Log" `list.bullet.rectangle` — that last one only when the window has a terminal region; built without terminals it carries the first seven — each the identifier as its accessibility identifier and the label as its tooltip.
- **toolbar-forwards**: Each button MUST be aimed at the window's `GitWindowToolbar`, which forwards it to its session's verb (`fetch`, `pull`, `push`, `newBranch`, `stash`, `popStash`, `undo`), so it goes through the one funnel; with no session a button does nothing. Push is the HEAD push of **push-remote**.
- **toolbar-command-log**: The Command Log button MUST call the session's `toggleCommandLog()`, which runs no git: with the Command Log in the terminal region it closes that pane; otherwise it splits the region's last pane to its right with the Command Log. A window built without terminals has no such button (toolbar-verbs); called there anyway, it does nothing.
- **toolbar-undo**: Undo MUST always be in the toolbar and never removed. It MUST be disabled while the session's model has no `undoTarget` — the undo state's target (git-client **undo-state**: on a branch, that branch's own reflog; HEAD's only when detached; the first entry whose sha differs from the tip), nil while an operation (merge, rebase, cherry-pick, revert) is in progress or any path is unmerged — and its tooltip MUST be `Undo <action>: <message>` from the undone entry (git-client **undo-state** `undoneEntry`: the entry just before the target, the step Undo takes back), `Undo <action>` when the message is empty, and `Undo` with none (no target, or the reflog lags the tip), both kept current by an observation of the model. The model reads the undo state with the refs. Pressed, it MUST re-read the undo state, the operation and the tree from git through `GitClient`, off the main thread (`undoPreflight`); when the ref, its tip or the target differs from what the model showed, or there is no target now, it MUST refresh the refs, working copy and operation and do nothing else. Otherwise it MUST reset to the target's sha through the funnel with the preflight's `resetMode` (`.reset(commit:mode:)`: `.soft` while anything is staged, so what is staged stays staged and the undone commit's changes join it; `.mixed` otherwise), at once when the fresh status is clean; with staged or unstaged changes it MUST first confirm `Undo "<message>"?` (`Undo <action>?` when the message is empty, `Undo the last change to <branch>?` with no undone entry) / `HEAD moves to <short sha>; the undone changes are staged with what is already staged.` (soft) or `HEAD moves to <short sha>; changes stay in the working copy.` (mixed) with the action `Undo`, not destructive, and do nothing when declined. After a confirmation it MUST read the preflight again, and when that differs from the one confirmed, refresh and do nothing else. With no target it does nothing. A second Undo right after one undoes the `reset` it made, so it redoes the first; its tooltip says `Undo reset: moving to …`.
- **undo-command**: The feature MUST register `git.action.undoLastAction`, "Undo Last Git Action" (category Git), enabled while the key (or main) Git window's model has an `undoTarget`, which runs that window's `undo()`, and contribute it to the top-level Git menu (slot `.git`, after AI and before Window, ids `menu.git.*`) as `Undo Last Git Action` at order 10; with no Git window key it does nothing.
- **toolbar-lifetime**: The feature MUST make the toolbar before the window, keep it beside the window's session by the row's id (the buttons hold it weakly, it holds the session weakly), point it at the session once the layout has made it, and drop it when the window closes; the session's presenter is a `GitAlertPresenter` over the window, set at the same moment.

### Asking the user

- **presenter-seam**: The window MUST ask the user only through `GitActionPresenting` (`confirm`, `askForText`, `showFailure`, `editRebase`), never through `NSAlert` directly, so a test answers with a fake.
- **sheets-only**: `GitAlertPresenter` MUST show each question as an `NSAlert` sheet on the window its provider returns (`beginSheetModal`, bridged to `async` with a checked continuation); it MUST NOT run a modal loop or activate the app. With no window it MUST log at error level and answer as cancelled: `confirm` false, `askForText` nil, `showFailure` nothing shown. When the window closes while a sheet is up, the sheet MUST be ended and the question answered as cancelled, so the caller always resumes, exactly once.
- **confirm-buttons**: A confirmation MUST have the action button first and Cancel second, and answer true only for the first; a destructive one MUST set `hasDestructiveAction` on its first button.
- **text-fields**: A text request MUST stack one `NSTextField` per field in the alert's accessory view, labelled with the field's label and filled with its initial text and with no placeholder, the first field focused; it MUST answer one value per field, trimmed of whitespace and newlines, or nil when cancelled.
- **text-action-enablement**: The action button MUST be enabled exactly while `GitTextRequest.isComplete(_:)` holds for the fields' current text: every non-optional field holds something other than whitespace (and there is one value per field). It MUST be re-checked on every keystroke.
- **rebase-editor-sheet**: `editRebase(_:)` MUST show the [rebase editor](cookbook:241d5e8b-3395-4093-ad77-1e138b7fe3a1) on the plan as a sheet on the window (an `NSWindow` titled `Interactive Rebase`, `git.rebase.sheet`, over a `GitRebaseEditorViewController`), bridged to `async` like the alerts, and answer the edited plan when the editor finishes with one and nil when it finishes with nil. With no window it MUST log and answer nil; when the window closes under the sheet, the sheet MUST be ended, the editor's finish handler dropped, and nil answered, exactly once.
- **failure-sheet**: `showFailure(title:message:)` MUST show an informational sheet with one OK button and not wait for it. The message for a failed git call MUST be `GitClientError.userMessage(of:)`: git's trimmed standard error, else the error's description.

### Actions

- **one-funnel**: Every intent a view sends (working copy, history, refs sidebar, diff, operation banner) and every toolbar verb (`fetch`, `pull`, `push`, `newBranch`, `stash`, `popStash`) MUST go through the session's one `perform(_:)`, which runs git only through the model's `perform`; the model refreshes after every action, so the views show what it left.
- **one-at-a-time**: While an action runs, sheets included, a new request MUST be ignored. The overview's spinner (`git.window.busy`, before Refresh) MUST show and spin exactly while git runs, never while a confirmation or text sheet waits for an answer; `onBusyChange(true)` MUST be called as git starts and `onBusyChange(false)` as it returns.
- **failure-shown**: A failed action MUST call `showFailure` with the action's title (`Push failed`, `Commit failed`, `Cherry-pick failed`, ...) and `GitClientError.userMessage(of:)`; a cancelled one shows nothing. The log line MUST carry the title and `logDescription`, never git's standard error.
- **needs-presenter**: While `presenter` is nil, an action that needs the user (a confirmation or a text) MUST do nothing.
- **discard**: Discarding MUST confirm `Discard changes to N file(s)?` with the destructive action `Discard Changes`, then restore the tracked paths (`.discard`) and delete the untracked ones (`.removeUntracked`), as two actions when there are both, skipping the second when the first fails. Discard All discards every unstaged path the same way.
- **diff-patches**: A diff intent MUST build its patch with `GitPatchBuilder` and do nothing when there is none: `.stage` runs `.applyToIndex` of the forward patch, `.unstage` `.applyToIndex` of the reverse patch with `reverse: true`, and `.discard` first confirms `Discard N selected line(s)?` / `This cannot be undone.` with the destructive action `Discard`, then runs `.applyToWorktree` of the reverse patch with `reverse: true`. Their failures are titled `Stage failed`, `Unstage failed` and `Discard failed`.
- **commit**: A commit MUST run `.commit(message:amend:)` and, on success, call `commitDidSucceed()`: the message is emptied, its undo history cleared and Amend unticked. Ticking Amend over a message that is only whitespace MUST fill it with HEAD's message. Amend MUST be enabled exactly while HEAD resolves to a commit, re-read on every working-copy or refs change, so it is disabled on an unborn HEAD, an orphan branch beside others included.
- **push-remote**: The destination MUST be the one git resolves, never one the window derives from the upstream's name. The checked-out branch with an upstream MUST be pushed with a plain `.push`, so `push.default`, `branch.<name>.pushRemote` and `remote.pushDefault` apply, and a refusal MUST be shown under `Push failed` in git's words. Any other branch with an upstream MUST resolve `<branch>@{push}` (the client's push destination) and, when it splits against a listed remote at the longest remote name that prefixes it, be pushed with `.pushToUpstream` to that remote and branch with its tracking untouched; when git names no destination, or it names none on a listed remote, the window MUST show `Push failed` / `<branch> has no push destination.` followed by git's message, push nothing and change no tracking. A branch with an upstream MUST never fall back to `.pushSettingUpstream`: a branch made from `origin/main` tracks it, and pushing it onto `main` would land unreviewed work on a shared branch. Only a branch with no upstream MUST be pushed with `.pushSettingUpstream` under its own name to `origin`, else the only remote; with none it MUST show `Push failed` / `This repository has no remote.`, and on a detached HEAD `Push failed` / `HEAD is not on a branch.`. Only remotes that have a URL count. Push Tag picks its remote the same way.
- **pull-fetch**: Pull MUST run `.pull`; the toolbar's Fetch MUST run `.fetch(remote: nil)`, the sidebar's Fetch of a remote `.fetch(remote:)` for it.
- **new-branch**: New Branch (toolbar, ref menu, commit menu) MUST ask one required field `Name` with the action `Create Branch`, then create the branch at the ref's full name, the commit's sha, or HEAD from the toolbar, and check it out.
- **names-validated**: A typed branch or tag name beginning with `-` MUST be refused before git runs, with `A name cannot begin with “-”.` under the action's failure title.
- **checkout**: Checking out a local branch MUST run `.checkout(name)`; a remote branch `.checkout` of the local branch already tracking it, else `.checkoutTracking("<remote>/<name>")`; a commit or a tag `.checkoutDetached(sha)`.
- **rename-delete**: Rename MUST ask one field prefilled with the branch's name and run `.renameBranch` unless the name is unchanged. Deleting a local branch MUST confirm (destructive), run `.deleteBranch(force: false)` and, when git answers `not fully merged`, confirm again (`Delete unmerged branch?`, destructive) before `.deleteBranch(force: true)`; declining shows nothing. Deleting a remote branch MUST confirm (destructive), then run `.deleteRemoteBranch`.
- **tags**: New Tag MUST ask `Name` (required) and `Message` (optional; empty makes a lightweight tag) and run `.createTag`; Delete Tag MUST confirm (destructive), then `.deleteTag`.
- **stashes**: Stash MUST ask one optional `Message` and run `.stashSave`; the toolbar's Pop MUST run `.stashPop(0)` when there is a stash and nothing otherwise; the sidebar's Apply, Pop and Drop MUST act on the stash the menu named, found again by its sha in the current stash list just before git runs, so a stash pushed or dropped meanwhile by another tool never shifts the target; a stash that is gone MUST fail under the action's title with `That stash no longer exists.` and run nothing. Drop MUST confirm (destructive).
- **merge-rebase**: The sidebar's `.merge(ref)` MUST run `.merge(ref: <full name>, fastForward: .allowed)` and `.rebaseOnto(ref)` `.rebase(onto: <full name>)`, at once: the menu or the drop menu the user chose from is the confirmation. A conflict fails under `Merge failed` or `Rebase failed` and leaves the operation in progress, which the refresh shows in the banner and the working copy.
- **operation-steps**: A banner step MUST run `.operation(<kind>, <step>)` for the kind the model's `operationState` names, and nothing while it is `.none`. Abort MUST first confirm `Abort the <verb>?` / `The working tree and the branch go back to how they were before it started.` with the destructive action `Abort`, and needs the presenter; Continue and Skip run at once. A failed step is shown under its own title (`Continue rebase failed`, ...) and leaves the operation, and so the banner, in place.
- **interactive-rebase**: The history's `.interactiveRebase` on a commit MUST build the plan with the model's `rebasePlan(onto: <sha>)`, then fill every entry's message from one `commitMessages(after: <onto>)` call, both while git runs; either failing MUST show `Interactive rebase failed` and present nothing. It MUST then ask the presenter's `editRebase` (and needs the presenter), run nothing when it answers nil, and otherwise run `.interactiveRebase(<edited plan>)` at once, failing under `Rebase failed`. A stop (a conflict, an `edit`) leaves the rebase in progress, which the banner shows.
- **worktrees**: `.newWorktree(branch:)` MUST ask `New Worktree` with two fields, `Branch` (required, prefilled with the branch's name, or empty from the header) and `Folder` (optional, empty), action `Create Worktree`; a branch beginning with `-` is refused as in **names-validated**. An empty folder MUST become `<parent of root>/<root's name>-<branch with every "/" replaced by "-">`; a typed folder has `~` expanded, and a relative one is taken against the parent of root. A branch that names an existing local branch MUST run `.addWorktree(path:branch:createBranch: false, startPoint: nil)`, any other `createBranch: true` from HEAD (`startPoint: nil`); on success the new worktree MUST open in its own window through `onOpenDirectory`, and a removed worktree's window, when one is open, MUST close through `onRemoveDirectory` (handed the folder's canonical path, spelled before it was deleted), as a close by the user. `.removeWorktree(worktree)` MUST confirm `Remove worktree <name>?` / `Its folder, <path>, is deleted.` with the destructive action `Remove`, then run `.removeWorktree(path:force: false)`; when git refuses because the tree is dirty (standard error contains `contains modified or untracked files`) it MUST confirm again `Remove worktree with uncommitted changes?` / `Its uncommitted changes and untracked files are lost.` (destructive `Remove`) before `.removeWorktree(force: true)`; declining shows nothing. Failures show under `Add worktree failed` and `Remove worktree failed`.
- **submodules**: `.updateSubmodule(submodule)` MUST run `.updateSubmodules(paths: [<its path>], initialize: <its state is .uninitialized>)` and `.updateAllSubmodules` `.updateSubmodules(paths: [], initialize: true)`, both at once; failures show under `Update submodules failed`.
- **banner-follows-model**: The banner's state MUST be the model's `operationState` at session start, on every change that touches `.operation` or the working copy, and on `reloadAll`, so an operation begun outside the window shows once the model reads it.
- **ref-drop-on-history**: A ref dropped on the history list MUST pop up the sidebar's `dropMenu(forRefNamed:)` over the history table through the sidebar's `menuPresenter`; a ref with no drop menu is refused by the history's `refDropValidator` and pops up nothing.
- **commit-actions**: Cherry-pick and Revert MUST pass `mainline: 1` for a commit with more than one parent. A soft or mixed reset MUST run at once; a hard one MUST confirm `Reset <branch> to <shortID>?` / `Uncommitted changes are lost.` (destructive) first, naming `HEAD` when detached, where a reset is allowed.
- **conflicts-resolve**: Resolve Using Ours… and Resolve Using Theirs… MUST confirm `Resolve N file(s) using ours?` (or theirs) / `Their changes to it are lost.` (`Our changes`, `them` for several) with the destructive action `Use Ours` or `Use Theirs`; declined, nothing runs. Confirmed, a path whose chosen side exists (`GitConflictKind.hasOurs` / `hasTheirs`) runs `.resolve(paths:side:)` then `.stage(paths:)`; one whose chosen side is a deletion runs `.removePaths`. Mark Resolved MUST run `.stage(paths:)` at once. Discard All MUST leave conflicted paths out. Stage All MUST stage only what the Unstaged list shows: with no conflicts `.stageAll`; with conflicts `.stage(paths:)` over the unstaged paths that are not conflicted (literal pathspecs), and nothing at all when none are left, so no conflict is marked resolved with its markers in it.
- **merge-view**: `.openMerge(path)` MUST read the working file (`contents(path:at: nil, maximumBytes: GitMergeViewController.maximumFileBytes)`, 1 MiB), decode it as UTF-8 and parse it into a `GitConflictDocument` off the UI thread, then show it in the bottom pane's merge view; a file over the cap, or one that does not decode or parse, shows its `.conflicted(path:)` diff instead, and a failed read fails under `Open failed`. Opening is a read, so it MUST NOT go through `perform` or be dropped while an action runs (`isActing`); each open, and every later selection that points the bottom pane elsewhere (`showDiff`, `clearDiff`), MUST supersede an open still reading, whose result (merge view, fallback diff or failure) is then dropped, so the bottom pane always follows the latest selection. The merge view's `.save(path:text:)` MUST write the text through the model's `writeResolution` (`Save failed` on error), then run `.stage([path])`, then return the bottom pane to the diff; `.cancel` returns it at once. Neither confirms. When a model change leaves the shown path no longer conflicted, the bottom pane MUST return to the diff.

### Pull requests

- **pull-requests-wiring**: `GitWindowFeature(gitHub:)` MUST give every window's session a `GitPullRequestsModel` over the one shared `GitHubCLI`; nil (the default) leaves the Pull Requests section absent. `gh` is the user's own: the Kitchen stores no token, reads none of `gh`'s files, and passes no host or token.
- **pull-request-open**: Open in Browser MUST open the URL through `NSWorkspace` with `activates = true` (the browser comes forward, never the Kitchen) and run no git or `gh`.
- **pull-request-checkout**: Check Out MUST run `gh pr checkout <number>` through `perform`, then refresh `.refs` and `.workingCopy` whether it succeeded or not (the new checked-out branch reloads the list); a refusal (a dirty tree) is shown in git's words.
- **pull-request-create**: Create MUST ask the form; Cancel runs nothing. The form waits on the user, so the refs MUST then be read again: when the checked-out branch is no longer the one the form was filled from, nothing runs and it reports `Pull request failed: The checked-out branch changed while the form was open.` A branch with no upstream, or ahead of its upstream, is pushed first through the push action (setting the upstream when there was none), and nothing is created unless the branch then has an upstream and is not ahead of it. Then `gh pr create --title --body [--base] [--draft]` runs with the form's values and no `--head` (a bare name means a branch in the base repository, which breaks a fork or an upstream named differently; `gh` takes the head from the checked-out branch's upstream, which the re-read above proved is the form's branch), the list reloads, and the new pull request's row is selected. Nothing confirms.
- **pull-request-failure**: Every pull-request failure MUST show under `Pull request failed` (not a `GitAction` title): `gh did not answer in time.` for a timeout, `gh`'s own words for a failure, and the list is left as it was.

## Appearance

The project window's frame and unified toolbar: the project window's title item, then the six verbs, then the project window's search field (placeholder `Search History` while the history pane is the searchable one) and help. The title is `Git: <name> → <branch>`. Panes: the overview at least 230 points and about a fifth of the width, the history at least 260 and about half, the commit at least 240 (about 65 % of the right column's height when terminals sit under it); inside the commit pane the detail and the bottom pane are each at least 160 points high. The overview's title bar carries the busy spinner and Refresh (`arrow.clockwise`). Every pane is the git views' own, themed by them.
## States

- **Opening**: the window shows at once, empty, and fills as the model's first refresh lands.
- **Working Copy selected**: the centre is the working copy.
- **Stash load failed**: the commit detail is cleared and a plain error label shows the failure's description; selecting anything else hides it.
- **Repository deleted underneath**: the model keeps its last state and logs; the window keeps showing it until closed.
- **Highlighting unavailable**: diffs and blame show uncoloured text.
- **Editing a rebase**: the rebase editor's sheet is attached to the window; nothing runs until Start Rebase.
- **Asking**: a confirmation, text or failure sheet is attached to the window; the window's other controls wait behind it.
## Accessibility

The window keeps the project window's identifiers. Its panes carry `git.window.overview`, `git.window.centre` (the history pane) and `git.window.commit`; inside the commit pane the detail host `git.window.detail`, its error label `git.window.error`, the split `git.window.right` and the bottom container `git.window.bottom`; in the overview's title bar the spinner `git.window.busy` (label `Running`) and Refresh `git.window.refresh`; the toolbar's items, in order, the project window's title `project.toolbar.title`, then the verbs `git.toolbar.fetch`, `git.toolbar.pull`, `git.toolbar.push`, `git.toolbar.branch`, `git.toolbar.stash` and `git.toolbar.pop`, then the search field and help. Each pane container also names the view its content sits in, `<pane id>.content`, and its header stack, `<pane id>.stack`. The views inside keep their own identifiers. Its sheets carry `git.prompt.confirm`, `git.prompt.text` or `git.prompt.failure`, and the rebase editor's `git.rebase.sheet` (the editor keeps its own identifiers); their buttons `git.prompt.action`, `git.prompt.cancel` and `git.prompt.ok`; a text request's fields `git.prompt.field.<index>` (each with its label as accessibility label) inside `git.prompt.fields`. The not-in-a-repository alert's window carries `git.prompt.failure` and its OK `git.prompt.ok`.
## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-window-001 | window-key-canonical, one-window-per-key, window-identity | A temporary repository with a subdirectory `sub`; open `sub`, then the root, both with `activates` false; then close it | The same controller both times, over a `.gitWindow` row whose path is the canonical root; the title begins `Git: `; the remembered list holds that one path; after closing, the feature holds no session. |
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
| git-window-012 | search-drives-history | Two commits; a `sha:` search for the older one's prefix through the history pane's search, then a message search | The older commit is selected; then the model's query is the parsed message search and only the matching commit is listed. |
| git-window-013 | window-identity | `title(kind:name:directory:branch:)` for a Git window named `adkitchen` with branch `main`, then none; then a refs change in a session | `Git: adkitchen → main`, then `Git: adkitchen`; the refs change asks the window to read its branch again. |
| git-window-014 | file-type-override-validated | Names `C++`, `C#`, `Shell Script`, `bash`, an unknown name, a blank name | `cpp`, `csharp`, `shellscript`, `shellscript` (an alias), nil, nil. |
| git-window-015 | commands | Open Git Window for Path run with no argument, then with a number | No window opens and nothing is remembered. |
| git-window-016 | text-action-enablement | Fields `Name` (required) and `Message` (optional); values `["", "note"]`, `["   ", ""]`, `["v1", ""]`, `["v1"]` | Incomplete, incomplete, complete, incomplete. |
| git-window-017 | one-at-a-time | A clone of a bare remote; `fetch()` twice before the first ends | One busy cycle (`true`, `false`), the spinner shown during it and hidden after; the second request ignored. |
| git-window-018 | discard | A tracked file edited and an untracked file; discard both, confirmed | One confirmation `Discard changes to 2 files?`, destructive, `Discard Changes`; the tracked file restored, the untracked file gone, nothing unstaged. |
| git-window-019 | needs-presenter | No presenter; Discard All and New Branch | Nothing changes. |
| git-window-020 | commit | A staged change; commit `second` | HEAD's subject is `second`; the box is empty. |
| git-window-021 | commit | A commit `The subject\n\nThe body.`; Amend ticked over an empty box, then over `typed` | The box holds the commit's message, then still `typed`. |
| git-window-022 | push-remote | A repository with a commit and no remote, push | `Push failed`: `This repository has no remote.` |
| git-window-023 | push-remote | A detached HEAD, push | `Push failed`: `HEAD is not on a branch.` |
| git-window-024 | push-remote | A clone on a new branch with no upstream, push | The remote has the branch at HEAD; its upstream is `origin/<branch>`. |
| git-window-025 | checkout | A remote branch `origin/feature` with no local branch, checked out; then `origin/main`, tracked by `main` | HEAD is `feature` tracking `origin/feature`; then `main`. |
| git-window-026 | rename-delete | A branch with a commit on no other branch; delete, confirmed twice | Two confirmations, the second `Delete unmerged branch?` and destructive; the branch is gone; no failure. |
| git-window-027 | rename-delete | As 026, the second confirmation declined | The branch remains; no failure. |
| git-window-028 | failure-shown | `f.txt` changed differently on `main` and `side`; cherry-pick `side`'s tip onto `main` | One `Cherry-pick failed` failure; `f.txt` is listed as conflicted. |
| git-window-029 | commit-actions | A merge commit; revert it | No failure; the merged branch's file is gone. |
| git-window-030 | commit-actions | Two commits; a hard reset to the first declined, then a soft reset, then a hard one confirmed | One confirmation `Reset main to <shortID>?` and HEAD unchanged; then HEAD at the first commit with the second's file staged; then nothing staged and the file gone. |
| git-window-031 | sheets-only | A sheet begun on a window that closes before it ends | The sheet is ended once and the question answered as cancelled. |
| git-window-032 | names-validated | New Branch answered `-f` | `Create branch failed`: `A name cannot begin with “-”.`; HEAD unchanged. |
| git-window-033 | push-remote | `push.default=upstream`; a clone whose `feat` tracks `origin/feature`, a commit on it; push from HEAD, then another commit and push from the sidebar with `main` checked out | Both times `origin/feature` is at `feat`, the remote has no `feat`, and `feat` still tracks `origin/feature`. |
| git-window-034 | one-at-a-time | A tag; delete it, confirmed | While the confirmation waits the spinner is hidden and the action is running; one busy cycle (`true`, `false`) follows. |
| git-window-035 | rename-delete, tags | Delete a merged local branch; delete a tag | Each first confirmation is destructive. |
| git-window-036 | push-remote | `push.default=simple`; New Branch `topic` from `origin/main` (so it tracks it), a commit; push from HEAD, then from the sidebar with `main` checked out | Each push shows one `Push failed`, the second `topic has no push destination.`; the remote's `main` never moves and it has no `topic`; `topic` still tracks `origin/main`. |
| git-window-037 | push-remote | `push.default=current`; `pr` tracks `origin/pr` with `branch.pr.pushRemote=fork`, a commit on it; pushed from the sidebar with `main` checked out | `fork`'s `pr` is at `pr`; `origin`'s `pr` is unchanged; `pr` still tracks `origin/pr`; no failure. |
| git-window-038 | push-remote | `push.default=simple`; `loc` tracks the local `main` (`.`), a commit on it; push from HEAD, then from the sidebar | Two `Push failed` failures, the second `loc has no push destination.`; local `main` unchanged, no `loc` on the remote, `loc` still tracks `main`. |
| git-window-039 | toolbar-verbs | Build the window's toolbar items | The first seven identifiers are `project.toolbar.title`, then `git.toolbar.fetch`, `.pull`, `.push`, `.branch`, `.stash`, `.pop`, with their labels and symbols. |
| git-window-040 | toolbar-forwards | A session on a repository with one commit and no remote; press each button in turn, every question cancelled | Each press starts an action that finishes; Branch asks `New Branch`, Stash asks `Stash Changes`, Push shows `Push failed`. |
| git-window-041 | toolbar-lifetime | Open a window, then close it | While open, the toolbar's session is the window's session and Fetch's button targets the toolbar; after closing, the feature holds no toolbar. |
| git-window-042 | non-repository-refused | New Git Window… choosing a temporary directory that is not a repository, then a repository; and the alert for `/tmp/Downloads` | The user is told once, about the directory, and the repository opens its window without telling; the alert reads `Downloads is not in a Git repository`, has only `OK` (`git.prompt.ok`), and its OK closes it once. |
| git-window-043 | stashes | Stashes `older` and `chosen`; another tool pushes `newcomer`; Drop `chosen` from the menu built before it, confirmed | No failure; `older` and `newcomer` remain and `chosen` is gone. |
| git-window-044 | stashes | Stashes `gone` and `other`; `gone` dropped outside the window; Pop `gone` | `Pop stash failed`: `That stash no longer exists.`; `other` remains and the working tree is unchanged. |
| git-window-045 | close-stops-model | A push started, then the window's session stopped | The action is cancelled and shows nothing. |
| git-window-046 | commit | An empty repository; a commit; then `checkout --orphan fresh` | Amend disabled, then enabled, then disabled with HEAD resolving to nothing. |
| git-window-047 | layout | The layout spec without terminals, then with | Three fixed panes `git.overview`, `git.history`, `git.commit`, one each; then a terminal region under the commit pane that keeps at least one terminal. |
| git-window-048 | diff-patches | a file of two changed regions, unstaged; Stage Hunk of the first | `staged` lists the file and its staged diff has only that hunk. |
| git-window-049 | diff-patches | the same file wholly staged; Unstage Lines of the first hunk's lines | its staged diff has one hunk, the second. |
| git-window-050 | diff-patches | an unstaged inserted line; Discard Lines of it declined, then confirmed; then Discard Lines naming only a context line | `Discard 1 selected line?` / `This cannot be undone.` / `Discard` asked twice; the file is unchanged, then back to its committed text; nothing asked or run. |
| git-window-051 | merge-rebase | `main`, and `topic` one commit ahead; Merge into main of `topic` | nothing asked; `main` is `topic`; the banner is hidden. |
| git-window-052 | merge-rebase, operation-steps | `side` and `main` changing `f.txt` from one base, HEAD `side`; Rebase side onto main; Continue unresolved; resolve, add, Continue | `Rebase failed: …`, the banner `Rebasing side (1/1)` with Skip, `f.txt` unstaged; `Continue rebase failed: …` and the banner stays; then no failure, the banner hidden, `f.txt` resolved. |
| git-window-053 | operation-steps | the same conflicting rebase; Abort declined, then confirmed | `Abort the rebase?` / `Abort`, destructive; still rebasing; then the banner hidden on `side`. |
| git-window-054 | banner-follows-model | the same branches; `git cherry-pick main` run outside the window, then the model refreshes `.operation` | the banner shows `Cherry-picking <main's short sha>`. |
| git-window-055 | ref-drop-on-history | HEAD `side`; drop `refs/heads/side`, then `refs/heads/main`, on the history | nothing, refused; then one menu `Merge into side`, `Rebase side onto main`, a separator, `Cancel`. |
| git-window-056 | merge-view | a UU `f.txt` from merging `main` into `side`; open it, choose Ours for every conflict, Save | the merge view shown; nothing confirmed; the file equals `side:f.txt`; no conflicts; `f.txt` staged at stage 0, matching HEAD, so neither Staged nor Unstaged lists it; the diff back in the bottom pane |
| git-window-057 | merge-view | the same conflict with its markers overwritten; open it | the diff shown, no failure |
| git-window-058 | conflicts-resolve | Mark Resolved on a hand-merged UU file | nothing confirmed; no conflicts; the file staged |
| git-window-059 | conflicts-resolve | Resolve Using Ours… declined, then confirmed | one destructive `Use Ours` confirmation and the conflict kept; then the file is ours, staged and listed nowhere |
| git-window-060 | conflicts-resolve | a UD `f.txt` (modified on `side`, deleted on `main`); Resolve Using Theirs…, confirmed | `Use Theirs`; no failure; no conflicts; the file gone from the tree and the index |
| git-window-061 | conflicts-resolve | Discard All over a UU `f.txt` and untracked `new.txt` | `Discard changes to 1 file?`; the conflict kept |
| git-window-062 | conflicts-resolve | Stage All over a UU `f.txt` and a modified tracked `other.txt` | nothing confirmed; `other.txt` staged; `f.txt` still unmerged and listed under Conflicts |
| git-window-063 | conflicts-resolve | Stage All over a UU `f.txt` alone | nothing runs; no failure; the conflict kept |
| git-window-064 | interactive-rebase | `base`, then `a.txt 20`, `b.txt 30`, `c.txt 40`; Interactive Rebase from Here on `base`, the editor swapping the last two | one plan shown, onto `base`, subjects and messages `a.txt 20`, `b.txt 30`, `c.txt 40`, all pick; no failure; the log after `base` is `a.txt 20`, `c.txt 40`, `b.txt 30` |
| git-window-065 | interactive-rebase | the same; the editor cancelled | one plan shown; no failure; HEAD unchanged |
| git-window-066 | interactive-rebase | `base`, then `main.txt` and a `--no-ff` merge of `side`; Interactive Rebase from Here on `HEAD~2` | no editor; one failure `Interactive rebase failed: …` |
| git-window-067 | rebase-editor-sheet | `editRebase` with fake sheets: Start after moving the second entry up; Cancel; the window closing | the sheet `Interactive Rebase` (`git.rebase.sheet`) begun; the edited plan answered and the sheet ended once; nil; nil, the sheet ended once and the editor's finish handler gone |
| git-window-068 | worktrees, directory-opens-window | a repository `r` with one commit; New Worktree from the header answered `topic/x` and an empty folder | `New Worktree` with `Branch` empty and `Folder` empty; branch `topic/x` created; a worktree at `<parent of r>/r-topic-x`; `onOpenDirectory` called once with it; no failure |
| git-window-069 | worktrees | branch `side`; Check Out in New Worktree on `side`, the fields answered `side` and an absolute folder | `Branch` prefilled `side`; the worktree at that folder on `side`, no new branch |
| git-window-070 | worktrees | a linked worktree with an untracked file; Remove…, confirmed twice; then the same with the second declined | two confirmations, the second `Remove worktree with uncommitted changes?`, both destructive; the worktree gone; declined, it stays and no failure |
| git-window-071 | submodules | a clone whose submodule `lib` is uninitialized; Update on its row | `.updateSubmodules([lib], initialize: true)`; `lib` current, `lib/lib.txt` checked out |
| git-window-072 | merge-view | a both-modified conflict whose file, markers kept, is padded past `GitMergeViewController.maximumFileBytes` | Open in Merge View shows the diff; no failure. |
| git-window-073 | open-windows-remembered | open a repository's window, then close it | the row exists while open; the key forgotten at once; a turn later no `.gitWindow` row at that path. |
| git-window-074 | restore-quietly | remembered `[<missing dir>, <repo>]`; a `.gitWindow` row at a path not remembered; restore | remembered `[<repo>]`; the stray row deleted; one window open on the repository's row. |
| git-window-075 | restore-quietly | open a window quietly, order it out, open the same repository quietly again | the same controller; the window still not visible. |
| git-window-076 | search-drives-history | a detached HEAD, the window on the working copy; search `one` | the centre shows the history; the selection is the history; no sidebar row selected. |
| git-window-077 | worktrees | remove a clean linked worktree; remove a dirty one, declining then accepting the force | `onRemoveDirectory` gets the folder's canonical path once per removal and nothing when declined; the feature closes the window open on it and nothing for another path. |
| git-window-078 | worktrees | `worktreeFolder` for root `/work/app`, branch `topic/x`: ``, whitespace, `side`, `../elsewhere/side`, ` side `, `~/trees/side`, `/abs/side` | `/work/app-topic-x` twice, `/work/side`, `/elsewhere/side`, `/work/side`, `<home>/trees/side`, `/abs/side`. |
| git-window-079 | merge-view | UU `f.txt` and UD `gone.txt` from merging `main` into `side`; select `gone.txt`, then `f.txt` | `gone.txt`'s diff shows `base` and `kept on side` (its unstaged diff is empty); `f.txt` opens the merge view. |
| git-window-080 | merge-view | an AA conflict, `side` against `main`, diffed as `.conflicted` | a context line `side` and an added line `main`, against HEAD. |
| git-window-081 | merge-view | the conflicts of 079; select `f.txt` and at once `gone.txt`; then, with `isActing` true, select `f.txt` | the diff shows `gone.txt` and the merge view was never shown; then the merge view shows `f.txt`. |
| git-window-082 | toolbar-command-log | a layout with a terminal region; toggle; toggle | the region holds the terminal and the Command Log (the session's controller); then the terminal alone. |
| git-window-083 | toolbar-verbs | `GitWindowToolbar(showsCommandLog: false)` | the six verbs from `git.toolbar.fetch` to `git.toolbar.pop`, no `git.toolbar.commandLog`. |
| git-window-084 | sessions-cache | a provider answering one session; roots `/repo`, `/wt`; refresh at 0 s, 59 s and 60 s | one read at 0 s over `/repo`, `/wt` since 90 days before, one change; none at 59 s; a second read at 60 s and no second change. |
| git-window-085 | sessions-provider-optional | a feature built without `sessions:` | the commit detail has no `agentSessionMatches` and the sidebar no `agentSessionsOnBranch`. |
| git-window-086 | toolbar-verbs, toolbar-undo | a toolbar with and without terminals | `git.toolbar.undo` "Undo" `arrow.uturn.backward` between Pop and Command Log; seven items without terminals, Undo last. |
| git-window-087 | toolbar-undo | HEAD@{0} `commit (amend)` / `two`; none; `reset` with no message | tooltip `Undo commit (amend): two`; `Undo`; `Undo reset`. |
| git-window-088 | toolbar-undo | three commits, then the third amended; Undo on a clean tree | no confirmation; HEAD the pre-amend commit; nothing staged, the amend's file unstaged with the amended text. |
| git-window-089 | toolbar-undo | the same repository with `a.txt` edited; Undo declined, then confirmed | `Undo "c.txt amended"?` / `HEAD moves to <8 chars>; changes stay in the working copy.` (Undo, not destructive) twice; HEAD unmoved, then the pre-amend commit with `a.txt` and `c.txt` unstaged. |
| git-window-090 | toolbar-undo | a rebase stopped on a conflict; Undo | `undoTarget` nil; no confirmation; HEAD unmoved. |
| git-window-091 | reflog-row | the reflog entry for the pre-amend commit: Hard (declined), Create Branch Here… `from-reflog`, Check Out (detached) | `Reset main to <short sha>?` / `Uncommitted changes are lost.` and HEAD unmoved; `from-reflog` at the commit; HEAD detached there. |
| git-window-092 | toolbar-undo | three commits and an amend, then `switch -c feature`; Undo | ref `refs/heads/feature`, `undoTarget` nil; no confirmation; `feature` and `main` both at the old tip, HEAD on `feature`. |
| git-window-093 | toolbar-undo | three commits and an amend, then `reset HEAD`; Undo | the two newest entries at the tip; target the pre-amend commit; HEAD moves there. |
| git-window-094 | toolbar-undo | three commits and an amend; a commit made behind the model's back; Undo | no confirmation, no failure; HEAD the new commit; the model refreshed, its tip the new commit and its target the amend. |
| git-window-095 | undo-command | the feature's contributions | `Undo Last Git Action` in slot `.git` at order 10. |
| git-window-096 | reviews-provider-optional | a session built without `reviews:`; `onOpenReview` set | no review loader, no `reviewLookup`, no listening task; the detail's `onOpenReview` stays nil. |
| git-window-097 | reviews-lookup, reviews-changes, reviews-open | a provider answering HEAD `queued`; the detail shows HEAD; the answer becomes `done` and the provider ticks; then the button pressed | the detail shows `Queued`, then `Done` without reselecting, the provider asked at least twice; one `onOpenReview` with the review's id. |
## Edge Cases

- **Symlinked spelling**: `/tmp/r` and `/private/tmp/r` resolve to one key and one window.
- **Linked worktree**: its own top level, so its own window; the watcher watches its git directory and the common directory.
- **Submodule row**: opens the submodule's own window, keyed by its own top level.
- **Removing a dirty worktree**: git refuses; the second confirmation names the loss, and declining it leaves the worktree with no failure shown.
- **New worktree on a branch checked out elsewhere**: git refuses and the failure shows under `Add worktree failed`; the sidebar offers `Check Out in New Worktree…` only on branches checked out nowhere.
- **A relative or `~` folder for a new worktree**: `~` is expanded and a relative path is taken against the parent of the root, since git requires an absolute path.
- **Remembered root gone**: dropped at restore.
- **Remembered root no longer a repository**: dropped at restore, since it no longer resolves.
- **Detached HEAD**: the title names no branch (`Git: <name>`).
- **Two repositories open side by side**: each keeps its own commit-pane divider position.
- **A chosen folder in no repository**: the not-in-a-repository alert, nothing opened or remembered.
- **A stash moved underneath**: the sidebar's stash actions follow the stash by sha; a vanished one fails with `That stash no longer exists.`.
- **A repository path containing a newline**: the watcher reads each directory with its own `rev-parse`, so the path is not split.
- **Refresh with nothing changed**: a commit picked by hand in the history stays selected.
- **Fast typing in search**: the history view serialises queries; the window only forwards text.
- **Quick selection changes**: generations drop stale stash and subtitle loads; the views drop their own.
- **Removing a worktree whose window is open**: the removing window tells the feature, which closes the worktree's window as the user would, so its root is forgotten and its row deleted; a worktree removed outside the app leaves its window open, and at the next launch its root is no longer a repository and is dropped.
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
| `database` | `ProjectDatabase` | none | Where the windows' `.gitWindow` rows go. |
| `windows` | `ProjectWindowManager` | `.shared` | Opens the windows (`openStandaloneWindow`). |
| `terminals` | `TerminalPaneFamily?` | nil | The terminal panes under the commit pane; nil leaves the commit pane alone in the right column. |
| `notInRepository` | `(@MainActor (URL) -> Void)?` | nil | Tells the user a chosen folder is in no repository; nil shows the alert. A test seam. |
## Deep Linking

Not applicable: the window defines no URL scheme or route; scripts reach it through `perform command "git.action.openWindowForPath" with arguments {"<path>"}`.
## Localization

The menu item (`New Git Window…`), command titles, pane titles (`Overview`, `History`, `Working Copy`, `Commit`), the search placeholder `Search History`, `Refresh`, the not-in-a-repository alert and the folder chooser's `Open` button are English literals today; ref names and paths are shown verbatim.
## Accessibility Options

The panes follow the theme's fonts; the window adds no text of its own beyond the title and the pane titles.
## Feature Flags

Not applicable: the window contains no feature-flag reference.
## Analytics

Not applicable: the window contains no analytics call.
## Privacy

The window shows local repository data only and sends nothing anywhere; the remembered list holds local paths. Coding Partner reviews are read from the Partner store on this Mac and never written.
## Logging

Under the `Loggable` categories of `GitWindowFeature`, `GitWindowSession` and `GitDeferredRepositoryWatcher` (the last for its directories): a path refused as not a repository, a `.gitWindow` row that could not be recorded, an invalid layout, missing TextMate resources or a highlighter that cannot be built (once), a failed stash load, a failed action and a watcher that could not resolve its directories, each at error level and by `GitClientError.logDescription` where the error is git's. `GitAlertPresenter` logs, at error level, a question it could not show because there was no window.
## Platform Notes

- **SwiftUI**: a `WindowGroup(for: URL.self)` with a `NavigationSplitView`; this toolkit's windows are AppKit.
- **Compose**: not applicable (desktop git windows only).
- **React/Web**: not applicable.
- **AppKit / UIKit**: AppKit: `@MainActor public final class GitWindowFeature: AppFeature`, `GitWindowSession`, `public enum GitWindowPanes` (a `ComposableTabLayoutSpec` on `ComposableTabsLayout`), `GitWindowToolbar`, and `NotInRepositoryAlert`, all in `AgenticDeveloperHubSDKMacOS` (`macOS/Features/Git/Window/`); the window is a `ComposableTabsWindowController` from `ProjectWindowManager.openStandaloneWindow`. The keyed window set, not the window manager, decides what reopens. UIKit: not applicable.
- **WinUI 3**: a window with a `SplitView`.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Window/` | confirmed (2.0.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Window/GitWindowSession.swift` | confirmed (2.0.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Window/GitWindowSession+Actions.swift` | confirmed (2.0.0) |

## Design Decisions

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
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| adc.check.best-practices.separation-of-concerns | passed | Best Practices |
| adc.check.best-practices.unit-test-coverage | passed | Best Practices |

`separation-of-concerns` passes because the feature owns windows and the highlighter, the controller only routes between views it does not implement, and the views keep their own logic. `unit-test-coverage` passes: `GitWindowFeatureTests` covers canonical keys, one window per key and the refusal of a non-repository, and `BranchControllerTests` the branch card's command; the views and the model have their own suites.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 2.0.1 | 2026-11-16 | Mike Fullerton | Phase 4 final review: Undo's tooltip from the undone entry, a soft reset while anything is staged, a second preflight after the confirmation; Create Pull Request re-reads the branch after the form and passes `--head`. |
| 2.0.0 | 2026-11-16 | Mike Fullerton | The Command Log in the terminal region, and the toolbar's seventh button toggling it. |
| 1.10.4 | 2026-11-16 | Mike Fullerton | Opening the merge view on selection is ungated and only the latest selection lands (vector 081) |
| 1.10.3 | 2026-11-16 | Mike Fullerton | The merge view's fallback is the .conflicted diff (vectors 079-080) |
| 1.10.2 | 2026-11-16 | Mike Fullerton | Git window keeps its rows with StandaloneWindowRows: closed windows and forgotten rows are deleted, quiet lookups stay put, removed worktrees close their window, detached-HEAD search |
| 1.10.1 | 2026-11-16 | Mike Fullerton | Final review: word-emphasis budget, selection kept across reloads, non-ancestor rebase rows; reword field newlines, row heights, Move Up/Down; selectRows; merge view cap |
| 1.10.0 | 2026-11-16 | Mike Fullerton | Worktrees and submodules from the sidebar: New Worktree asks Branch and Folder (empty: beside the root), checks out an existing branch or creates one, and opens the new worktree; Remove confirms and asks again before forcing a dirty one; Update and Update All run updateSubmodules, initialising as needed; Open bypasses the funnel. |
| 1.9.0 | 2026-11-16 | Mike Fullerton | Interactive Rebase from Here: the plan built with every message filled from one call, the rebase editor shown as a sheet through the presenter's editRebase, the edited plan run, cancel runs nothing; vectors 064-067 |
| 1.8.1 | 2026-11-15 | Mike Fullerton | Stage All stages only the Unstaged list and leaves conflicts unmerged (git-window-062, 063) |
| 1.8.0 | 2026-11-15 | Mike Fullerton | Conflicts: Resolve Using Ours… and Theirs… confirmed, then resolved and staged or removed; Mark Resolved stages; Discard All skips conflicts; the merge view opened from the working copy, saved through the model and staged; vectors 056-061 |
| 1.7.0 | 2026-11-15 | Mike Fullerton | Merge and rebase from the sidebar's menus and drop menus without a confirmation; the operation banner's Continue, Skip and confirmed Abort through the funnel; the banner follows the model; refs dropped on the history; vectors 051-055 |
| 1.6.0 | 2026-11-15 | Mike Fullerton | Diff patches: diff intents through the funnel, staged and unstaged with `git apply --cached`, discarded with `git apply --reverse` after a confirmation; vectors 048-050 |
| 1.5.0 | 2026-11-14 | Mike Fullerton | Review fixes: describes the composable-tabs panes, the project-window id and title; the not-in-a-repository alert; stashes found by sha; close cancels the action; Amend off on an orphan branch; vectors 042-047 |
| 1.4.0 | 2026-11-14 | Mike Fullerton | Toolbar: Fetch, Pull, Push, Branch, Stash and Pop, aimed at the window's GitWindowToolbar and forwarded to the session's verbs; the toolbar kept beside the session and dropped on close |
| 1.3.0 | 2026-11-14 | Mike Fullerton | Push goes where git resolves it: the checked-out branch with an upstream by a plain push, any other by its `@{push}` without `--set-upstream`, failing when git names none, never falling back to setting an upstream; the spinner shows only while git runs; local branch and tag deletes confirm destructively |
| 1.2.0 | 2026-11-14 | Mike Fullerton | Actions: every intent and toolbar verb through one funnel, one at a time, with confirmations, failures and the busy spinner; only remotes with a URL count; a sheet ends when its window closes |
| 1.1.0 | 2026-11-14 | Mike Fullerton | Asking the user: the GitActionPresenting seam and GitAlertPresenter's confirm, text and failure sheets |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Selection and the bottom pane follow model changes; per-repository autosave; override names mapped through the registry |
| 1.0.0 | 2026-11-14 | Mike Fullerton | Initial creation |
