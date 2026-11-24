---
id: bdd3a72d-8810-439b-bad7-ec16233cb2a3
title: "Git Views"
type: ingredient
version: 1.14.2
status: review
language: en
created: 2026-11-13
modified: 2026-11-16
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The git window's AppKit views, each reading one data-source protocol of the repository model and reporting to an injected delegate: the refs sidebar (working copy, branches with ahead/behind, remotes by remote, tags, stashes, submodules, worktrees) the history list (graph, subject with ref badges, author, date, short sha; paging; search), the shared changed-files list, the commit detail (message, people, sha, parent links, changed files) and the working copy (staged and unstaged lists)."
platforms:
  - swift
  - macos
tags:
  - git
  - ui
  - sidebar
  - history
  - search
  - commit-detail
  - working-copy
depends-on:
  - a2394ca0-3988-410b-9fc8-e0c9e253fc94
  - ce223be3-818a-4310-b136-9e1e84e9af54
  - 595f1a5e-0f92-49c5-a980-af6f809be932
  - e3a2394d-d0d0-4495-bde4-59197f9d7866
  - 873f79b1-444d-4c2c-8a5f-4fc01cd9022e
  - 2cfe57f0-cdd4-4723-a6e0-2ce4f136ce7f
related:
  - 779ac6ea-9ef5-4fb0-8ed9-dc6b9d617344
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/ (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitHistorySearch.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitFileListItem.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Git Views

## Overview

The views of a git window: each one an AppKit view controller that reads one narrow data-source protocol of the [git repository model](cookbook:a2394ca0-3988-410b-9fc8-e0c9e253fc94) and reports what the user chose to a delegate, injected, so none of them knows its window or calls git. This recipe has one section per view. The **refs sidebar** (`GitRefsSidebarViewController`) lists, on the toolkit's [topic list](cookbook:ce223be3-818a-4310-b136-9e1e84e9af54), the working copy, the local branches, the remote branches grouped by remote, the tags, the stashes, the submodules and every non-bare worktree (the main one and the one the window is on included), with ahead/behind badges on branches that track an upstream and the checked-out branch in bold. Its row and remote-header context menus, and a double-clicked branch, send intents (`GitRefIntent`) to the delegate.
The **history list** (`GitHistoryViewController`) is a paged table of the [commit graph cell](cookbook:595f1a5e-0f92-49c5-a980-af6f809be932), the subject behind a [badge](cookbook:2cfe57f0-cdd4-4723-a6e0-2ce4f136ce7f) per ref at the commit, the author's [avatar](cookbook:e3a2394d-d0d0-4495-bde4-59197f9d7866) and name, the [relative date](cookbook:873f79b1-444d-4c2c-8a5f-4fc01cd9022e) and the short sha. It reads a `GitHistoryDataSource`, asks for the next page as the end of the list comes into view, and takes the window's search text through `setQuery(_:)`, which `GitHistorySearch.parse(_:)` (Foundation only, in `AgenticDeveloperHubSDKCore`) turns into a `GitLogQuery`. A row's context menu sends intents (`GitCommitIntent`) for that commit to the delegate and copies its sha.
The **changed-files list** (`GitFileListViewController`) is one list of `GitFileListItem`s (`AgenticDeveloperHubSDKCore`), each a status letter in its status colour, the file type's icon and the path (`old → new` for a rename), reused wherever the window lists files.
The **commit detail** (`GitCommitDetailViewController`) shows one commit's subject, body, author and committer with their avatars, dates, full sha with a copy button and its parents as links, over a changed-files list read from the `GitContentSource`'s diff of that commit; the latest `show(commit:)` always wins over a load still in flight.
The **working copy** (`GitWorkingCopyViewController`) shows the `GitWorkingCopyDataSource`'s staged and unstaged files in two changed-files lists and reports the selected file as the `GitDiffTarget` that shows its diff. Under them the **commit box** (`GitCommitBoxViewController`) holds the message, Amend and Commit. Staging, unstaging, discarding and committing are intents (`GitWorkingCopyIntent`) sent to the delegate, never git run by the view.
The **diff** (`GitDiffViewController`) shows one file's change for a `GitDiffTarget` on the toolkit's line viewer, inline (`GitInlineDiffModel`) or side by side (`GitSideBySideDiffModel`), with word-level emphasis and syntax colour from `GitSyntaxColoring`, which reads both sides' contents and highlights them with the TextMate highlighter. The **blame** (`GitBlameViewController`) shows a file's lines with the sha, author initials and date at the start of each commit's run, and the **file history** (`GitFileHistoryViewController`) lists the commits that changed a file beside a diff of the selected one's change to it.

## Behavioral Requirements

### Refs sidebar

- **sidebar-section-order**: The sidebar MUST list its sections in this order: `Workspace` (one row, `Working Copy`), `Branches` (local branches), one section per remote titled `Remotes · <remote>` (in the order each remote first appears in the refs), `Tags`, `Stashes`, `Submodules`, `Worktrees`. Rows keep the data source's order within a section.
- **sidebar-empty-sections-omitted**: A section with no rows MUST be left out, header included; `Workspace` always has its one row.
- **sidebar-row-titles**: A local branch or tag row MUST be titled with its name; a remote branch row with its name less the `<remote>/` prefix, or its whole name when nothing follows the prefix; a stash row with its message, or `stash@{N}` when the message is empty; a submodule row with its path; a worktree row with its directory's last path component. Bare worktrees MUST be left out.
- **sidebar-ahead-behind-badge**: A local branch row MUST carry a badge `↑n ↓m`, each half present only when its count is non-zero (`↑2 ↓1`, `↑2`, `↓1`), and no badge when both are zero. Other rows carry none.
- **sidebar-head-bold**: The checked-out branch's row MUST be emphasized (bold); no other row is.
- **sidebar-selection**: Selecting a row MUST call the delegate once: the working copy → `sidebarDidSelectWorkingCopy`; a branch, remote branch or tag → `didSelect ref`; a stash → `didSelectStash`; a submodule → `open directory` with the repository root joined with the submodule's path; a worktree → `open directory` with the worktree's directory. A submodule or worktree row is an action, not a place: after it opens, the previous selection, when there is one, is restored, so the same row can be chosen again. Clearing the selection calls nothing.
- **sidebar-reload**: `reload()` MUST rebuild every section from the data source's current values, keeping the selected row selected when its id is still present (by the topic list's restore-by-id) without calling the delegate. When the selected row is gone, the sidebar MUST select `Working Copy` and call `sidebarDidSelectWorkingCopy` once, so the owner never keeps showing a ref or stash that no longer exists.
- **sidebar-intents-only**: The sidebar MUST NOT run git. Every action chosen from a context menu, and a double-clicked branch, is one call of the delegate's `sidebar(_:didRequest:)` with a `GitRefIntent` (`checkout(GitRef)`, `createBranch(from:)`, `rename`, `delete`, `push`, `pull`, `fetch(remote:)`, `deleteTag`, `pushTag`, `applyStash`, `popStash`, `dropStash`, `merge(GitRef)`, `rebaseOnto(GitRef)`, `newWorktree(branch:)`, `removeWorktree(GitWorktree)`, `updateSubmodule(GitSubmodule)`, `updateAllSubmodules`, `openDirectory(URL)`); confirming a delete, a removal or a drop is the owner's. `delete` names a local or a remote branch alike; the ref's kind decides which git verb runs.
- **sidebar-menus**: A local branch row's menu MUST hold `Checkout` (`.checkout`), `Check Out in New Worktree…` (`.newWorktree(branch:)`, only while **sidebar-worktree-menus** allows it), `New Branch…` (`.createBranch(from:)`), `Rename…` (`.rename`), `Delete…` (`.delete`), a separator and `Push` (`.push`); on the checked-out branch `Checkout` and `Delete…` are absent and `Pull` (`.pull`) follows `Push`. A remote branch row's menu MUST hold `Checkout`, `New Branch…`, `Delete…`, a separator and `Fetch <remote>` (`.fetch(remote:)`). A `Remotes · <remote>` section header's menu MUST hold `Fetch` for that remote; the `Worktrees` and `Submodules` headers have the menus of **sidebar-worktree-menus** and **sidebar-submodule-menus**; no other header has a menu. A tag row's menu MUST hold `Push` (`.pushTag`) and `Delete…` (`.deleteTag`); a stash row's `Apply`, `Pop` and `Drop…` (`.applyStash`, `.popStash`, `.dropStash`). The working copy row and the main worktree's row have no menu. Each item carries the clicked row's ref or stash, never the selection's; the menus are built through the topic list's `itemMenuProvider` and `headerMenuProvider`.
- **sidebar-worktree-menus**: The `Worktrees` header's menu MUST hold `New Worktree…` (`.newWorktree(branch: nil)`, `git.sidebar.menu.newWorktree`). A worktree row other than the main worktree's MUST have a menu of `Open` (`.openDirectory(<its directory>)`, `git.sidebar.menu.open`) and, unless the worktree's directory is the data source's `root` (the window's own worktree), `Remove…` (`.removeWorktree(<the worktree>)`, `git.sidebar.menu.removeWorktree`). A local branch row MUST carry `Check Out in New Worktree…` (`.newWorktree(branch: <the ref>)`, `git.sidebar.menu.newWorktree`) right after its `Checkout` slot exactly while the branch is checked out nowhere: it is not HEAD and no worktree's `branch` names it.
- **sidebar-submodule-menus**: The `Submodules` header's menu MUST hold `Update All` (`.updateAllSubmodules`, `git.sidebar.menu.updateAllSubmodules`). A submodule row's menu MUST hold `Open` (`.openDirectory(<root>/<path>)`, `git.sidebar.menu.open`) and `Update` (`.updateSubmodule(<the submodule>)`, `git.sidebar.menu.updateSubmodule`).
- **sidebar-merge-items**: While the data source's `operationState` is `.none` and a local branch is checked out, the menu of every local branch, remote branch and tag row other than the checked-out branch MUST end its own items with a separator, `Merge into <head>` (`.merge(ref)`, `git.sidebar.menu.merge`) and `Rebase <head> onto <name>` (`.rebaseOnto(ref)`, `git.sidebar.menu.rebase`), placed before a local branch's `Push` and a remote branch's `Fetch`, after a tag's `Delete…`. During an operation, on a detached HEAD and on the checked-out branch they are absent.
- **sidebar-drag-drop**: A local branch, remote branch or tag row MUST drag its ref's full name through the topic list's `dragPayloadProvider`; no other row drags. A drop MUST be valid only onto the checked-out branch's row and only for a ref whose `dropMenu(forRefNamed:)` is not nil, and an accepted drop MUST pop that menu up through `menuPresenter`, after the drop returns. `dropMenu(forRefNamed:)` MUST be nil for an unknown name, HEAD itself, and whenever the merge items are absent; otherwise it holds `Merge into <head>` (`git.drop.menu.merge`), `Rebase <head> onto <name>` (`git.drop.menu.rebase`), a separator and `Cancel` (`git.drop.menu.cancel`, which sends nothing). Its items send the same intents as the context menu; choosing one is the confirmation.
- **sidebar-double-click**: Double-clicking a local or remote branch row MUST send `.checkout(ref)` through the topic list's `onDoubleClick`; the checked-out branch, and every other row, sends nothing.
- **sidebar-ui-thread**: The sidebar MUST be used on the UI thread.

### Operation banner

- **banner-text**: `GitOperationBannerViewController.statusText(for:)` MUST be nil for `.none` and otherwise `Merging <sha>`, `Rebasing <branch> (<step>/<total>)`, `Cherry-picking <sha>` or `Reverting <sha>`, each sha shortened to 7 characters; a part git did not record is left out with its space, and the count needs both step and total.
- **banner-visibility**: Setting `state` MUST hide the banner (`git.banner`) for `.none` and show it otherwise, with the status (`git.banner.status`) and `Continue` (`git.banner.continue`) and `Abort` (`git.banner.abort`); `Skip` (`git.banner.skip`) MUST show only while the state `allowsSkip`, so never for a merge. A state set before the view loads is shown when it does. The banner sits above the overview pane's sidebar and gives its height back when hidden.
- **banner-intents-only**: The banner MUST NOT run git. Each button is one call of the delegate's `banner(_:didRequest:)` with `.step(.continue)`, `.step(.skip)` or `.step(.abort)`; confirming Abort is the owner's.

### History list

- **history-columns**: The history list MUST show one row per data-source commit, in the data source's order, with these columns in order: `graph` (a `CommitGraphCellView` drawing the data source's graph row at the same index), `subject` (the ref badges, then the commit's subject), `author` (an `AvatarView` of side 18 showing initials, seeded by the author's email, with no picture URL, then the author's name), `date` (`RelativeDateFormatting.string(for:)` of the author date, with the absolute date and time, `date.formatted(date: .abbreviated, time: .shortened)`, as its tooltip) and `sha` (the commit's `shortID` in the theme's code font).
- **history-graph-width**: The graph column MUST be as wide as the widest loaded graph row (`width × CommitGraphCellView.columnWidth`), and never narrower than one graph column.
- **history-ref-badges**: The subject cell MUST carry one badge per ref the data source reports at the commit (`refs(at:)`), titled with the ref's name (`main`, `origin/main`, `v1`), ordered local branches, then remote branches, then tags, keeping the data source's order within a kind. A local branch is a filled badge in the accent colour; a remote branch an outlined badge in the accent colour; a tag an outlined badge in the warning colour. A commit with no refs has no badges.
- **history-selection**: Selecting a row MUST call the delegate's `history(_:didSelect:)` once with that commit; clearing the selection calls it once with nil. `select(commitID:)` MUST select the loaded commit with exactly that id, scroll it into view and call the delegate the same way; an id that is not loaded changes nothing.
- **history-reload**: `reload()` MUST re-read the data source: commits, graph rows, query, and the refs at each commit; rows and badges show only that snapshot until the next reload. A selected commit that is still loaded stays selected without a delegate call; a selected commit that is gone is deselected and the delegate is called once with nil, so the owner never keeps showing a commit that left the list.
- **history-paging**: When the table asks for a row in the last 50 loaded rows (index ≥ count − 50), the list MUST call the data source's `loadMore()` once, then reload, and MUST NOT call it again until the number of loaded commits or the data source's query has changed, so the end of the history does not loop and a new search whose first page is the same size still pages. The count and query are the ones as of the last `reload()`, so a data source that cleared its commits for a search in flight does not page.
- **history-search-parse**: `GitHistorySearch.parse(_:)` MUST be pure and return a `GitLogQuery` with the default revisions, limit and skip and at most one filter, from the text trimmed of whitespace: empty → no filter; `author:<x>` (prefix in any case) → `author` `x`; `sha:<x>` (prefix in any case) → no filter; `-S <x>` or `-S<x>` → `pickaxe` `x`; anything else → `messageGrep`, the whole trimmed text. A prefix with nothing after it is no filter. `GitHistorySearch.shaPrefix(_:)` MUST return the lowercased `x` of the `sha:` form and nil for every other form.
- **history-set-query**: `setQuery(_:)` MUST parse the text, and when the parsed query differs from the one the list last sent (applied or in flight; the data source's query before the first search), send it to the data source after a quiet period (`searchDelay`, 250 ms), cancelling the send it replaces, so a burst of keystrokes runs one `git log` and a superseded one is terminated rather than left to run. Cancelling the latest caller cancels its send, and the next call with that query sends it afresh; an older caller's cancellation never cancels a send a newer call shares. A parsed query equal to one still in flight MUST wait for that request rather than skip or resend it, because the data source takes a new query before its results arrive. The latest call then reloads. For the `sha:` form it MUST then select the first loaded commit whose id starts with the prefix (case-insensitively), as `select(commitID:)` does; no match selects nothing. A `setQuery` overtaken by a later one MUST NOT select.
- **history-intents-only**: The history list MUST NOT run git. Every action chosen from a row's context menu, except Copy SHA, is one call of the delegate's `history(_:didRequest:for:)` with a `GitCommitIntent` (`checkout`, `createBranch`, `createTag`, `cherryPick`, `revert`, `reset(GitResetMode)`) and the commit; confirming a hard reset is the owner's.
- **history-menu**: A row's context menu MUST hold, in order, `Checkout`, `New Branch…`, `New Tag…`, a separator, `Cherry-pick`, `Revert`, `Interactive Rebase from Here…` (`.interactiveRebase`, `git.history.menu.interactiveRebase`), a separator, a `Reset Current Branch to Here` submenu of `Soft`, `Mixed` and `Hard…` (`.reset(.soft)`, `.reset(.mixed)`, `.reset(.hard)`), a separator and `Copy SHA`. `Interactive Rebase from Here…` MUST be left out on the row whose sha is the source's `headCommit` (nothing after it to replay) and on every row while the source's `operationState` is not `.none`. It acts on the right-clicked row (`clickedRow`), not the selection, and leaves the selection alone; a click outside the rows shows no menu. The list does not know which rows are ancestors of HEAD, so `Interactive Rebase from Here…` is offered on any other row, a commit on another branch included; the rebase that follows replays HEAD's commits since that commit's merge base onto it. `Copy SHA` MUST put the commit's full sha on the list's `pasteboard` and send no intent.
- **history-ref-drop**: The table MUST accept a drag of the topic list's item pasteboard type onto a row, retargeted to `.on` that row, when `refDropValidator` answers yes for the dragged ref's full name (and while it is unset), and an accepted drop MUST call `onRefDrop` once with that name. The drop does not depend on the row it lands on.
- **history-ui-thread**: The history list MUST be used on the UI thread; every data-source call that waits is awaited, never blocked on.

### Changed-files list

- **file-list-item**: A `GitFileListItem` made from a `GitFileChange` MUST take its path and status and have no old path. One made from a `GitFileDiff` MUST take the diff's `path` (the new path, or the old one for a deleted file) and the status of its change (added `A`, deleted `D`, modified and type-changed `M`, renamed `R`, copied `C`), and an old path only for a rename or copy whose old path differs from its new one. Its `title` MUST be `<old> → <new>` when it has an old path and the path otherwise; its id is its path.
- **file-list-rows**: The list MUST show one row per item of `files`, in order, each with the status letter (`GitFileStatus.displayCharacter`) in the status's colour (`GitFileStatus.nsColor`), the SF Symbol `FileTypeIcons.builtInIcon(for:)` names for the path's extension (`doc` when it names none), and the title, truncated in the middle with the whole title as its tooltip.
- **file-list-selection**: Selecting a row MUST call the delegate's `fileList(_:didSelect:)` once with that item; clearing the selection calls it once with nil. `clearSelection()` MUST deselect without calling the delegate.
- **file-list-files**: Setting `files` MUST keep a selected item whose path is still listed selected without calling the delegate, unless the listed item differs (a new status), when it MUST call the delegate once with the new item; when the selected path is gone, the list MUST deselect and call the delegate once with nil.
- **file-list-ui-thread**: The changed-files list MUST be used on the UI thread.

### Commit detail

- **detail-header**: `show(commit:)` with a commit MUST fill the header at once: the subject (heading); the body, wrapped, hidden when empty; an author row and a committer row, each an `AvatarView` of side 28 showing initials seeded by the person's email with no picture URL, the name followed by `<email>`, and the date as `date.formatted(date: .abbreviated, time: .shortened)` with `RelativeDateFormatting.string(for:)` as its tooltip; the full sha in the theme's code font beside a copy button; and a parents row with one link per parent, in order, titled with the parent's first eight characters, hidden for a root commit.
- **detail-copy-sha**: The copy button MUST put the full sha on the pasteboard as a string, replacing what was there.
- **detail-parent-link**: Pressing a parent link MUST call the delegate's `commitDetail(_:didSelectCommit:)` once with that parent's full sha.
- **detail-files**: After the header, the detail MUST ask the content source for `changedFiles(commit: <sha>)` (the names and statuses only, never the patch, so a huge commit costs one name per file) and list them, in order, in its changed-files list (context `commit`); the one file the user selects is diffed on its own. Showing a different commit MUST empty the list at once, so it never lists another commit's files; showing the same commit again keeps the list (and its selection) until the new diff arrives. A diff that throws MUST be logged at error level by `GitClientError.logDescription` (never git's own output) and MUST leave the list empty with the error's description shown over it (`git.detail.error`, in the theme's danger colour), so a failure never reads as a commit with no changes; the next `show(commit:)` hides it, and a diff with no files shows no error.
- **detail-latest-wins**: The latest `show(commit:)` MUST win: a diff requested by an earlier call never changes the list, whichever order the diffs finish in. The check is the detail's own call counter, taken before it awaits, never state the content source changes; a failure from an earlier call is dropped the same way. Cancelling the earlier request only stops its work early: a cancelled request that still returns is dropped by the counter alone.
- **detail-file-selection**: Selecting a file MUST call the delegate's `commitDetail(_:didSelectFile:in:)` once with that item and the shown commit; clearing the selection, or a list change that removes the selected file, calls it once with nil.
- **detail-clear**: `show(commit: nil)` MUST empty the header and the list, hide a shown failure, collapse the header to no height, and cancel any diff in flight.
- **detail-ui-thread**: The commit detail MUST be used on the UI thread; the diff is awaited, never blocked on.

### Agent sessions

- **sessions-model**: An agent session (`GitAgentSession`) MUST carry the daemon's id, its title (nil when unnamed), its working directory, its branch (nil when unknown) and its start and last-activity dates; its display title is the title, or the id's first eight characters when there is none. Sessions come from a `GitSessionsProviding`, which answers the sessions under a list of roots active since a date and never throws; the Git views never write to it.
- **sessions-match-commit**: The sessions beside a commit MUST be those whose working directory is one of the roots (the repository's top level and its worktrees) or under one, compared by path component so `/a/bc` is not under `/a/b`, and that either ran on the commit's branch (an empty branch counts as unknown) or were active at its committer date within ten minutes' slack, inclusive (`startedAt - 600 ≤ date ≤ lastActivityAt + 600`); newest start first, ties by id.
- **sessions-match-branch**: The sessions beside a branch MUST be those under the roots whose branch is that branch's short name, in the same order.
- **sessions-daemon-adapter**: `GitDaemonSessions` MUST read a daemon read-only, with one `sessions(status: nil, project: <root>, sinceHours:, includeCounts: false)` call per root, merged by id with the first seen kept; `sinceHours` is the whole hours since the date, rounded up, between 1 and 2160 (90 days). A row with no id or an unreadable start is dropped; an unreadable or earlier last activity is the start; empty title and branch strings are nil; an unreachable daemon answers none.
- **detail-sessions-section**: The commit detail MUST show its matched sessions (`agentSessionMatches`) as an `Agent Sessions` section (`git.commit.sessions`, caption `git.commit.sessions.caption`) after the commit message in the header, one row per session (`git.commit.sessions.row`) titled `<display title> · <branch> · <start–last activity>` (the branch only when known; the span by `DateIntervalFormatter`, medium date, short time) with the working directory as its tooltip. The section MUST be hidden when nothing matches and absent without `agentSessionMatches`; it is re-matched on every `show(commit:)` and on `reloadAgentSessions()`.
- **detail-sessions-open**: Clicking a row MUST call `onOpenAgentSession` once with that session's id; while `onOpenAgentSession` is nil the rows are disabled. A row's colour MUST follow whether it is enabled (accent while clickable, primary text while not), including when `onOpenAgentSession` is set or cleared after the rows are shown.
- **sidebar-sessions-submenu**: A local branch's context menu MUST end, after a separator, with an `Agent Sessions` submenu (`git.sidebar.menu.sessions`) holding the branch's sessions (`agentSessionsOnBranch`), at most 20, one item each (`git.sidebar.menu.sessions.item`, titled like a detail row, the working directory as its tooltip); choosing one MUST call `onOpenAgentSession` with its id, and while that is nil the items are disabled. With no sessions, or no `agentSessionsOnBranch`, there is no separator and no submenu.

### Signing badges

- **signature-badge**: A commit's signing badge (`GitHistorySignatureBadge`) MUST exist only for a checked, signed commit (none for a commit whose signature is not known yet or is `unsigned`), with the SF Symbol `checkmark.seal` in the success colour for `good`, `seal` in the secondary text colour for `unknownValidity`, `exclamationmark.triangle` in the warning colour for `bad`, `revokedKey`, `expired` and `expiredKey`, and `questionmark.diamond` in the secondary text colour for `cannotCheck`. Its text is the signature's summary, `<status title> by <signer>` (the status title alone without a signer).
- **history-signature-badge**: The history's subject cell MUST show the commit's badge (`git.history.signature`, an accessibility image) before its ref badges, with the badge's text as both its tooltip and its accessibility label, read from the data source's `signature(for:)` on each cell; a commit without a badge shows none and takes no space.
- **history-signature-requests**: The history MUST ask the data source for the signatures of the rows it shows (`requestSignatures(for:)` with the visible rows' shas, in row order) after every `reload()` and whenever its clip view's bounds or frame change, once per main-actor turn however many steps a scroll posts (so the rows where a scroll stops are asked for, the leading edge included), and never waits on the answer; it never runs git.
- **signature-loader**: `GitShaBatchLoader` MUST debounce requests by its `delay` (150 ms by default) and run one provider call per batch, one batch at a time, off the UI thread. A request MUST drop the shas already cached, in the running batch, or left unanswered; by default it replaces the queued (not yet started) batch, so the latest visible rows win, and with `replacingQueued: false` it keeps the shas apart from that queue, so no replacement drops them, and they join the next batch (first). A running batch is never cancelled: it finishes and its values are cached for the life of the loader. A sha a successful batch did not answer is never asked for again; a failed batch is reported to `onFailure` and its shas MUST NOT be asked for again until `failureCooldown` (one minute) has passed. `onLoad` is called once per batch that changed the cache: a value new to it or different from the one cached.
- **model-signatures**: The repository model MUST keep one signature loader whose provider is `GitClient.signatures(for:in:caller:)`, answer `signature(for:)` from its cache, send the history's requests in replace mode and a single commit's in add mode (`requestSignature(for:)`), post an `.annotations` change when a batch lands (the window redraws the visible history rows and the commit detail's signature and review, and reloads nothing), and log a failed batch without surfacing it.
- **detail-signature-line**: The commit detail MUST show a `Signature` line (`git.commit.signature`, caption `git.commit.signature.caption`) right after the committer row, from `signatureLookup`: the badge's symbol in its colour, then its text, with `Key <key>` as its tooltip when git named a key and `Signature: <text>` as its accessibility label. The line MUST be hidden without a lookup, for an unsigned commit and for one not checked yet, re-read on every `show(commit:)` and on `reloadSignature()`, which the window calls on every `.annotations` change so a signature that lands shows without reselecting. The window's lookup answers from the model's cache and, when the commit is not cached, asks for it in add mode.

### Reviews

- **reviews-model**: A commit's Coding Partner review (`GitCommitReview`) MUST carry its sha, its state (`queued`, `running`, `done`, `failed`, `skipped`; the title is the capitalized name), its summary and skip reason (each nil when absent) and the review's id. Its first summary line is the summary trimmed of surrounding whitespace and newlines, up to its first newline, trimmed again; nil when that is empty. Reviews come from a `GitReviewsProviding`, which answers the reviews of a list of shas in one repository path (a sha without a review is absent from the answer), never throws, and ticks `changes()` whenever any review changes; the Git views never write to it.
- **review-badge**: A commit's review badge (`GitHistoryReviewBadge`) MUST exist for every review except a skipped one (none for a commit with no review or none read yet), with the SF Symbol `text.magnifyingglass` in the accent colour for `done`, `hourglass` in the secondary text colour for `queued` and `running`, and `xmark.octagon` in the danger colour for `failed`. Its text is the summary's first line, or the state's title when there is none.
- **history-review-badge**: The history's subject cell MUST show the commit's review badge (`git.history.review`, an accessibility image) after its signing badge and before its ref badges, with the badge's text as both its tooltip and its accessibility label, read from the data source's `review(for:)` on each cell; a commit without a badge shows none and takes no space.
- **history-review-requests**: The history MUST ask the data source for the reviews of the rows it shows (`requestReviews(for:)`, the visible rows' shas in row order) exactly when it asks for their signatures: after every `reload()` and on clip-view bounds or frame changes, once per main-actor turn. It never waits on the answer.
- **review-loader-invalidate**: `GitShaBatchLoader.invalidate()` MUST make every value it holds stale without dropping it, so a cached value stays readable until the next batch that asks for its sha lands, and forget every unanswered and failed sha and every queued, kept and running request, so the next request asks for them all again. A batch started before the invalidation MUST NOT be cached. When a batch lands, a stale sha it answered takes the new value and a stale sha it did not answer is removed; a removal, or a value that differs from the cached one, counts as a change for `onLoad`, and a re-answer equal to the cached value does not, so a store write that changed nothing the list shows does not redraw it. Without `invalidate()` a cached sha is never asked for again.
- **model-reviews**: The repository model MUST take an optional `GitReviewsProviding` (`reviews:` at init, `reviewsProvider`) and, when it has one, keep one review loader whose provider asks it for the batch under the root's path. It answers `review(for:)` from that cache (nil without a provider), sends the history's requests in replace mode and a single commit's in add mode (`requestReview(for:)`), posts an `.annotations` change when a batch lands, and `invalidateReviews()` invalidates the loader.
- **detail-review-section**: The commit detail MUST show a `Review` section (`git.commit.review`, caption `git.commit.review.caption`) after the `Agent Sessions` section, from `reviewLookup`: a row (`git.commit.review.stateRow`) with the review's symbol (`git.commit.review.symbol`: the badge's, or `minus.circle` in the secondary text colour for a skipped review) and its state title (`git.commit.review.state`), then the full text (`git.commit.review.summary`, selectable, not editable): the skip reason for a skipped review, otherwise the summary, trimmed, and hidden when empty. Its accessibility label is `Review: <state>`. The section MUST be hidden without a lookup and for a commit without a review, re-read on every `show(commit:)` and on `reloadReview()`, which the window calls on every `.annotations` change. The window's lookup answers from the model's cache and, when the commit is not cached, asks for it in add mode.
- **detail-review-open**: The section MUST end with `Open in Coding Partner` (`git.commit.review.open`) while `onOpenReview` is set, hidden while it is nil; pressing it calls `onOpenReview` once with the review's id.

### Working copy

- **wc-lists**: The working copy MUST show two changed-files lists, `Staged` (context `staged`) over the data source's `staged` files and `Unstaged` (context `unstaged`) over its `unstaged` files, in the data source's order, each item `GitFileListItem(change:)`, each under a header titled `Staged (<count>)` or `Unstaged (<count>)`.
- **wc-selection**: Selecting a file MUST call the delegate's `workingCopy(_:didSelect:)` once with its diff target: a staged file `.staged(paths: [path])`, an untracked unstaged file `.untracked(path:)`, any other unstaged file `.unstaged(paths: [path])`. Selecting in one list MUST clear the other without a delegate call for the clearing. Clearing the selection calls the delegate once with nil.
- **wc-reload**: `reload()` MUST re-read both lists from the data source. A selected file still in its list stays selected without a delegate call, unless its status changed, when the delegate is called once with its new target (an untracked file that becomes intent-to-add moves from `.untracked` to `.unstaged`); one that left its list is deselected and the delegate is called once with nil.
- **wc-intents-only**: The working copy MUST NOT run git. Every action is one call of the delegate's `workingCopy(_:didRequest:)` with a `GitWorkingCopyIntent` (`stage([String])`, `unstage([String])`, `discard([String])`, `stageAll`, `unstageAll`, `discardAll`, `commit(message:amend:)`, `amendChanged(Bool)`, `resolve([String], GitConflictSide)`, `markResolved([String])`, `openMerge(String)`); confirming a discard is the owner's.
- **wc-stage-all**: A trailing borderless `Stage All` button beside the Unstaged header MUST send `.stageAll`, and `Unstage All` beside the Staged header `.unstageAll`.
- **wc-menus**: A staged row's context menu MUST hold `Unstage` (`.unstage`); an unstaged row's `Stage` (`.stage([path])`), `Discard Changes…` (`.discard([path])`), a separator and `Discard All Changes…` (`.discardAll`). A staged item's paths are its `oldPath` (when it has one) and its `path`, so a staged rename unstages both. The changed-files list builds the menu for the clicked row through its `menuProvider` and has none for a click outside the rows.
- **wc-double-click**: Double-clicking a staged row MUST send `.unstage` with its paths, an unstaged row `.stage([path])`, through the changed-files list's `onDoubleClick`.
- **wc-commit-box**: Under the two lists, the commit box MUST offer a plain-text message, an `Amend` checkbox and a `Commit` button (⌘↩). Commit is enabled only when the message trimmed of whitespace and newlines is not empty and there are staged changes (the data source's `staged` is not empty) or Amend is on. Pressing it sends `.commit(message:amend:)` with the message exactly as typed.
- **wc-amend**: Ticking or unticking Amend MUST send `.amendChanged(_:)` with its new state; the owner may then fill the message. `canAmend` (set by the owner, false until it is told otherwise) disables the checkbox and unticks it when false, without a delegate call. `commitDidSucceed()` empties the message and unticks Amend, without a delegate call.
- **wc-conflicts-list**: While the data source's `conflicts` is not empty, a third list, `Conflicts` (context `conflicts`, view `git.fileList.conflicts`, header `Conflicts (<count>)`, no button), MUST sit above Staged, holding each conflicted path sorted, status `.conflicted`; with no conflicts its pane is hidden. A conflicted path MUST NOT also be listed under Unstaged, so the Unstaged header counts only the rest. Selecting a conflict whose kind `hasMarkers` MUST send `.openMerge(path)` and nothing else; selecting one without markers calls `workingCopy(_:didSelect:)` with `.conflicted(path:)`, a diff of the working file against the merge base, so the pane is never blank; selecting in any of the three lists clears the other two.
- **wc-conflict-menu**: A conflict row's context menu MUST hold `Open in Merge View` (`.openMerge(path)`) and a separator, both only when its kind `hasMarkers` (so not for DU, UD, AU, UA or DD), then `Resolve Using Ours…` (`.resolve([path], .ours)`), `Resolve Using Theirs…` (`.resolve([path], .theirs)`) and `Mark Resolved` (`.markResolved([path])`). Double-clicking a conflict with markers sends `.openMerge(path)`; one without sends nothing. Confirming is the owner's.
- **wc-ui-thread**: The working copy MUST be used on the UI thread.

### Diff

- **diff-inline-rows**: `GitInlineDiffModel(diff:oldLines:newLines:wordHighlights:)` MUST have two gutter columns and, per hunk in order, one `.header` row (background `.header`, no gutter values) titled `@@ -<oldStart>,<oldCount> +<newStart>,<newCount> @@`, followed by ` <section>` when the section is not empty, then one row per hunk line: a context line with gutter `[old, new]` and no background, a removed line `[old, nil]` with background `.removed`, an added line `[nil, new]` with background `.added`, and a no-newline marker as a text row `\ No newline at end of file` with no gutter values. Numbers are decimal strings.
- **diff-side-by-side-rows**: `GitSideBySideDiffModel.make(diff:oldLines:newLines:wordHighlights:)` MUST return a left and a right data source of one gutter column each, with the same row count, aligned row for row: each hunk's header on both sides; a context line on both (old number left, new number right); within each run of removed and added lines, the removed lines in order on the left and the added lines in order on the right, the shorter side padded with `.filler` rows (empty text, no gutter value) to the longer side's length; a no-newline marker on the side of the line before it, a filler opposite, or on both sides after a context line.
- **diff-binary**: A binary file MUST be one `.header` row `Binary file`, on each side for side by side, whatever its hunks.
- **diff-word-emphasis**: With `wordHighlights` on, each removed line paired with an added line by `GitWordDiff.pairs(in:)` MUST carry one run with highlight `.emphasis` (no foreground) per range `GitWordDiff.changedRanges(old:new:budget:)` reports for its side; with it off, no row carries an emphasis run. The emphasis MUST be worked out under one `GitWordDiff.Budget` for the whole file diff (a cap on tokens per line and on table cells across every pair), and a pair the budget cannot cover MUST carry no emphasis runs, falling back to line-level colour alone, so a huge diff never stalls the UI thread. The view MUST keep the emphasis it worked out for the loaded diff and setting and reuse it across rebuilds.
- **diff-syntax-runs**: A removed line MUST carry the runs of `oldLines[old − 1]`, an added line those of `newLines[new − 1]`, and a context line those of `newLines[new − 1]`, else `oldLines[old − 1]`; nil lines or a number past the end carry no syntax runs. Emphasis runs follow the syntax runs.
- **diff-coloring**: `GitSyntaxColoring.lines(for:path:)` MUST return nil for nil data, for data over `SyntaxHighlighter.maximumBytes`, for a path whose language the resolver does not know or whose scope has no grammar, and when the highlighter returns nil (a line over `maximumLineLength`); otherwise the highlighter's lines for the data decoded as the diff's own lines are, each line UTF-8 else ISO Latin-1 (so one stray byte does not move the runs of the other lines), with a lone carriage return (one not before a newline) replaced by a space, since the diff splits on newlines only and the highlighter would also break there, decoded off the UI thread. A highlighter that throws is logged and gives nil. `sides(of:target:source:)` MUST resolve each side's language before reading it, so a path with no known language or grammar is never read, and MUST read each side with `maximumBytes: SyntaxHighlighter.maximumBytes`, so a file too large to colour is never read whole.
- **diff-coloring-revisions**: The old side MUST be read with `contents(path: oldPath, at:)` at `:0` for unstaged, `HEAD` for staged, `<id>^1` for a commit and `from` for a range, and is absent for an untracked file; for a conflicted target it MUST be read at the file diff's `oldRevision` (the merge base `:1`, or `HEAD` when the diff fell back to it; absent when nil), so the colours and the lines come from one source; the new side with `contents(path: newPath, at:)` at the working file (nil) for unstaged, untracked and conflicted, `:0` for staged, the commit's id and `to` for a range. A side whose path is nil (an added file's old side, a deleted file's new side) is not read. A read that throws is logged and leaves that side uncoloured.
- **diff-show**: `GitDiffViewController.show(target:file:)` MUST ask the content source for `diff(target, options:)` with `ignoreWhitespace` from its setting, show the file diff whose new path is `file`, else whose old path is `file` (with neither, no rows), at once uncoloured, then read both sides through `GitSyntaxColoring` and show them coloured. A reload that reads a diff equal to the one shown, for the same target, file and options, MUST keep the shown rows until the colouring lands rather than rebuilding them uncoloured first. A viewer's selection MUST survive a rebuild when every selected row shows the same hunk line with the same text afterwards, and is cleared otherwise. Without a coloring the diff stays uncoloured. A diff that throws MUST be logged by `GitClientError.logDescription` and leave the viewer empty with the error's description shown (`git.diff.error`, danger colour); the next `show` or `clear()` hides it.
- **diff-latest-wins**: The latest `show(target:file:)` or `clear()` MUST win: a diff or colouring requested by an earlier call never changes the view, whichever order they finish in, decided by the view's own counter, bumped before it awaits.
- **diff-controls**: The view MUST offer a segmented control `Inline` / `Side by Side`, checkboxes `Ignore Whitespace` and `Word Highlighting`, and buttons `Blame` and `History`. The three settings MUST be read from and written to `UserSettings` keys `git_diff_layout` (`inline` or `sideBySide`, default `inline`), `git_diff_ignore_whitespace` (default false) and `git_diff_word_highlight` (default true). Changing the layout or word highlighting MUST rebuild from the loaded diff without asking the source again; changing ignore-whitespace MUST ask for the shown target again. Side by side locks the two sides' vertical scroll together.
- **diff-blame-history**: `Blame` MUST call the delegate's `diff(_:didRequestBlameFor:at:)` with the shown file and the revision its new side is at (the commit's id, a range's `to`, otherwise nil for the working file); for a deleted file, the revision before it (`<id>^1`, `from`, otherwise `HEAD`). `History` MUST call `diff(_:didRequestHistoryFor:)` with the shown file. Both MUST act on the latest `show`: until its diff arrives they use the `file` it named, as a file that is not deleted, never the previous diff still on screen. Both are disabled while no file is shown.
- **diff-line-refs**: Each diff model (`GitInlineDiffModel`, each side of `GitSideBySideDiffModel`) MUST carry `lineRefs`, one `GitDiffLineRef?` per row: a hunk header `(hunk, nil)`, a row made from a hunk line, marker included, `(hunk, index into that hunk's lines)`, and nil for a filler and the binary row.
- **diff-staging-menu**: A right-click on a row of the diff MUST offer, through the line viewer's `menuProvider`, on an `.unstaged` target `Stage Hunk` (`git.diff.menu.stageHunk`), `Stage Lines` (`stageLines`), a separator, `Discard Hunk…` (`discardHunk`) and `Discard Lines…` (`discardLines`); on a `.staged` target `Unstage Hunk` (`unstageHunk`) and `Unstage Lines` (`unstageLines`). The Lines items are present only when the selection holds an added or removed line. There is no menu for a commit, range or untracked target, for a file `GitPatchBuilder.canBuild` refuses, for a row with no hunk, or for a diff read with options other than the defaults (ignore-whitespace on), whose hunks are not the ones git would apply a patch against.
- **diff-staging-intents**: The diff MUST NOT run git. Each item is one call of the delegate's `diff(_:didRequest:)` with a `GitDiffIntent` (`.stage`, `.unstage`, `.discard`) of a `GitPatchSelection` of the shown file: Hunk is `GitPatchSelection.hunk` of the clicked row's hunk (a filler's is the hunk of the row above it); Lines is every added or removed line among the clicked viewer's selected rows, grouped by hunk, read through that viewer's own `lineRefs` alone: side by side, the two viewers keep separate selections, so the left viewer's rows give removed lines and the right viewer's added lines, and a row never brings in its partner on the other side. The viewers' selection is cleared after.
- **diff-ui-thread**: The diff, its models and its coloring MUST be used on the UI thread; every read and highlight is awaited, never blocked on.

### LFS

- **lfs-diff-row**: When the shown file diff summarises as an LFS diff
  (git-client's lfs-diff-summary), the diff view MUST show that summary as
  its one row (`git.diff.lfs`, secondary text) instead of the pointer text,
  build no viewer rows and colour nothing; any other diff hides the row.
- **lfs-badge**: While the working copy's data source reports an LFS state
  that is in use, each row of the Conflicts, Staged and Unstaged lists
  whose path is stored in LFS (git-client's lfs-tracked-path) MUST show an
  `externaldrive` symbol after its title (`git.workingCopy.lfsBadge`,
  tooltip `Stored in Git LFS`); other rows, and every row of a repository
  not using LFS, show none. The badge is an accessibility image element
  labelled `Stored in Git LFS`. The model loads the LFS state with the refs,
  so a refs change re-reads the badges without re-reading the lists, and a
  change to any `.gitattributes` file, or to `.git/info/attributes`, counts as a refs change too.
- **lfs-fetch-menu**: While the repository uses LFS, the toolbar's Fetch
  button MUST open a menu under itself of `Fetch`, `Fetch LFS Objects`
  (`git.toolbar.lfsFetch`) and `Pull LFS Objects` (`git.toolbar.lfsPull`);
  otherwise it fetches at once, and the two LFS items are not offered. The
  toolbar's items are the same either way. Neither LFS item confirms; a
  failure shows under `Fetch LFS objects failed` or `Pull LFS objects
  failed`.

### Blame

- **blame-rows**: `GitBlameViewController.show(path:at:)` MUST ask the content source for `blame(path:at:)` and show one row per blame line, in order, its text the line's text, with three gutter columns filled only on the first line of each `GitBlame.Run`: the commit's first eight characters, the author's initials (`PersonInitials.of(name:fallback:)` with the email as fallback), and the author date as `yyyy-MM-dd` in the current time zone.
- **blame-coloring**: After showing the lines it MUST colour them by passing the lines joined with `\n` to `GitSyntaxColoring.lines(for:path:)`, line i taking the i-th styled line's runs; nil leaves them uncoloured. The blame is not read a second time.
- **blame-select-commit**: A click in the sha gutter column on any row MUST call the delegate's `blame(_:didSelectCommit:)` once with that row's commit's full id; the all-zero id of uncommitted lines (40 zeros, or 64 in a SHA-256 repository) calls nothing.
- **blame-errors-latest-wins**: A blame that throws MUST be logged and shown as the error's description (`git.blame.error`) over an empty viewer; the latest `show` or `clear()` wins as in diff-latest-wins.

### File history

- **file-history-list**: `GitFileHistoryViewController.show(path:)` MUST ask the content source for `fileHistory(path:)` and list its entries' commits in order, each row the subject and `<shortID> · <author initials> · <relative date>`, then select the first (newest) and show its change to the file in its `diffViewController` as `show(target: .commit(<id>, paths: <entry paths>), file: <entry path>)`: an entry's path is the file's path at that commit, and its paths are that path, or the old and new paths of a rename or copy, so a commit from before a rename shows its change too. Selecting another row shows that commit the same way; clearing the selection clears the diff.
- **file-history-errors-latest-wins**: A history that throws MUST be logged and shown as the error's description (`git.fileHistory.error`) over an empty list, with the diff cleared; the latest `show(path:)` wins as in diff-latest-wins.
- **file-history-reload**: `reload()` MUST list the shown path's commits again, keeping the commit that is selected when the history lands (read after the latest-wins check, not when the reload was asked for) selected when it is still listed, else the newest. The list holds at most the client's file-history limit (500); a history that reaches it is logged, and no text in the view says so.

### Command log

- **command-log-columns**: `GitCommandLogViewController(book:roots:)` MUST show the book's entries oldest first in a themed table of five columns, identifiers `git.commandLog.<time|command|directory|duration|status>`, titled Time, Command, Directory, Duration and Status: the entry's time as a 24-hour `HH:mm:ss` whatever the locale's clock, its command line, its directory's last component, its duration as `<n> ms`, and its exit status (or `–` when unfinished) beside a symbol — `checkmark.circle` success, `clock.badge.exclamationmark` warning when unfinished, `xmark.octagon` danger otherwise.
- **command-log-filter**: It MUST show only entries whose directory is one of the roots the closure returns (the repository's top level and its worktrees), or inside one, comparing the entry's directory and the roots each in their standardized and symlink-resolved forms; an entry with no directory is not shown. The roots are asked for and resolved once per reload (and again only when the list they return changes), and each entry directory is resolved once, never once per entry per root.
- **command-log-follow**: It MUST subscribe to the book's updates when its view loads, before reading what is already there, so nothing lands between the two unseen; each new matching entry is appended; past the ring's capacity the oldest rows go and the new one comes in as one table update, never a full reload, and a reader scrolled up keeps the same rows in view; and the table scrolls to it only when it was already scrolled to the bottom. `stop()` ends the subscription.
- **command-log-copy**: Its context menu MUST hold `Copy Command` (`git.commandLog.menu.copy`), which puts the clicked row's command line on the pasteboard.
- **command-log-tooltip**: A failed row's tooltip MUST be its kept standard error; a row without one has none.
- **error-label**: Every view's error label MUST be the shared `ThemedLabel` and change state only through `show(error:)`, which shows the error's description, or empties and hides the label for nil.
- **settings-keys**: A view's persisted setting MUST be a `UserSettings` key in lower snake case, prefixed with the feature (`git_diff_layout`). Keys already stored keep their spelling; renaming one orphans what users saved.

### Reflog

- **reflog-columns**: `GitReflogViewController` (`git.reflog`; table `git.reflog.table`, scroll `git.reflog.scroll`, rows `git.reflog.row`) MUST show the entries it is given, newest first, in a themed table of five columns, identifiers `git.reflog.<selector|action|message|commit|date>`, titled Selector, Action, Message, Commit and Commit Date, Message alone taking up extra width: the selector (`HEAD@{n}`), the action, the message, the eight-character short sha and the commit's committer date (not the reflog entry's own time) in the locale's medium date and short time. It shows no text when empty. A reload that drops the selected entry (expired or collected) deselects it and tells the delegate nil.
- **reflog-selection**: Selecting a row MUST report its entry to the delegate (nil when the selection empties), which shows that commit in the detail. `show(_:)` MUST keep the selected entry selected when an entry with the same sha, date, action and message is still listed (never matched by selector, which shifts with every new action), and reports nothing while it applies the selection.
- **reflog-menu**: A row's menu MUST hold `Reset HEAD to Here` (`git.reflog.menu.reset`) with a submenu `Soft`, `Mixed`, `Hard…` (`git.reflog.menu.resetSoft|resetMixed|resetHard`), then `Check Out (detached)` (`git.reflog.menu.checkout`) and `Create Branch Here…` (`git.reflog.menu.createBranch`); each item hands the delegate a `GitReflogIntent` for the clicked entry and runs nothing itself. A click outside the rows shows no menu. The session confirms the hard reset; the soft and mixed ones run at once.

### Pull requests

- **pull-requests-source**: `GitRefsDataSource.pullRequests` MUST be the open pull requests `gh` lists (`[GitPullRequest]?`): nil while `gh` is missing, not logged in or not a GitHub repository, which leaves the sidebar's Pull Requests section absent with no word of explanation; any other failure (a timeout, a network or API error) keeps the list already shown, nil before the first load; empty when none is open. `GitRefsDataSource.headPullRequest` MUST be the checked-out branch's own open pull request as `GitHubCLI.pullRequest(forBranch:in:)` finds it, which drops fork (cross-repository) pull requests and is not capped by the list's limit; nil on a detached HEAD, when it has none, or when the lookup fails as not installed, not logged in or not GitHub; any other lookup failure keeps the one already shown. A branch name is never matched against the list. Sources that have no `gh` keep the defaults, nil.
- **pull-requests-loading**: `GitPullRequestsModel` MUST load when the window opens (once the refs are read, so the window's first refs change does not load a second time), after every Fetch, the toolbar's or a remote section's (both at once, started before the fetch), on a change of the checked-out branch (at once), and on any other `.refs` change of the repository model, at most once per 30 seconds: a change inside the interval is answered once, when it ends, and a change while a forced load runs or inside the interval after one starts nothing. A load runs `GitHubCLI.availability` first, then `pullRequests` (`gh pr list --state open --limit 50 --json …`), then the checked-out branch's `pullRequest(forBranch:in:)`; an error at the first two steps gives nil only when `gh` is not installed, not authenticated or the repository is not on GitHub; any other error keeps the list and head pull request already shown, and is in the Command Log. It runs `gh` only through `GitHubCLI` and git only through `GitClient`, never on the main thread, and tells the session only when the list changed.
- **pull-requests-section**: The sidebar MUST show a `Pull Requests` section after Worktrees while the list is not nil, even with no rows; its rows (`git.sidebar.pullRequests.<number>`) read `#<number> <title>` in `gh`'s order, with the status symbol as the icon (`circle.dashed` draft, `arrow.triangle.pull` open, `arrow.triangle.merge` merged, `xmark.circle` closed) and the check state as the badge (`✗` any failing, `●` any pending, `✓` all passing, none without checks). The row that is `headPullRequest` (by number) is bold; a fork's pull request from a branch of the same name is not. The section header carries `git.sidebar.pullRequests`.
- **pull-requests-menus**: A row's menu MUST hold `Check Out`, `Open in Browser` and `Copy URL` (`git.sidebar.pullRequests.menu.checkout|open|copyURL`); Copy URL puts the URL on the pasteboard and runs nothing. The section header's menu MUST hold `Create Pull Request for <head>…` (`git.sidebar.pullRequests.menu.create`), and is absent on a detached HEAD or while `headPullRequest` is not nil. Each item hands the delegate a `GitPullRequestIntent` and runs nothing itself.
- **pull-request-detail**: Selecting a row MUST show `GitPullRequestViewController` (`git.pullRequest`) in the centre pane, titled `Pull Request`: the title (`git.pullRequest.title`), `#<number>`, the state (`Draft`, `Open`, `Closed`, `Merged`), the author, `head → base`, the review decision (`Approved`, `Changes requested`, `Review required`, `None`), the checks (`<n> passing, <n> failing, <n> pending`, or `None`) and the updated date in the locale's medium date and short time, with `Open in Browser` (`git.pullRequest.open`) and `Check Out` (`git.pullRequest.checkout`). The body is not fetched. Captions and values are `ThemedLabel`s (captions in the secondary text role), and each caption carries `git.pullRequest.caption.<number|state|author|branches|review|checks|updated>`. Check Out MUST be disabled for the checked-out branch's own pull request (`headRefName` equal to `checkedOutBranch`, which the session sets on every refs change, and the pull request not `isCrossRepository`: a fork's branch of the same name is a different branch). The detail follows each reload of the selected pull request; a selected pull request the list no longer has (merged or closed elsewhere) empties the detail (`show(nil)`) with both buttons off.
- **pull-request-form**: The create form MUST be a sheet titled `Create Pull Request for <head>` (`git.pullRequest.form`) holding Title, Body, Base and Draft (`git.pullRequest.form.title|body|base|draft`), with `Create` (`git.prompt.action`), enabled only while the title is not blank, and `Cancel` (`git.prompt.cancel`). The title starts as the subject of the branch's first commit not on the base, the body as those commits' subjects oldest first, one `- <subject>` line each; the bases are the repository's default branch first (`gh repo view --json defaultBranchRef`, else `<remote>/HEAD` as git records it), then the push remote's other branches (origin's, else the first remote's) without the head. When neither knows the default branch the Base popup is empty and disabled and `--base` is left out, so `gh` picks it; no branch name is ever guessed to be the default. The form is the confirmation.

## Appearance

### Refs sidebar

The topic list's appearance throughout. Icons (SF Symbols): working copy `square.and.pencil`, local branch `arrow.triangle.branch`, remote branch `network`, tag `tag`, stash `tray`, submodule `shippingbox`, worktree `folder`. The ahead/behind badge is the topic list's trailing badge; the checked-out branch uses its emphasized (bold) label.

### History list

A `ThemedTableView` in a `ThemedScrollView`, with a themed header and themed row selection. The subject is body text in the primary colour; the author name and the date are body text in the secondary colour; the sha is the code font in the secondary colour. Ref badges are the toolkit's `Badge`: local branch filled `accent`, remote branch outlined `accent`, tag outlined `warning`, repainted on a theme change. The avatar is 18 points and shows initials only.

### Changed-files list

A headerless, single-column `ThemedTableView` in a `ThemedScrollView`, with themed row selection. Each row: the status letter in the code font, coloured by status (modified orange, added and untracked green, deleted red, renamed and copied blue, conflicted purple, ignored grey); the file type's SF Symbol in the secondary colour; the title as body text in the primary colour, truncated in the middle.

### Commit detail

The header scrolls on its own above the changed-files list and takes at most half the detail's height. The subject is heading text, the body body text, both selectable; the names primary body text, emails and dates secondary; the sha the code font in the secondary colour, followed by a borderless `doc.on.doc` copy button. Parent links are borderless buttons titled in the accent colour and code font. The avatars are 28 points and show initials only.

### Working copy

Four panes in a horizontal-divider `ThemedSplitView`: conflicts (hidden while there are none), staged, unstaged, then the commit box. Each list pane is a heading-weight caption header, with a trailing borderless small button on staged and unstaged (`Unstage All`, `Stage All`; the Conflicts header has none), over its changed-files list. The commit box is a `Commit Message` caption header over a scrolled native `NSTextView` (plain text, the theme's body font and primary text colour, no placeholder), then a row of the `Amend` checkbox and the `Commit` push button at the trailing edge.

### Diff

A controls row (the native segmented control, two checkboxes and two push buttons, small control size) above the toolkit's line viewer in the theme's code font. Inline: one viewer. Side by side: two viewers in a vertical-divider `ThemedSplitView`, split evenly. Rows use the viewer's backgrounds: added `.success` and removed `.danger` at 0.18 alpha, emphasis runs at 0.40, headers `.surface`, fillers hatched `.surface`.

### Blame

One line viewer; its three gutter columns are 8, the widest initials (at least 2) and 10 characters wide.

### File history

A vertical-divider `ThemedSplitView`: the commit list (a headerless single-column `ThemedTableView`, rows of a primary-colour subject over a secondary-colour detail line) on the left, the diff on the right.

## States

### Refs sidebar

- **Unborn repository**: only `Workspace` is listed (no refs yet), plus `Worktrees` when the data source lists one.
- **Selected row removed**: after a reload that no longer contains the selected ref or stash, `Working Copy` is selected and the delegate is told.
- **Repository deleted**: the data source keeps its last values, so the sidebar keeps its last rows.

### History list

- **Unborn repository / empty history**: no rows; nothing throws, and no text stands in for the rows.
- **Paging**: further rows appear as the data source loads them; the selection is kept.
- **Selected commit removed**: after a reload that no longer contains the selected commit, nothing is selected and the delegate is told nil.
- **Repository deleted**: the data source keeps its last values, so the list keeps its last rows.

### Changed-files list

- **Empty**: no rows, and no text stands in for them.
- **Selected file removed**: after `files` no longer lists it, nothing is selected and the delegate is told nil.

### Commit detail

- **Nothing shown**: before the first `show(commit:)` and after `show(commit: nil)`, the header is empty and takes no height, and the list has no rows.
- **Loading**: the header shows the new commit while its list is empty until the diff arrives.
- **Diff failed**: the header stays, the list stays empty, and the error's description is shown over it until the next `show(commit:)`.
- **Repository deleted**: the shown header and list stay until the next `show(commit:)`.

### Working copy

- **Clean**: both lists are empty, headers `Staged (0)` and `Unstaged (0)`.
- **Unborn repository**: staged files are listed as added; nothing throws.
- **Selected file moved or gone**: after a reload that no longer lists it in its list, nothing is selected and the delegate is told nil.
- **Nothing staged**: Commit is disabled unless Amend is on.
- **Empty or blank message**: Commit is disabled.
- **No commit to amend** (`canAmend` false): the Amend checkbox is disabled and unticked.
- **Commit succeeded**: after `commitDidSucceed()` the message is empty and Amend unticked.

### Diff

- **Nothing shown**: before the first `show` and after `clear()`, no rows and the Blame and History buttons are disabled.
- **Loading**: the previous file's rows stay until the new diff arrives; then the rows show uncoloured until both sides are coloured.
- **Diff failed**: no rows and the error's description shown until the next `show` or `clear()`.
- **Binary**: one header row `Binary file`.

### Blame

- **Blame failed**: no rows and the error's description shown until the next `show` or `clear()`.

### File history

- **No commits**: no rows; the diff is cleared.
- **History failed**: no rows, the diff cleared, the error's description shown until the next `show`.

### Pull requests

- **gh unavailable**: no section, and no explanation.
- **No open pull requests**: the section with no rows; its header menu can still create one.
- **Default branch unknown**: the form's Base popup is empty and disabled; `gh` picks the base.
- **Nothing selected in the detail**: no fields; both buttons disabled.

## Accessibility

### Refs sidebar

The sidebar's root view carries the identifier `git.sidebar`. Rows are the topic list's, so each row's label carries `topic-list.item.<slug of title>` and answers an accessibility press by selecting the row; a badge carries `topic-list.item.<slug>.badge`. Because the identifier comes from the title, a branch name shared by `Branches` and a `Remotes · <remote>` section (`main`) yields the same identifier in each; address one with `dev.py ax --nth`. Context menu items carry `git.sidebar.menu.<name>`: `checkout`, `newBranch`, `rename`, `delete`, `push`, `pull`, `fetch`, `apply`, `pop` and `drop`, a tag's `tag.push` and `tag.delete`, and for worktrees and submodules `newWorktree`, `open`, `removeWorktree`, `updateSubmodule` and `updateAllSubmodules`.

### History list

The root view carries `git.history`, its scroll view `git.history.scroll`, the table `git.history.table`, each row view `git.history.row`. Cells carry `git.history.subject`, `git.history.author`, `git.history.date` and `git.history.sha`; the graph cell keeps its own `commitGraph.cell` and the avatar `avatar`. Badges carry `git.history.badge.local`, `git.history.badge.remote` or `git.history.badge.tag`; the signing badge carries `git.history.signature` and the review badge `git.history.review`, each an image whose accessibility label is its tooltip. Rows are table rows, so `dev.py ax --nth` picks one. Context menu items carry `git.history.menu.<name>`: `checkout`, `newBranch`, `newTag`, `cherryPick`, `revert`, `reset` (the submenu's item), `resetSoft`, `resetMixed`, `resetHard` and `copySha`.

### Changed-files list

The root view carries `git.fileList.<context>` (`commit`, `conflicts`, `staged`, `unstaged`), its scroll view `git.fileList.<context>.scroll` and its table `git.fileList.<context>.table`. Each row view carries `git.fileList.row`, each cell `git.fileList.file`, and within it `git.fileList.status`, `git.fileList.icon` and `git.fileList.title`. The status letter's accessibility label is the status's readable, localized name, `GitFileStatus.displayName` (`Modified`, `Added`, …), never its case name.

### Commit detail

The root view carries `git.detail`, the header's scroll view `git.detail.header`; then `git.detail.subject`, `git.detail.body`, `git.detail.author`, `git.detail.committer` (each row; its avatar keeps `avatar`), `git.detail.sha`, `git.detail.copySha` (accessibility label `Copy SHA`) and `git.detail.parent` for each parent link (use `dev.py ax --nth` for a merge). The review section carries `git.commit.review` (accessibility label `Review: <state>`), its caption `git.commit.review.caption`, the row `git.commit.review.stateRow` holding `git.commit.review.symbol` and `git.commit.review.state`, the text `git.commit.review.summary` and the button `git.commit.review.open`. Its list is `git.fileList.commit`.

### Working copy

The root view carries `git.workingCopy`, its split `git.workingCopy.split` and the panes `git.workingCopy.conflictsPane`, `git.workingCopy.stagedPane` and `git.workingCopy.unstagedPane`; the headers `git.workingCopy.conflictsHeader`, `git.workingCopy.stagedHeader` and `git.workingCopy.unstagedHeader`, and the lists `git.fileList.conflicts`, `git.fileList.staged` and `git.fileList.unstaged`; the header buttons `git.workingCopy.stageAll` and `git.workingCopy.unstageAll`; the menu items `git.workingCopy.menu.stage`, `git.workingCopy.menu.unstage`, `git.workingCopy.menu.discard` and `git.workingCopy.menu.discardAll`, and on a conflict row `git.workingCopy.menu.openMerge`, `git.workingCopy.menu.resolveOurs`, `git.workingCopy.menu.resolveTheirs` and `git.workingCopy.menu.markResolved`. The commit box carries `git.commitBox`, its header `git.commitBox.header`, the message `git.commitBox.message`, the checkbox `git.commitBox.amend` and the button `git.commitBox.commit`.

### Diff

The root view carries `git.diff`; the controls `git.diff.controls`, `git.diff.layout`, `git.diff.ignoreWhitespace`, `git.diff.wordHighlight`, `git.diff.blame` and `git.diff.history`; the inline viewer `git.diff.inline` and the side-by-side viewers `git.diff.left` and `git.diff.right` (in `git.diff.split`), each with the viewer's own `.text` and `.gutter`; the error label `git.diff.error`.

### Blame

The root view carries `git.blame`, its viewer `git.blame.lines` (with `.text` and `.gutter`) and the error label `git.blame.error`.

### File history

The root view carries `git.fileHistory`, the split `git.fileHistory.split`, the list's scroll view `git.fileHistory.scroll`, its table `git.fileHistory.table`, each row view `git.fileHistory.row`, each cell `git.fileHistory.commit` with `git.fileHistory.subject` and `git.fileHistory.details`, the error label `git.fileHistory.error`, and the diff's own `git.diff`.

### Pull requests

The section header carries `git.sidebar.pullRequests` (`TopicListSection.accessibilityIdentifier`), rows `git.sidebar.pullRequests.<number>` and their menu items `git.sidebar.pullRequests.menu.<checkout|open|copyURL|create>`. The detail's root view carries `git.pullRequest`, its fields `git.pullRequest.<title|number|state|author|branches|review|checks|updated>` in the grid `git.pullRequest.fields`, and its buttons `git.pullRequest.open` and `git.pullRequest.checkout` in `git.pullRequest.buttons`. The form's window carries `git.pullRequest.form`, its controls `git.pullRequest.form.<title|body|bodyScroll|base|draft>` in `git.pullRequest.form.fields`.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-views-001 | sidebar-section-order, sidebar-row-titles | A fake source with branches `main` (head) and `dev`, remote branches `origin/main`, `upstream/main`, `origin/dev`, tag `v1`, a stash `WIP on main`, a stash with an empty message at index 1, submodule `lib/sub`, worktrees `/r` (main) and `/w/feature` | Sections `Workspace`, `Branches`, `Remotes · origin`, `Remotes · upstream`, `Tags`, `Stashes`, `Submodules`, `Worktrees`; rows `Working Copy`; `main`, `dev`; `main`, `dev`; `main`; `v1`; `WIP on main`, `stash@{1}`; `lib/sub`; `r`, `feature`. |
| git-views-002 | sidebar-ahead-behind-badge | Branches with (ahead, behind) (2, 1), (2, 0), (0, 3), (0, 0) | Badges `↑2 ↓1`, `↑2`, `↓3`, none. |
| git-views-003 | sidebar-head-bold | `main` is head, `dev` is not | `main` emphasized, `dev` not. |
| git-views-004 | sidebar-empty-sections-omitted | A source with one local branch and nothing else | Sections `Workspace`, `Branches` only. |
| git-views-005 | sidebar-selection | Select each row kind in turn | The delegate receives working copy; ref `refs/heads/main`; ref `refs/remotes/origin/main`; ref `refs/tags/v1`; the stash; directory `<root>/lib/sub`; directory `/w/feature`, once each. |
| git-views-006 | sidebar-reload | Source gains a branch `x`; `reload()` | `Branches` lists `x`; the delegate is not called. |
| git-views-007 | sidebar-reload | `dev` selected; the source gains a branch above it and `dev`'s ahead count changes; `reload()` | `dev` is still selected; the delegate is not called again. |
| git-views-008 | sidebar-reload | Stash `s0` selected and then dropped; `reload()`. Then `dev` selected and deleted; `reload()` | Each time `Working Copy` is selected and `sidebarDidSelectWorkingCopy` is called once. |
| git-views-009 | sidebar-selection | Tag `v1` selected, then worktree `/w/feature` chosen | `open directory /w/feature`; `v1` is selected again. |
| git-views-010 | sidebar-row-titles | Remote refs `origin/main` and `odd` | Rows `main` and `odd`. |
| git-views-011 | sidebar-empty-sections-omitted | An unborn source with main worktree `/repo` | Sections `Workspace`, `Worktrees`; rows `Working Copy`; `repo`. |
| git-views-012 | history-search-parse | `""`, `"  "`, `fix bug`, `author:Ann`, `AUTHOR: Ann `, `sha:AbC12`, `-S needle`, `-Sneedle`, `author:` | No filter; no filter; messageGrep `fix bug`; author `Ann`; author `Ann`; no filter (shaPrefix `abc12`); pickaxe `needle`; pickaxe `needle`; no filter. Revisions, limit and skip are the defaults throughout. |
| git-views-013 | history-columns | A fake source with three commits | Three rows; columns `graph`, `subject`, `author`, `date`, `sha`; row 0's subject, author name, relative date with the absolute tooltip, and 8-character sha. |
| git-views-014 | history-ref-badges | Commit A carries tag `v1`, remote `origin/main` and local `main` (in that order); commit B carries none | A's badges `main` (local), `origin/main` (remote), `v1` (tag); B has none. |
| git-views-015 | history-paging | 120 commits; the table asks for row 69, then 70, then 71 | `loadMore` is not called for 69, is called once for 70, and not again for 71 while the count is unchanged; after `setQuery("author:Ann")` row 70 calls it again. |
| git-views-016 | history-selection, history-reload | Select commit `c1`; reload with `c1` still loaded; reload without it | Delegate `c1` once; nothing on the first reload; nil once on the second. |
| git-views-017 | history-set-query | `setQuery("sha:C1")` on an unfiltered source holding `c1…`; then `setQuery("author:Ann")` | First: the source's query is not replaced and `c1…` is selected. Second: the source receives author `Ann`. |
| git-views-018 | history-graph-width | Graph rows of width 1 and 3 | The graph column is 3 × `columnWidth` wide. |
| git-views-019 | history-set-query | A source that takes the query before it suspends; `setQuery("fix")` held, then `setQuery("fix ")`; the source then returns one commit and is released | The source receives messageGrep `fix` once; after both calls the list shows one row. |
| git-views-020 | history-set-query | Source filtered by author `Someone`; `setQuery("sha:a")` held, then `setQuery("sha:ab")`; the cleared list holds `c000…`, `ab12…`, `c002…` | The source receives the default query once; row 1 (`ab12…`) is selected and the delegate hears it once. |
| git-views-021 | history-paging, history-reload | 120 commits shown; the source clears its commits; row 10 appears | No `loadMore`; the table still has 120 rows. |
| git-views-022 | history-reload | Tag `v1` added at a commit after the last reload | No badge until `reload()`; then `v1`. |
| git-views-023 | file-list-item | Changes `a.swift` modified and `new file.txt` untracked; diffs: added `b`, deleted `old.c`, modified `m.py`, type-changed `link`, renamed `src/a.swift` → `src/b.swift` (90), copied `x` → `y` (100), renamed with identical paths `same` | Items `a.swift` M no old path, `new file.txt` ? no old path; `b` A, `old.c` D, `m.py` M, `link` M, `src/b.swift` R old `src/a.swift` titled `src/a.swift → src/b.swift`, `y` C old `x`, `same` R no old path titled `same`. |
| git-views-024 | file-list-rows | Items `Sources/App.swift` M, `README.md` A, `Makefile` D, `ünï cødé/a b.json` R from `x.json` | Four rows: `M` orange, `swift`, `Sources/App.swift`; `A` green, `doc.richtext`, `README.md`; `D` red, `doc`, `Makefile`; `R` blue, `curlybraces`, `x.json → ünï cødé/a b.json`, tooltip the same. |
| git-views-025 | file-list-selection, file-list-files | Select row 1; set `files` with an item inserted above it; set `files` without it; `clearSelection()` after selecting again | Delegate item 1 once; nothing, row 2 selected; nil once; nothing for the clearing. |
| git-views-026 | detail-header | A commit with subject `Fix it`, body `Line one\n\nLine two`, author `Ann Lee <ann@example.com>`, committer `Bob Roe <bob@example.com>`, parents `p1…`, `p2…` | Subject, body, author `Ann Lee <ann@example.com>` with avatar seeded `ann@example.com`, committer likewise, absolute dates with relative tooltips, the 40-character sha, two parent links titled with eight characters. |
| git-views-027 | detail-header | A root commit with an empty body | Body hidden; parents row hidden. |
| git-views-028 | detail-copy-sha, detail-parent-link | Press copy; press the second parent link | Pasteboard holds the full sha; delegate `didSelectCommit` `p2…` once. |
| git-views-029 | detail-files, detail-file-selection | The source's diff for the commit lists `a.swift` modified and `b` renamed from `a`; select row 1 | The source is asked for `.commit(<sha>, paths: [])` with default options; rows `a.swift`, `a → b`; delegate `didSelectFile` `b` in the commit. |
| git-views-030 | detail-latest-wins | `show(A)` held; `show(B)` returns at once; then A's diff is released | The list shows B's files; A's never appear. |
| git-views-031 | detail-latest-wins | `show(A)` held; `show(B)` held; B released first, then A | The list shows B's files. |
| git-views-032 | detail-files, detail-clear | `show(A)` loaded; `show(B)` held; then `show(nil)` | While B is held the list is empty and the header is B's; after nil, the header and list are empty and B's diff, released, changes nothing. |
| git-views-033 | detail-files | The source's diff throws `commandFailed(verb: "diff", exitStatus: 128, standardError: "fatal: bad object")`; then `show(B)` whose diff lists `from-b` | The header shows the commit; the list is empty; the error label shows the error's description and the failure is logged. After `show(B)` the label is hidden and the list shows `from-b`. |
| git-views-034 | wc-lists | Staged `a` added; unstaged `b` modified, `c` untracked | Headers `Staged (1)`, `Unstaged (2)`; rows `a`; `b`, `c`. |
| git-views-035 | wc-selection | Select `a` (staged), then `c` (unstaged untracked), then `b` | Delegate `.staged(paths: ["a"])`, `.untracked(path: "c")`, `.unstaged(paths: ["b"])`, once each; the staged list is cleared when `c` is selected, with no nil reported. |
| git-views-036 | wc-reload | `b` selected; reload with `b` still unstaged; reload with `b` staged instead | Nothing on the first reload; nil once on the second. |
| git-views-037 | file-list-files, wc-reload | Unstaged `c` untracked selected; reload with `c` added (intent-to-add) | Delegate `.untracked(path: "c")`, then `.unstaged(paths: ["c"])` once; `c` stays selected; a second identical reload reports nothing. |
| git-views-038 | detail-files | A commit whose diff lists no files | The list is empty and no error is shown. |
| git-views-039 | detail-latest-wins, detail-clear | `show(A)` held and failing; `show(B)` returns; A released; then B fails and `show(nil)` | No error after A's late failure, B's files listed; B's failure shown; hidden after nil. |
| git-views-040 | diff-inline-rows | A modified file with hunk `-1,3 +1,3` section `func a()` (context `let a = 1`, removed `let b = 2`, added `let b = 3`, context `let c = 4`) and hunk `-10,2 +10,3` (context `x`, added `y`, context `z`) | Nine rows: header `@@ -1,3 +1,3 @@ func a()`; `1 1`; `2 -` removed; `- 2` added; `3 3`; header `@@ -10,2 +10,3 @@`; `10 10`; `- 11` added; `11 12`. |
| git-views-041 | diff-word-emphasis | 040 with word highlighting on, then off | On: row 2 and row 3 each carry one emphasis run at 8 length 1. Off: no emphasis run. |
| git-views-042 | diff-side-by-side-rows | A hunk: context `c`, removed `r1`, `r2`, `r3`, added `a1`, context `d` | Six rows each side; left `header, c, r1, r2, r3, d`; right `header, c, a1, filler, filler, d`; left `r1` and right `a1` carry the pair's emphasis. |
| git-views-043 | diff-binary | A binary file with no hunks | Inline: one header row `Binary file`; side by side: one on each side. |
| git-views-044 | diff-syntax-runs | 040 with old lines whose line n has one run of length n, new lines likewise with a different colour | Removed `2 -` has old line 2's run; added `- 2` has new line 2's run; context `11 12`, whose new line 12 is past the end, has old line 11's run; with one line on each side, rows `2 -`, `- 2` and `11 12` have none; nil lines give none. |
| git-views-045 | diff-coloring | Real highlighter; `let x = 1` as `a.swift`; the same as `a.unknownext`; nil data; 1,000,001 bytes; one line of 10,001 characters; `let é` in Latin-1, alone and after a UTF-8 line `let ü = 1` | One line whose first run is 0 length 3; nil; nil; nil; nil; `let é = 1` with runs, and the UTF-8 line decoded as UTF-8. |
| git-views-046 | diff-coloring-revisions | Each target with a modified file `a.swift`; a commit with a rename `old.swift` → `new.swift`; an added file in a commit | unstaged `:0`/working; staged `HEAD`/`:0`; untracked none/working; commit `c1^1`/`c1`; range `from`/`to`; the rename reads `old.swift` at `c1^1` and `new.swift` at `c1`; the added file reads only its new side. |
| git-views-047 | diff-show, diff-controls | `show(.commit(c1, paths: [a]), file: a)` with ignore whitespace stored true and the layout stored `sideBySide` | The source is asked for that target with `ignoreWhitespace` true; the side-by-side viewers show the rows; switching to Inline stores `inline` and asks the source nothing. |
| git-views-048 | diff-latest-wins | `show(A)` held, `show(B)` held; released B then A, and again A then B | The rows are B's in both orders, and only B's sides are coloured. |
| git-views-049 | diff-show | The diff throws `commandFailed(verb: "diff", …)`; then `show(B)` | The error label shows the description and the viewer is empty; after B it is hidden and B's rows show. |
| git-views-050 | diff-blame-history | Showing `.commit(c1, paths: [a])`; press Blame, History; then a deleted file `d` in the same commit | Blame `a` at `c1`; History `a`; blame `d` at `c1^1`. |
| git-views-051 | blame-rows, blame-select-commit | Lines 1–2 from `c1` (Ann Lee), line 3 from `c2` (Bob Roe), line 4 from `c1` | Gutters `[c1 short, AL, date]`, `[]`, `[c2 short, BR, date]`, `[c1 short, AL, date]`; a sha click on row 1 selects `c1`; on an uncommitted row nothing. |
| git-views-052 | blame-errors-latest-wins | `show` held then a second `show`, released in both orders; a failing blame | The latest blame's rows; the failure's description in `git.blame.error`. |
| git-views-053 | file-history-list, file-history-errors-latest-wins | `fileHistory` returns `c2`, `c1`; select row 1; a failing history | Rows `c2`, `c1`; the diff is asked for `.commit(c2, paths: [path])`, then `.commit(c1, …)`; the failure shown with the list empty. |
| git-views-054 | file-history-list | `new.swift`'s entries: `c3` at `new.swift`; `c2` renaming `old.swift` → `new.swift`; `c1` at `old.swift`; select rows 1 and 2; press Blame | The diff is asked for `.commit(c3, paths: [new.swift])`, `.commit(c2, paths: [old.swift, new.swift])`, `.commit(c1, paths: [old.swift])`; Blame names `old.swift`. |
| git-views-055 | diff-blame-history | Show a deleted `a` in `c1`; show `b` in `c2`, held; press Blame and History | Blame `b` at `c2`; History `b`. |
| git-views-056 | diff-show | `c1`'s diff holds only `other`; show `mine` | No rows. |
| git-views-057 | diff-coloring | Colour `let a = 1\rx\nlet b = 2` as Swift | Two lines; the second's first run covers `let`. |
| git-views-058 | wc-menus, wc-double-click | Staged `new` renamed from `old`; unstaged `b` modified. Each menu item, then a double-click on each row | `.unstage(["old", "new"])`; `.stage(["b"])`, `.discard(["b"])`, `.discardAll`; then `.unstage(["old", "new"])`, `.stage(["b"])`, once each. |
| git-views-059 | wc-stage-all | Press `Stage All`, then `Unstage All` | `.stageAll`, then `.unstageAll`. |
| git-views-060 | wc-commit-box | Nothing staged, message `Fix\n\nBody`; then Amend ticked; press Commit | Commit disabled for an empty or blank message and with a message but nothing staged; enabled with Amend; `.commit(message: "Fix\n\nBody", amend: true)`. |
| git-views-061 | wc-amend | `canAmend` true, tick Amend; set `canAmend` false; then `commitDidSucceed()` | `.amendChanged(true)` once; the checkbox disabled and unticked; the message empty. |
| git-views-062 | history-menu, history-intents-only | Three commits, the first selected; open row 2's menu, choose each item and each reset mode | Titles `Checkout`, `New Branch…`, `New Tag…`, separator, `Cherry-pick`, `Revert`, `Interactive Rebase from Here…`, separator, `Reset Current Branch to Here` (submenu `Soft`, `Mixed`, `Hard…`), separator, `Copy SHA`; `.checkout`, `.createBranch`, `.createTag`, `.cherryPick`, `.revert`, `.interactiveRebase`, `.reset(.soft)`, `.reset(.mixed)`, `.reset(.hard)`, each for the third commit; the first stays selected. |
| git-views-063 | history-menu | Choose `Copy SHA` on row 1 | The pasteboard holds the second commit's full sha; no intent. A row outside the list has no menu. |
| git-views-064 | sidebar-menus, sidebar-intents-only | The git-views-001 source; `dev`'s menu, each item | `Checkout`, `Check Out in New Worktree…`, `New Branch…`, `Rename…`, `Delete…`, separator, `Push`; `.checkout(dev)`, `.newWorktree(branch: dev)`, `.createBranch(from: dev)`, `.rename(dev)`, `.delete(dev)`, `.push(dev)`; no selection call. |
| git-views-065 | sidebar-menus | `main` (head)'s menu, each item | `New Branch…`, `Rename…`, separator, `Push`, `Pull`; `.createBranch(from: main)`, `.rename(main)`, `.push(main)`, `.pull`. |
| git-views-066 | sidebar-menus | `origin/dev`'s menu; the `Remotes · upstream` header's; every other header's | `Checkout`, `New Branch…`, `Delete…`, separator, `Fetch origin` → `.checkout`, `.createBranch(from:)`, `.delete`, `.fetch(remote: "origin")`; `Fetch` → `.fetch(remote: "upstream")`; none. |
| git-views-067 | sidebar-menus | `v1`'s menu; `stash@{1}`'s; the working copy's and the main worktree's | `Push`, `Delete…` → `.pushTag`, `.deleteTag`; `Apply`, `Pop`, `Drop…` → `.applyStash`, `.popStash`, `.dropStash` of stash 1; no menu. |
| git-views-068 | sidebar-double-click | Double-click `dev`, `origin/main`, then the working copy, `main` (head), `v1`, a stash, a submodule and a worktree | `.checkout(dev)`, `.checkout(origin/main)`, nothing else. |
| git-views-069 | diff-line-refs | `twoHunks` inline | refs `(0,nil) (0,0) (0,1) (0,2) (0,3) (1,nil) (1,0) (1,1) (1,2)`; binary `[nil]`. |
| git-views-070 | diff-line-refs | `twoHunks` side by side | left `(0,nil) (0,0) (0,1) (0,3) (1,nil) (1,0) nil (1,2)`; right `(0,nil) (0,0) (0,2) (0,3) (1,nil) (1,0) (1,1) (1,2)`. |
| git-views-071 | diff-staging-menu | right-click a changed row of an unstaged, a staged, a commit, an untracked diff, and of an unstaged diff with Ignore Whitespace on | `Stage Hunk`, `Stage Lines`, separator, `Discard Hunk…`, `Discard Lines…`; `Unstage Hunk`, `Unstage Lines`; no menu; no menu; no menu. |
| git-views-072 | diff-staging-intents | unstaged `twoHunks`, rows of the removed line of hunk 0 and the added line of hunk 1 selected; `Stage Lines` | one `.stage` with lines `[0: [1], 1: [1]]`; the selection is cleared. |
| git-views-073 | diff-staging-intents | unstaged `twoHunks` side by side; the left viewer's row 2 (the removed `let b = 2`) selected, `Stage Lines`; then the right viewer's row 2 (the added `let b = 3`) | `.stage` with lines `[0: [1]]`, then `.stage` with lines `[0: [2]]`: each the clicked side's line alone. |
| git-views-074 | sidebar-merge-items | the full source, HEAD `main`; menus of `dev`, `origin/dev` and `v1` | each ends its items with a separator, `Merge into main`, `Rebase main onto <name>`, before `Push`, before `Fetch origin`, after `Delete…`; they send `.merge` and `.rebaseOnto` of the row's ref |
| git-views-075 | sidebar-merge-items | the same source while merging; then with HEAD detached; and the `main` row's menu | no menu holds Merge or Rebase |
| git-views-076 | sidebar-drag-drop | ask every row for its drag payload | `refs/heads/dev`, `refs/remotes/origin/dev`, `refs/tags/v1` and the others' full names; the working copy, headers, stashes, submodules and worktrees nothing |
| git-views-077 | sidebar-drag-drop | drop `refs/heads/dev` onto `main`, onto `dev`; `refs/heads/main` onto `main`; `refs/heads/nope` onto `main` | only the first is valid; it pops up `Merge into main`, `Rebase main onto dev`, a separator and `Cancel`, whose items send `.merge(dev)`, `.rebaseOnto(dev)` and nothing |
| git-views-078 | banner-text | each state, with and without its sha, branch and counts | the texts of banner-text; `.none` nil |
| git-views-079 | banner-visibility | `.none`, a merge, a rebase, a cherry-pick, a revert, `.none`; a cherry-pick set before load | hidden; shown without Skip; shown with Skip three times; hidden; shown once loaded |
| git-views-080 | banner-intents-only | press Continue, Skip and Abort | the delegate receives `.step(.continue)`, `.step(.skip)`, `.step(.abort)` |
| git-views-081 | history-ref-drop | a validator refusing `refs/heads/no`; drop `refs/heads/dev`, then `refs/heads/no` | the first is valid and calls `onRefDrop` with `refs/heads/dev`; the second is refused and calls nothing |
| git-views-082 | wc-conflicts-list | conflicts UU `both.txt`, DU `gone.txt`, AA `added.txt`, each also unstaged `.conflicted`, beside modified `b` and staged `s`; then none | the Conflicts pane shown, `Conflicts (3)`, `added.txt`, `both.txt`, `gone.txt`; Unstaged `b` only (`Unstaged (1)`); then the pane hidden |
| git-views-083 | wc-conflict-menu | the menu of `both.txt` (UU); fire each item | `Open in Merge View`, a separator, `Resolve Using Ours…`, `Resolve Using Theirs…`, `Mark Resolved`; `.openMerge`, `.resolve(.ours)`, `.resolve(.theirs)`, `.markResolved` |
| git-views-084 | wc-conflict-menu | the menu of `gone.txt` (DU) | `Resolve Using Ours…`, `Resolve Using Theirs…`, `Mark Resolved`, no Open |
| git-views-085 | wc-conflict-menu | double-click `both.txt`, then `gone.txt` | `.openMerge("both.txt")` only |
| git-views-086 | wc-conflicts-list | select `b`, then `both.txt` (UU), then `gone.txt` (DU), then a staged row | `.unstaged([b])`; `.openMerge("both.txt")` and no selection event; `.conflicted(path: "gone.txt")`; each selection clears the other lists |
| git-views-087 | history-menu | three commits, `headCommit` the first; the menus of rows 0, 1 and 2; then `operationState` merging | `Interactive Rebase from Here…` absent on row 0, present on rows 1 and 2; then absent on both |
| git-views-088 | sidebar-worktree-menus | the full source (worktrees `/repo` main, `/w/feature`); the `Worktrees` header's menu, `feature`'s menu; then with `/w/feature` as the source's root | `New Worktree…` → `.newWorktree(branch: nil)`; `Open`, `Remove…` → `.openDirectory(/w/feature)`, `.removeWorktree(feature)`; then `Open` alone |
| git-views-089 | sidebar-worktree-menus | `dev` checked out in `/w/feature`; `dev`'s menu; `main` (head)'s menu | neither holds `Check Out in New Worktree…` |
| git-views-090 | sidebar-submodule-menus | submodule `lib/sub dir` (uninitialized); the `Submodules` header's menu, the row's menu | `Update All` → `.updateAllSubmodules`; `Open`, `Update` → `.openDirectory(<root>/lib/sub dir)`, `.updateSubmodule(lib/sub dir)` |
| git-views-091 | diff-word-emphasis | the pair `one two` / `three four` under `Budget(cells: 1)`; 200 pairs of 200-word lines under the default budget | no emphasis runs; the rows are those with word highlighting off. |
| git-views-092 | diff-show | two hunks unstaged, rows 2–3 selected; reload reading the same diff; then reload reading a one-line diff | the rows and selection unchanged; then new rows and no selection. |
| git-views-093 | diff-coloring-revisions | `.conflicted(a)` without a diff; with a file diff whose `oldRevision` is `:1`, `HEAD`, nil | `:1`/working; `:1`/working; `HEAD`/working; none/working. |
| git-views-094 | command-log-filter | entries in the root, a subdirectory, `<root>-other`, a worktree, `/elsewhere` and none | the root's, the subdirectory's and the worktree's, five columns. |
| git-views-095 | command-log-follow | 40 entries shown at the bottom; one more; scroll to the top; one more | the last row visible; then still the first row visible. |
| git-views-096 | command-log-copy | `push https://***@github.com/o/r.git main`; Copy Command on row 0 | the pasteboard holds `git push https://***@github.com/o/r.git main`. |
| git-views-097 | command-log-tooltip | a passed `status`; a failed `push` (1, `rejected`) | no tooltip; `rejected`, `xmark.octagon`, `1`, `12 ms`. |
| git-views-098 | command-log-columns | 14:05:09 and 00:00:07 UTC | `14:05:09` and `00:00:07`. |
| git-views-099 | command-log-filter | 20 entries in the root and one in `other`; reload; change the roots to `other`; reload | 20 shown, the roots asked for at most twice; then only `other`'s. |
| git-views-100 | sessions-match-commit | roots `/repo`, `/worktrees/feature`; sessions in `/worktrees/feature`, `/repo/App/Sources`, `/repobc`, `/worktrees/featurex/a`, each active 0–3600 s; a commit at 60 s, no branch | the first two only. |
| git-views-101 | sessions-match-commit | one session on `feature` that ended a day before the commit; one active 0–3600 s; commits at -600, -601, 4200 and 4201 s | the `feature` one for branch `feature`, none for `main`; the active one at -600 and 4200, not at -601 or 4201. |
| git-views-102 | sessions-match-commit, sessions-match-branch | sessions `b` and `a` started at 0, `c` at 100; on-branch `feature` with one session in `/other` | `c`, `a`, `b`; the one in `/other` left out. |
| git-views-103 | sessions-daemon-adapter | rows with empty title and branch; empty id; start `not a date`; empty last activity; last activity before the start; since now, 3601 s ago and 400 days ago | nil title and branch; dropped; dropped; the start; the start; 1, 2 and 2160 hours. |
| git-views-104 | detail-sessions-section | no `agentSessionMatches`; matches answering `[]`; two sessions for `c1`, then show `c2` | hidden; hidden; `Fix it · main · …` and `abcdefgh · main · …`, disabled; hidden again. |
| git-views-105 | detail-sessions-open | `onOpenAgentSession` set; click row 1 | called once with `second`. |
| git-views-106 | sidebar-sessions-submenu | no provider; `[]`; 25 sessions; 2 sessions, `onOpenAgentSession` nil then set, choose item 1 | no submenu; no submenu; the last item `Agent Sessions` holding 20; items disabled, then called with `session-1`. |
| git-views-107 | reflog-columns | three entries, `HEAD@{0}` `commit (amend)` `three again` at sha `c`×40 | columns Selector, Action, Message, Commit, Commit Date (`git.reflog.<name>`); three rows; the first reads `HEAD@{0}`, `commit (amend)`, `three again`, `cccccccc`. |
| git-views-108 | reflog-menu | row 1's menu; then rows -1 and 3 | `Reset HEAD to Here` (submenu `Soft`, `Mixed`, `Hard…`), `Check Out (detached)`, `Create Branch Here…` with their `git.reflog.menu.*` ids; no menu for either. |
| git-views-109 | reflog-menu | choose `Hard…`, `Soft`, `Mixed`, `Check Out (detached)`, `Create Branch Here…` on row 1 | the delegate gets `.reset(e, .hard)`, `.reset(e, .soft)`, `.reset(e, .mixed)`, `.checkout(e)`, `.createBranch(e)`. |
| git-views-110 | reflog-selection | select row 1, then show the same entries | one report of entry 1; it stays selected with no second report. |
| git-views-111 | reflog-selection | select row 1, then show a new `reset` entry first with every selector shifted by one | entry 1's step stays selected, now `HEAD@{2}`; no second report. |
| git-views-112 | review-badge, history-review-badge | Reviews for six rows: done with summary `\n  Looks fine.  \nMore.`, running, queued, failed, skipped with reason `Merge commit`, none | Row 0 shows `text.magnifyingglass` in the accent colour with tooltip and accessibility label `Looks fine.` (`git.history.review`); rows 1 and 2 `hourglass` in the secondary text colour, tooltip `Running` and `Queued`; row 3 `xmark.octagon` in the danger colour, tooltip `Failed`; rows 4 and 5 no badge, hidden. |
| git-views-113 | history-review-requests | 200 commits, an 800 × 240 view, `reload()` | The last `requestReviews(for:)` holds exactly the visible rows' shas, fewer than 200. |
| git-views-114 | detail-review-section, detail-review-open | `reviewLookup` answers `c1` done with summary `Looks fine.\nOne nit.` (review id `repo:c1`); `show(c1)`; then `onOpenReview` set and the button pressed | Section shown right after `Agent Sessions`: caption `Review`, state `Done`, symbol `text.magnifyingglass`, text `Looks fine.\nOne nit.`; the button hidden until `onOpenReview` is set; one call with `repo:c1`. |
| git-views-115 | detail-review-section | No lookup; a lookup answering nil; a lookup answering skipped with reason `Merge commit`; then `show(nil)` | Hidden; hidden; shown with state `Skipped`, symbol `minus.circle`, text `Merge commit`; hidden. |
| git-views-116 | review-loader-invalidate | `a1` cached as `queued`; the answer becomes `done`; `invalidate()`; read; request `a1` | `queued` until the batch lands, then `done`; two batches; `onLoad` twice. |
| git-views-117 | review-loader-invalidate | `a1` cached as `done`; the answer becomes none; `invalidate()`; request `a1` | `a1` reads nil; `onLoad` still called. |
| git-views-118 | review-loader-invalidate | `a1` unanswered and requested twice (one batch); the answer becomes `queued`; `invalidate()`; request `a1` | Two batches in all; `a1` reads `queued`. |
| git-views-119 | review-loader-invalidate | `a1` cached as `queued`; the answer becomes `done`; request `a1` without `invalidate()` | One batch; `a1` still reads `queued`. |
| git-views-120 | review-loader-invalidate | `a1` cached as `done`; the answer stays `done`; `invalidate()`; request `a1` | Two batches; `a1` reads `done`; `onLoad` once in all. |
## Edge Cases

- **Null / empty input**: An unborn repository lists only the working copy (and its worktree).
- **Boundary values**: A branch with no upstream has ahead and behind 0 and so no badge.
- **Duplicate titles**: A local `main` and `origin/main` are both titled `main` in different sections; their row ids differ (the full ref name), so selection is unambiguous.
- **Awkward paths**: Submodule paths and worktree directories with spaces or unicode are shown as they are and joined to the root as path components, never as strings.
- **Concurrent access**: UI thread only.
- **Error states**: The sidebar shows whatever the data source last loaded; it has no error state of its own.
- **Offline / disconnected state**: Not applicable: no network.

- **History, empty**: an unborn repository has no commits; the list has no rows and asks for one page at most.
- **History, end reached**: a `loadMore` that adds nothing is not repeated until the count or the query changes.
- **History, ambiguous sha prefix**: the first (newest) loaded match is selected.
- **History, search text with regex characters**: plain text is passed to git as `--grep` (a regular expression, case-insensitive); `-S` is a literal string.
- **History, text starting with `-S`**: any text that starts with `-S` (case-sensitive) is a pickaxe search for the rest, as git's own `-S<x>`: `-Something` searches for `omething`; `-s x` is a message search.
- **History, typing while a search is in flight**: `fix` then `fix ` (or `sha:a` then `sha:ab` while a filter clears) parse to the query already in flight; the later call waits for it, then reloads and selects.
- **History, non-UTF-8 messages**: shown as the model decoded them (lossily), never dropped.

- **Files, awkward paths**: spaces, unicode and tabs are shown as they are; a path holding a newline stays on one row (single-line label, one line at most) and its tooltip holds the whole path.
- **Files, a path with no extension** (`Makefile`) or a dot file (`.gitignore`, whose extension is empty): the `doc` icon.
- **Files, the same path twice**: the id is the path, so the selection kept across a `files` change is the first row with that path.
- **Commit detail, a merge**: one parent link per parent; the list is the diff against the first parent.
- **Commit detail, a root commit**: no parents row; the list is the diff against the empty tree.
- **Commit detail, a stash**: a stash is a commit and shows as one, its list the diff against its first parent.
- **Commit detail, quick selection changes**: each `show(commit:)` bumps the detail's own counter before awaiting; a diff that returns for an older call is dropped, so arrow-keying down the history never leaves an earlier commit's files under a later header.
- **Commit detail, a binary file**: one row like any other; the diff view decides how to show it.
- **Commit detail, non-UTF-8 message**: shown as the model decoded it (lossily).
- **Working copy, unborn HEAD**: staged files list as added; selecting one reports `.staged`, which the client diffs against the empty tree.
- **Working copy, a conflicted file**: listed unstaged with `U` in purple; selecting it reports `.unstaged`.
- **Working copy, a file both staged and modified**: listed in both lists; each selection reports its own target.

- **Diff, a whitespace-only change with Ignore Whitespace on**: the diff lists no file; the viewer is empty, with no error.
- **Diff, a pure rename or mode change**: no hunks, so no rows.
- **Diff, huge or minified files**: over 1 MB, or a line over 10,000 UTF-16 units, the side is uncoloured; the viewer draws only visible rows.
- **Diff, non-UTF-8 content**: each line decoded as UTF-8 else ISO Latin-1, as the diff's own lines are, so a stray byte leaves every other line coloured on the right columns.
- **Diff, a lone `\r` line ending**: git does not split on it but the highlighter would, so colouring sees it as a space and every later line keeps its colours; the diff text itself is unchanged.
- **Diff, awkward paths**: the language comes from the path's file name and extension; spaces, unicode and newlines are passed through to the content source as they are.
- **Blame, uncommitted lines**: the all-zero id shows as `00000000` with the `Not Committed Yet` author; clicking it selects nothing.
- **File history, renames**: the history follows renames, and each commit's diff is asked for the file's path at that commit (both paths for the rename itself), so a commit from before a rename shows its change.
- **Diff, Blame or History while a file loads**: they act on the file just requested, never on the diff still on screen.
- **Diff, the file is not in the diff**: no rows, never another file's change.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `source` | `GitRefsDataSource` | none | Where the sidebar reads refs, stashes, submodules, worktrees and the repository root. |
| `delegate` | `GitRefsSidebarDelegate?` | nil | Told what the user selected, and every `GitRefIntent`. |
| `source` (history) | `GitHistoryDataSource` | none | Where the history list reads commits, graph rows, the query, the HEAD commit, the operation in progress and the refs at a commit, and asks for pages and queries. |
| `delegate` (history) | `GitHistoryDelegate?` | nil | Told which commit is selected, or nil, and every `GitCommitIntent` with its commit. |
| `pasteboard` (history) | `NSPasteboard` | `.general` | Where Copy SHA puts the sha. |
| `identifier` (file list) | `String` | none | The list's context (`commit`, `conflicts`, `staged`, `unstaged`); its root identifier is `git.fileList.<identifier>`. |
| `files` (file list) | `[GitFileListItem]` | `[]` | The rows. |
| `delegate` (file list) | `GitFileListDelegate?` | nil | Told which item is selected, or nil. |
| `source` (detail) | `GitContentSource` | none | Where the commit detail reads the commit's diff. |
| `pasteboard` (detail) | `NSPasteboard` | `.general` | Where the copy button puts the sha. |
| `delegate` (detail) | `GitCommitDetailDelegate?` | nil | Told which parent link and which file were chosen. |
| `source` (diff) | `GitContentSource` | none | Where the diff reads diffs and contents. |
| `coloring` (diff, blame, file history) | `GitSyntaxColoring?` | none | Syntax colour; nil shows text uncoloured. |
| `settings` (diff, file history) | `SettingsStore` | `UserSettings.shared` | Where the layout and toggles are stored. |
| `delegate` (diff) | `GitDiffDelegate?` | nil | Told when Blame or History is pressed. |
| `delegate` (blame) | `GitBlameDelegate?` | nil | Told which commit a sha click chose. |
| `source` (working copy) | `GitWorkingCopyDataSource` | none | Where the working copy reads its staged and unstaged files. |
| `delegate` (working copy) | `GitWorkingCopyDelegate?` | nil | Told the selected file's diff target, or nil, and every `GitWorkingCopyIntent`. |
| `canAmend` (working copy, commit box) | `Bool` | false | Whether Amend can be ticked; the owner sets it when there is a commit to amend. |
| `menuProvider` (changed-files list) | `((GitFileListItem) -> NSMenu?)?` | nil | The clicked row's context menu. |
| `onDoubleClick` (changed-files list) | `((GitFileListItem) -> Void)?` | nil | Called with a double-clicked row's item. |

## Deep Linking

Not applicable: the views define no URL scheme, route or navigation destination.

## Localization

Section titles (`Workspace`, `Branches`, `Remotes · <remote>`, `Tags`, `Stashes`, `Submodules`, `Worktrees`) and `Working Copy` are English literals today; ref names, messages and paths are shown verbatim.
The history list's column titles (`Graph`, `Subject`, `Author`, `Date`, `SHA`) are English literals today; relative and absolute dates follow the current locale; the search prefixes (`author:`, `sha:`, `-S`) are not localized.
The working copy's headers (`Staged (<count>)`, `Unstaged (<count>)`), the commit detail's field captions (`Author`, `Committer`, `SHA`, `Parents`) and the copy button's label (`Copy SHA`) are English literals today; detail dates follow the current locale; status letters are git's and are not localized.
The diff's controls (`Inline`, `Side by Side`, `Ignore Whitespace`, `Word Highlighting`, `Blame`, `History`), its `Binary file` and `\ No newline at end of file` rows are English literals today; blame dates are `yyyy-MM-dd` in every locale, and file-history dates follow the current locale.

## Accessibility Options

The topic list's fonts follow the theme; the emphasized row is bold text, not colour alone.

## Feature Flags

Not applicable: the views contain no feature-flag reference.

## Analytics

Not applicable: the views contain no analytics call.

## Privacy

The views show local repository data only and send nothing anywhere. Coding Partner reviews are read, never written, through `GitReviewsProviding`; the views show a review's state, summary and skip reason, and hand only its id to `onOpenReview`.

## Logging

The commit detail, the diff, the blame and the file history each log a failed load (diff, blame, history, or a side's contents) at error level, by `GitClientError.logDescription` (case and fields, never git's output), under their own `Loggable` categories; `GitSyntaxColoring` logs a highlighter error by its type; the other views log nothing, and the model logs failed reloads.

## Platform Notes

- **SwiftUI**: A `List` with `Section`s and `.badge(_:)` would serve; this toolkit's views are AppKit.
- **Compose**: A `LazyColumn` with sticky headers; the badge as trailing text.
- **React/Web**: A listbox with grouped options; the badge as a trailing span.
- **AppKit / UIKit**: AppKit: `@MainActor public final class GitRefsSidebarViewController: NSViewController` in `AgenticDeveloperHubSDKMacOS`, hosting a `TopicListViewController` as a child; `@MainActor public final class GitHistoryViewController: NSViewController` on a `ThemedTableView`, and `public enum GitHistorySearch` in `AgenticDeveloperHubSDKCore`; `GitFileListViewController`, `GitCommitDetailViewController` and `GitWorkingCopyViewController` likewise, with `public struct GitFileListItem` in `AgenticDeveloperHubSDKCore`. UIKit: not applicable (no git on iOS).
- **WinUI 3**: A `ListView` with grouped items.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/` | confirmed (1.14.2) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Git/GitHistorySearch.swift` | confirmed (1.14.2) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Git/GitFileListItem.swift` | confirmed (1.14.2) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/GitDiffLineModels.swift` | confirmed (1.14.2) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/GitSyntaxColoring.swift` | confirmed (1.14.2) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/GitDiffViewController.swift` | confirmed (1.14.2) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/GitBlameViewController.swift` | confirmed (1.14.2) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/GitFileHistoryViewController.swift` | confirmed (1.14.2) |
| apple | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Theme/ThemedViews.swift` | confirmed (1.14.2) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Git/GitFileStatus.swift` | confirmed (1.14.2) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/GitOperationBannerViewController.swift` | confirmed (1.14.2) |
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/GitWorkingCopyViewController.swift` | confirmed (1.14.2) |
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/GitCommandLogViewController.swift` | confirmed (1.14.2) |

## Design Decisions

**Decision**: The sidebar hosts a topic list as a child rather than subclassing it.
**Rationale**: The sidebar's public surface is its data source, delegate and `reload()`; a subclass would also publish the list's own setters, letting a caller replace the sections behind the sidebar's back.
**Approved**: pending

**Decision**: Remote branches are grouped as one flat section per remote (`Remotes · origin`) rather than nested under one `Remotes` header.
**Rationale**: The topic list is deliberately flat (no disclosure, no indentation); a section per remote groups them without a second list type.
**Approved**: pending

**Decision**: The ahead/behind badge and the bold head row are topic-list features (`badge`, `isEmphasized`), not sidebar drawing.
**Rationale**: Built from the shared component upward: any sectioned sidebar can show a count or mark the current row, and the topic list keeps owning its cells.
**Approved**: pending

**Decision**: The data source vends the repository root, so a submodule row can name its directory.
**Rationale**: `git submodule status` reports paths relative to the working tree; the model already knows its root.
**Approved**: pending

**Decision**: `GitHistorySearch` lives in `AgenticDeveloperHubSDKCore`, beside `GitLogQuery`, not with the view.
**Rationale**: It is pure Foundation; the lowest tier that can hold it is Core, where a CLI or another view can parse the same search text.
**Approved**: pending

**Decision**: `sha:` selects among loaded commits rather than filtering the log.
**Rationale**: The search is for finding a commit in context; filtering to one commit would hide the graph around it. A prefix not yet loaded selects nothing.
**Approved**: pending

**Decision**: Paging is asked for when the table requests a row near the end, and not again until the count or the query changes.
**Rationale**: The table only requests rows it is about to show, so the request is the visibility signal; the count guard keeps a finished history from reloading in a loop.
**Approved**: pending

**Decision**: After a page arrives the list reloads itself; the owner's reload on the model's history notification is a second, harmless one.
**Rationale**: The list must not depend on its owner to show the pages it asked for; the owner's reload is still needed for changes the list did not ask for (refresh, refs).
**Approved**: pending

**Decision**: `setQuery` tracks the query it sent and the task sending it, never the data source's query after the first search.
**Rationale**: The model takes the new query before it awaits the log, so its query says nothing about whether results have arrived.
**Approved**: pending

**Decision**: One changed-files list (`GitFileListViewController`) serves the commit detail and both working-copy lists, and its row model `GitFileListItem` lives in `AgenticDeveloperHubSDKCore`.
**Rationale**: The same row in three places is one component (DRY); the item's mapping from a status entry or a diff is pure Foundation, so Core is the lowest tier that can hold it.
**Approved**: pending

**Decision**: The file list, commit detail and working copy delegates take an optional (`GitFileListItem?`, `GitDiffTarget?`) and report nil when the selection clears.
**Rationale**: The owner shows a diff for the selection; without the nil a removed file's diff would stay on screen after a refresh (Review Focus: stale selection clears). The history list's delegate does the same.
**Approved**: pending

**Decision**: The commit detail reports a file as the `GitFileListItem` and the commit, not as a diff target.
**Rationale**: The owner builds the target (`.commit(id, paths:)`) for the diff view; the item carries the old path a rename's diff needs.
**Approved**: pending

**Decision**: The commit detail's latest-call-wins check is its own counter, bumped before it awaits, and the list empties when a different commit is shown.
**Rationale**: A check on state the content source changes before it awaits would let an older diff through; emptying at once means the header and the files never disagree.
**Approved**: pending

**Decision**: The commit detail lists the diff's files rather than a separate `--name-status` call.
**Rationale**: The diff is the one source the content source offers and its parser already reads renames, copies and binaries; a second call per commit is a second process for the same facts.
**Approved**: pending

**Decision**: The diff models are `LineViewerDataSource`s built once per diff, layout and toggle, not views.
**Rationale**: The line viewer already draws runs, backgrounds, gutters and fillers; a diff is a configuration of it (built from the shared component upward), and a model is testable without a window.
**Approved**: pending

**Decision**: The diff shows its rows uncoloured as soon as the diff arrives, then recolours when both sides are read and highlighted.
**Rationale**: Highlighting reads two file versions and runs the interpreted TextMate engine; the change itself should never wait for its colours.
**Approved**: pending

**Decision**: `GitSyntaxColoring` lives with the views in `AgenticDeveloperHubSDKMacOS`, not in `AgenticDeveloperHubSDKLanguage`.
**Rationale**: It reads a `GitContentSource`, which is a macOS-tier protocol; `lines(for:path:)` itself uses only Language types, so it could move down if another tier ever needs it.
**Approved**: pending

**Decision**: The blame colours the lines it already has rather than reading the file again.
**Rationale**: The blame's lines are the file at that revision; a second read is a second process for the same bytes.
**Approved**: pending

**Decision**: The window's own worktree has `Open` but no `Remove…`, and the main worktree has no menu.
**Rationale**: Git refuses to remove the main worktree, and removing the folder a window is showing would leave that window on nothing; the sidebar compares the row's directory with the data source's `root`, which it already holds.
**Approved**: pending

**Decision**: Reviews reach the views through `GitReviewsProviding`, declared in Core beside `GitCommitReview`, and the Partner store's adapter (`PartnerGitReviews`) lives with the Partner feature.
**Rationale**: The Git views must not know the Partner store or its schema, and the Partner feature must not know the views; a Foundation-only protocol in the lowest tier lets either change, and lets a test supply reviews without a store.
**Approved**: pending

**Decision**: Reviews use the signing badges' `GitShaBatchLoader`, with `invalidate()` added, rather than a loader of their own.
**Rationale**: The request shape is the same (visible rows, debounced, coalesced, single commits in add mode); what differs is that a review changes after it is read, which `invalidate()` covers without dropping what is shown, so a queued badge does not blink out while its done value loads.
**Approved**: pending

**Decision**: A skipped review has no history badge but does have a detail section.
**Rationale**: A row of skipped merge commits would be noise in the list; the detail is where someone asks why a commit has no review, and the skip reason answers it.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because the views read data-source protocols and report to delegates; none calls git or knows its window. `unit-test-coverage` passes: `GitRefsSidebarViewControllerTests` covers section order and titles, badges, emphasis, omitted sections, selection of every row kind, reload with a selection kept or dropped, directory rows restoring the selection, every row's and remote header's context menu with its intents, the rows with none, and double-click, against a fake data source; `GitHistoryViewControllerTests` covers the columns, ref badges per row, the graph width, paging, selection and reload, `setQuery`, and the row menu's items, intents for the clicked commit and Copy SHA, and `GitHistorySearchTests` each search form; `GitFileListItemTests` covers the item mapping, `GitFileListViewControllerTests` the rows, selection and `files` changes, `GitCommitDetailViewControllerTests` the header, copy, parent links, files, file selection, clearing and latest-call-wins in both finishing orders, `GitWorkingCopyViewControllerTests` the lists, targets, reload, header buttons, menus and double-clicks, and `GitCommitBoxViewControllerTests` the Commit button's enabling, the commit and amend intents, `canAmend` and `commitDidSucceed()`, all against fakes that behave like the model.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation: the refs sidebar |
| 1.0.1 | 2026-11-13 | Mike Fullerton | Reload falls back to the working copy when the selected ref or stash vanishes; directory rows restore the selection; remote title fallback; vectors 007-011 |
| 1.1.0 | 2026-11-13 | Mike Fullerton | History list: graph, subject with ref badges, author, date, short sha; paging; selection and reload; search parsing and setQuery; vectors 012-018 |
| 1.1.1 | 2026-11-13 | Mike Fullerton | setQuery tracks the query it sent and waits for one in flight; paging and badges read the reload snapshot; scroll and row identifiers; vectors 019-022 |
| 1.2.0 | 2026-11-13 | Mike Fullerton | Changed-files list, commit detail and working copy: GitFileListItem in Core, one shared list, latest-call-wins detail, staged/unstaged targets; vectors 023-036 |
| 1.3.0 | 2026-11-13 | Mike Fullerton | Commit detail logs a failed diff and shows its description; surviving items re-report on a status change; single-line titles; collapsed empty header; vectors 033, 037-039 |
| 1.4.0 | 2026-11-13 | Mike Fullerton | Diff, blame and file history views: inline and side-by-side diff models, syntax colouring, persisted diff toggles |
| 1.4.1 | 2026-11-14 | Mike Fullerton | File history diffs each commit under the file's path at that commit; Blame and History act on the latest show; a file missing from the diff shows no rows; blame's uncommitted id at either hash length; colouring decodes each line as the diff text does |
| 1.5.0 | 2026-11-14 | Mike Fullerton | Final review: debounced cancellable search; commit detail lists changed files without the patch; colouring resolves the language before a capped read; file-history reload keeps the current selection; one error-label helper; key style; readable status label |
| 1.6.0 | 2026-11-14 | Mike Fullerton | Working copy actions: stage, unstage and discard by menu, double-click and header buttons, and a commit box with Amend; every action a GitWorkingCopyIntent sent to the delegate; vectors 058-061 |
| 1.7.0 | 2026-11-14 | Mike Fullerton | Commit and ref menus: history row menu with a reset submenu and Copy SHA; branch, remote, remote header, tag and stash menus and double-click to check out in the sidebar; every action a GitCommitIntent or GitRefIntent sent to the delegate; vectors 062-068 |
| 1.7.1 | 2026-11-14 | Mike Fullerton | Review fixes: the tag menu items carry tag.push and tag.delete |
| 1.8.0 | 2026-11-15 | Mike Fullerton | Diff staging menu: line refs on each diff model; Stage, Unstage and Discard of the clicked hunk or the selected lines, each a GitDiffIntent sent to the delegate; no menu ignoring whitespace; vectors 069-072 |
| 1.8.1 | 2026-11-15 | Mike Fullerton | Review fix: side by side, Lines reads only the clicked viewer's own side, so one half of a changed pair can be staged, unstaged or discarded alone; vector 073 |
| 1.9.0 | 2026-11-15 | Mike Fullerton | Merge and rebase: the sidebar's Merge into and Rebase onto items, refs dragged and dropped on the checked-out branch for a drop menu, the in-progress operation banner, refs dropped on the history; vectors 074-081 |
| 1.10.0 | 2026-11-15 | Mike Fullerton | Working copy conflicts: a Conflicts list above Staged while there are conflicts, its paths left out of Unstaged; Open in Merge View (markers only), Resolve Using Ours…, Resolve Using Theirs… and Mark Resolved, and double-click to open; vectors 082-086 |
| 1.10.1 | 2026-11-15 | Mike Fullerton | the working copy's conflicts pane, list and menu identifiers in accessibility, appearance and configuration |
| 1.11.0 | 2026-11-16 | Mike Fullerton | History menu: Interactive Rebase from Here…, left out on HEAD's row and during an operation; the data source gives the HEAD commit and the operation state; vector 087 |
| 1.12.0 | 2026-11-16 | Mike Fullerton | Worktree and submodule menus: New Worktree… on the Worktrees header, Open and Remove… on a linked worktree (Open alone on the window's own), Check Out in New Worktree… on a branch checked out nowhere, Update All on the Submodules header, Open and Update on a submodule; new intents newWorktree, removeWorktree, updateSubmodule, updateAllSubmodules, openDirectory. |
| 1.12.1 | 2026-11-16 | Mike Fullerton | Final review: word-emphasis budget, selection kept across reloads, non-ancestor rebase rows; reword field newlines, row heights, Move Up/Down; selectRows; merge view cap |
| 1.12.2 | 2026-11-16 | Mike Fullerton | Selecting a conflict with markers opens the merge view; one without shows its .conflicted diff (vector 086) |
| 1.12.3 | 2026-11-16 | Mike Fullerton | A conflicted diff's old side is coloured from the revision the diff used (vector 093) |
| 1.13.0 | 2026-11-16 | Mike Fullerton | Command log view: columns, root filter, follow-bottom, Copy Command, failure tooltip. |
| 1.14.0 | 2026-11-16 | Mike Fullerton | Signing badges: a symbol per signed history row, the visible-row requests through the debounced, coalesced `GitShaBatchLoader` (replace the queued batch, a running one finishes and is cached), and the Signature line in the commit detail. |
| 1.14.1 | 2026-11-16 | Mike Fullerton | Signing badges fix round 1: requests on every clip-view bounds or frame change; single-sha requests kept apart from the replaceable queue; a failed batch cools down for a minute. |
| 1.14.2 | 2026-11-16 | Mike Fullerton | Phase 4 final review: `.annotations` redraws for signature and review batches; one coalesced visible-row request per main-actor turn; one batch at a time; `.git/info/attributes` is a refs change; the command log drops its oldest rows in one update and keeps a reader's scroll; reflog Commit Date and a vanished selection reported nil; gh failures other than not installed, not authenticated and not GitHub keep the Pull Requests section; detail caption ids, ThemedLabels, Check Out off for the checked-out branch, an emptied detail for a pull request that left the list. |
