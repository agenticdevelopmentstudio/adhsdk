---
id: bdd3a72d-8810-439b-bad7-ec16233cb2a3
title: "Git Views"
type: ingredient
version: 1.1.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The git window's AppKit views, each reading one data-source protocol of the repository model and reporting to an injected delegate: the refs sidebar (working copy, branches with ahead/behind, remotes by remote, tags, stashes, submodules, worktrees) and the history list (graph, subject with ref badges, author, date, short sha; paging; search)."
platforms:
  - swift
  - macos
tags:
  - git
  - ui
  - sidebar
  - history
  - search
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
approved-by: ""
approved-date: ""
---

# Git Views

## Overview

The views of a git window: each one an AppKit view controller that reads one narrow data-source protocol of the [git repository model](cookbook:a2394ca0-3988-410b-9fc8-e0c9e253fc94) and reports what the user chose to a delegate, injected, so none of them knows its window or calls git. This recipe has one section per view. The **refs sidebar** (`GitRefsSidebarViewController`) lists, on the toolkit's [topic list](cookbook:ce223be3-818a-4310-b136-9e1e84e9af54), the working copy, the local branches, the remote branches grouped by remote, the tags, the stashes, the submodules and every non-bare worktree (the main one and the one the window is on included), with ahead/behind badges on branches that track an upstream and the checked-out branch in bold.
The **history list** (`GitHistoryViewController`) is a paged table of the [commit graph cell](cookbook:595f1a5e-0f92-49c5-a980-af6f809be932), the subject behind a [badge](cookbook:2cfe57f0-cdd4-4723-a6e0-2ce4f136ce7f) per ref at the commit, the author's [avatar](cookbook:e3a2394d-d0d0-4495-bde4-59197f9d7866) and name, the [relative date](cookbook:873f79b1-444d-4c2c-8a5f-4fc01cd9022e) and the short sha. It reads a `GitHistoryDataSource`, asks for the next page as the end of the list comes into view, and takes the window's search text through `setQuery(_:)`, which `GitHistorySearch.parse(_:)` (Foundation only, in `AgenticDeveloperHubSDKCore`) turns into a `GitLogQuery`.

## Behavioral Requirements

### Refs sidebar

- **sidebar-section-order**: The sidebar MUST list its sections in this order: `Workspace` (one row, `Working Copy`), `Branches` (local branches), one section per remote titled `Remotes · <remote>` (in the order each remote first appears in the refs), `Tags`, `Stashes`, `Submodules`, `Worktrees`. Rows keep the data source's order within a section.
- **sidebar-empty-sections-omitted**: A section with no rows MUST be left out, header included; `Workspace` always has its one row.
- **sidebar-row-titles**: A local branch or tag row MUST be titled with its name; a remote branch row with its name less the `<remote>/` prefix, or its whole name when nothing follows the prefix; a stash row with its message, or `stash@{N}` when the message is empty; a submodule row with its path; a worktree row with its directory's last path component. Bare worktrees MUST be left out.
- **sidebar-ahead-behind-badge**: A local branch row MUST carry a badge `↑n ↓m`, each half present only when its count is non-zero (`↑2 ↓1`, `↑2`, `↓1`), and no badge when both are zero. Other rows carry none.
- **sidebar-head-bold**: The checked-out branch's row MUST be emphasized (bold); no other row is.
- **sidebar-selection**: Selecting a row MUST call the delegate once: the working copy → `sidebarDidSelectWorkingCopy`; a branch, remote branch or tag → `didSelect ref`; a stash → `didSelectStash`; a submodule → `open directory` with the repository root joined with the submodule's path; a worktree → `open directory` with the worktree's directory. A submodule or worktree row is an action, not a place: after it opens, the previous selection, when there is one, is restored, so the same row can be chosen again. Clearing the selection calls nothing.
- **sidebar-reload**: `reload()` MUST rebuild every section from the data source's current values, keeping the selected row selected when its id is still present (by the topic list's restore-by-id) without calling the delegate. When the selected row is gone, the sidebar MUST select `Working Copy` and call `sidebarDidSelectWorkingCopy` once, so the owner never keeps showing a ref or stash that no longer exists.
- **sidebar-ui-thread**: The sidebar MUST be used on the UI thread.

### History list

- **history-columns**: The history list MUST show one row per data-source commit, in the data source's order, with these columns in order: `graph` (a `CommitGraphCellView` drawing the data source's graph row at the same index), `subject` (the ref badges, then the commit's subject), `author` (an `AvatarView` of side 18 showing initials, seeded by the author's email, with no picture URL, then the author's name), `date` (`RelativeDateFormatting.string(for:)` of the author date, with the absolute date and time, `date.formatted(date: .abbreviated, time: .shortened)`, as its tooltip) and `sha` (the commit's `shortID` in the theme's code font).
- **history-graph-width**: The graph column MUST be as wide as the widest loaded graph row (`width × CommitGraphCellView.columnWidth`), and never narrower than one graph column.
- **history-ref-badges**: The subject cell MUST carry one badge per ref the data source reports at the commit (`refs(at:)`), titled with the ref's name (`main`, `origin/main`, `v1`), ordered local branches, then remote branches, then tags, keeping the data source's order within a kind. A local branch is a filled badge in the accent colour; a remote branch an outlined badge in the accent colour; a tag an outlined badge in the warning colour. A commit with no refs has no badges.
- **history-selection**: Selecting a row MUST call the delegate's `history(_:didSelect:)` once with that commit; clearing the selection calls it once with nil. `select(commitID:)` MUST select the loaded commit with exactly that id, scroll it into view and call the delegate the same way; an id that is not loaded changes nothing.
- **history-reload**: `reload()` MUST re-read the data source. A selected commit that is still loaded stays selected without a delegate call; a selected commit that is gone is deselected and the delegate is called once with nil, so the owner never keeps showing a commit that left the list.
- **history-paging**: When the table asks for a row in the last 50 loaded rows (index ≥ count − 50), the list MUST call the data source's `loadMore()` once, then reload, and MUST NOT call it again until the number of loaded commits or the data source's query has changed, so the end of the history does not loop and a new search whose first page is the same size still pages.
- **history-search-parse**: `GitHistorySearch.parse(_:)` MUST be pure and return a `GitLogQuery` with the default revisions, limit and skip and at most one filter, from the text trimmed of whitespace: empty → no filter; `author:<x>` (prefix in any case) → `author` `x`; `sha:<x>` (prefix in any case) → no filter; `-S <x>` or `-S<x>` → `pickaxe` `x`; anything else → `messageGrep`, the whole trimmed text. A prefix with nothing after it is no filter. `GitHistorySearch.shaPrefix(_:)` MUST return the lowercased `x` of the `sha:` form and nil for every other form.
- **history-set-query**: `setQuery(_:)` MUST parse the text, and when the parsed query differs from the data source's current query, await the data source's `setQuery` and reload. For the `sha:` form it MUST then select the first loaded commit whose id starts with the prefix (case-insensitively), as `select(commitID:)` does; no match selects nothing. A `setQuery` overtaken by a later one MUST NOT select.
- **history-ui-thread**: The history list MUST be used on the UI thread; every data-source call that waits is awaited, never blocked on.

## Appearance

### Refs sidebar

The topic list's appearance throughout. Icons (SF Symbols): working copy `square.and.pencil`, local branch `arrow.triangle.branch`, remote branch `network`, tag `tag`, stash `tray`, submodule `shippingbox`, worktree `folder`. The ahead/behind badge is the topic list's trailing badge; the checked-out branch uses its emphasized (bold) label.

### History list

A `ThemedTableView` in a `ThemedScrollView`, with a themed header and themed row selection. The subject is body text in the primary colour; the author name and the date are body text in the secondary colour; the sha is the code font in the secondary colour. Ref badges are the toolkit's `Badge`: local branch filled `accent`, remote branch outlined `accent`, tag outlined `warning`, repainted on a theme change. The avatar is 18 points and shows initials only.

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

## Accessibility

### Refs sidebar

The sidebar's root view carries the identifier `git.sidebar`. Rows are the topic list's, so each row's label carries `topic-list.item.<slug of title>` and answers an accessibility press by selecting the row; a badge carries `topic-list.item.<slug>.badge`. Because the identifier comes from the title, a branch name shared by `Branches` and a `Remotes · <remote>` section (`main`) yields the same identifier in each; address one with `dev.py ax --nth`.

### History list

The root view carries `git.history`, the table `git.history.table`. Cells carry `git.history.subject`, `git.history.author`, `git.history.date` and `git.history.sha`; the graph cell keeps its own `commitGraph.cell` and the avatar `avatar`. Badges carry `git.history.badge.local`, `git.history.badge.remote` or `git.history.badge.tag`. Rows are table rows, so `dev.py ax --nth` picks one.

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
- **History, non-UTF-8 messages**: shown as the model decoded them (lossily), never dropped.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `source` | `GitRefsDataSource` | none | Where the sidebar reads refs, stashes, submodules, worktrees and the repository root. |
| `delegate` | `GitRefsSidebarDelegate?` | nil | Told what the user selected. |
| `source` (history) | `GitHistoryDataSource` | none | Where the history list reads commits, graph rows, the query and the refs at a commit, and asks for pages and queries. |
| `delegate` (history) | `GitHistoryDelegate?` | nil | Told which commit is selected, or nil. |

## Deep Linking

Not applicable: the views define no URL scheme, route or navigation destination.

## Localization

Section titles (`Workspace`, `Branches`, `Remotes · <remote>`, `Tags`, `Stashes`, `Submodules`, `Worktrees`) and `Working Copy` are English literals today; ref names, messages and paths are shown verbatim.
The history list's column titles (`Graph`, `Subject`, `Author`, `Date`, `SHA`) are English literals today; relative and absolute dates follow the current locale; the search prefixes (`author:`, `sha:`, `-S`) are not localized.

## Accessibility Options

The topic list's fonts follow the theme; the emphasized row is bold text, not colour alone.

## Feature Flags

Not applicable: the views contain no feature-flag reference.

## Analytics

Not applicable: the views contain no analytics call.

## Privacy

The views show local repository data only and send nothing anywhere.

## Logging

Not applicable: the views log nothing; the model logs failed loads.

## Platform Notes

- **SwiftUI**: A `List` with `Section`s and `.badge(_:)` would serve; this toolkit's views are AppKit.
- **Compose**: A `LazyColumn` with sticky headers; the badge as trailing text.
- **React/Web**: A listbox with grouped options; the badge as a trailing span.
- **AppKit / UIKit**: AppKit: `@MainActor public final class GitRefsSidebarViewController: NSViewController` in `AgenticDeveloperHubSDKMacOS`, hosting a `TopicListViewController` as a child; `@MainActor public final class GitHistoryViewController: NSViewController` on a `ThemedTableView`, and `public enum GitHistorySearch` in `AgenticDeveloperHubSDKCore`. UIKit: not applicable (no git on iOS).
- **WinUI 3**: A `ListView` with grouped items.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/` | confirmed (1.1.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Git/GitHistorySearch.swift` | confirmed (1.1.0) |

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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because the views read data-source protocols and report to delegates; none calls git or knows its window. `unit-test-coverage` passes: `GitRefsSidebarViewControllerTests` covers section order and titles, badges, emphasis, omitted sections, selection of every row kind, reload with a selection kept or dropped, and directory rows restoring the selection, against a fake data source; `GitHistoryViewControllerTests` covers the columns, ref badges per row, the graph width, paging, selection and reload, and `setQuery`, and `GitHistorySearchTests` each search form.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation: the refs sidebar |
| 1.0.1 | 2026-11-13 | Mike Fullerton | Reload falls back to the working copy when the selected ref or stash vanishes; directory rows restore the selection; remote title fallback; vectors 007-011 |
| 1.1.0 | 2026-11-13 | Mike Fullerton | History list: graph, subject with ref badges, author, date, short sha; paging; selection and reload; search parsing and setQuery; vectors 012-018 |
