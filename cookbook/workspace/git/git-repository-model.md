---
id: a2394ca0-3988-410b-9fc8-e0c9e253fc94
title: "Git Repository Model"
type: ingredient
version: 1.1.0
status: review
language: en
created: 2026-11-13
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A main-actor model of one repository (refs, paged history with graph rows, staged and unstaged changes, content on demand) behind four view protocols, refreshed by kind from a debounced FSEvents watcher of the working tree, git directory and common directory."
platforms:
  - swift
  - macos
tags:
  - git
  - model
  - file-watching
depends-on:
  - 779ac6ea-9ef5-4fb0-8ed9-dc6b9d617344
  - 750fe184-d20a-4b58-867b-3edd094d59b4
related:
  - 9a4aa2a8-c01b-4cec-b789-6c89c100d8d3
  - 1b64553a-ab58-4154-b9d5-30f34eb33caf
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Model/ (adhsdk)
approved-by: ""
approved-date: ""
---

# Git Repository Model

## Overview

The one place a git window's views read a repository from. `GitRepositoryModel` is a main-actor model over one working tree: it loads refs, stashes, submodules and worktrees; history a page at a time with its graph rows from the [commit graph layout](cookbook:750fe184-d20a-4b58-867b-3edd094d59b4); and the working copy split into staged and unstaged changes. It hands diffs, file contents, blame and file history through on demand. Every call goes through the [git client](cookbook:779ac6ea-9ef5-4fb0-8ed9-dc6b9d617344). Views see it through four narrow protocols (refs, history, working copy, content), so each can be tested against a fake. `GitRepositoryWatcher` watches the working tree, the git directory and the common directory, sorts each changed path into a kind of change (refs, history, working copy, in-progress operation), and reports the union after 300 ms of quiet. The model then reloads only what those kinds cover and tells its observers what changed.

## Behavioral Requirements

- **start-loads**: `start()` MUST start the watcher and load refs, stashes, submodules, worktrees, the first history page with its graph rows, and the working-copy status.
- **history-paging**: `loadMore()` MUST ask for the next page (`skip` = commits loaded), append its commits, and append their graph rows from the same layout, so paged rows equal one long load. A page shorter than the query's `limit` MUST end paging; `loadMore()` while a page is loading or after paging ended MUST do nothing.
- **set-query**: `setQuery(_:)` MUST replace the query, clear commits, graph rows and paging, and load the first page of the new query.
- **refs-at**: `refs(at:)` MUST return every ref whose `target` is the commit id, in ref order, and none for an unknown id.
- **working-copy-split**: `staged` and `unstaged` MUST come from `GitClient.status`'s per-column maps, sorted by path; untracked files MUST be unstaged with `isUntracked` true; a file changed in both columns MUST appear in both lists.
- **refresh-scope**: `refresh(_:)` MUST reload `.refs` → refs, stashes, submodules and worktrees; `.history` → the history from the top, covering at least as many commits as were loaded, with the graph rebuilt; `.workingCopy` and `.operation` → the working-copy status.
- **watcher-drives-refresh**: Every change set the watcher reports MUST be passed to `refresh(_:)` on the main actor.
- **observe**: After a refresh, every live observer MUST be called on the main actor with the kinds whose data reloaded, and with history after `setQuery(_:)` and after each page `loadMore()` appends; dropping the token returned by `observe(_:)` MUST stop its calls. No call is made when nothing reloaded.
- **failures-keep-state**: A git call that fails MUST leave that part's last loaded value in place and be logged; `start()` and `refresh(_:)` MUST NOT throw. A repository deleted under the model keeps showing what it last loaded. A load that was cancelled (a search the window replaced, whose `git log` was terminated) is not a failure and MUST be logged at debug level only.
- **refs-partial**: Refs, stashes, submodules and worktrees MUST load independently, so one that fails costs only itself: a failed source is logged and keeps its last value, except submodules, which a failure empties rather than leave stale (a submodule list git refuses over an orphan gitlink). The sidebar's observers are told when any source was applied.
- **stale-results-dropped**: A history result that a later `setQuery(_:)` or refresh superseded MUST be discarded, and so MUST a page from `loadMore()` that finishes after one.
- **unborn**: A repository with no commits MUST load an empty history and no refs without failing, and its working copy MUST list its files.
- **content-pass-through**: `diff`, `changedFiles`, `contents`, `blame` and `fileHistory` MUST call the git client in the model's root; `contents` MUST pass its `maximumBytes` through, so an oversized file is never read; `fileHistory` MUST log, at info level, a history that reaches the client's file-history limit, since the list then ends there; `fileHistory` MUST follow renames and return the client's `fileHistory(path:in:)` entries, each commit with the file's path at that commit; `commit(_:)` MUST return a loaded commit by id, or nil.
- **watcher-classify**: `classify(relativePath:)` MUST map a path inside the git directory (written `.git/<path>`) as follows: `HEAD`, `packed-refs`, `refs` and anything under `refs/` → refs and history; `index` → working copy; `MERGE_HEAD`, `CHERRY_PICK_HEAD`, `rebase-merge`, `rebase-apply` and anything under the last two → operation; `worktrees/<name>` (the directory itself) and `worktrees/<name>/HEAD` (another worktree switching branch) → refs; anything under `objects/`, any name ending `.lock`, and everything else inside the git directory → nothing. Any path outside the git directory MUST map to working copy.
- **watcher-paths**: The watcher MUST watch the working tree, the git directory and the common directory through the toolkit's file-system watcher, MUST exclude the common directory's `objects`, and MUST write a path under the git directory or the common directory as `.git/<path relative to it>` (the git directory wins when both contain it) before classifying it.
- **watcher-debounce**: The watcher MUST call `onChange` once, 300 ms after the last event, with the union of the kinds since its last call, and MUST NOT call it for events that classify to nothing. `stop()` MUST stop the stream and drop a pending call.
- **main-actor**: The model MUST be used on the main actor; every git call MUST be `async` and never block it.
- **deferred-watcher**: The window's watcher (`GitDeferredRepositoryWatcher`) MUST ask git for the git and common directories before it makes the real watcher, one `rev-parse --path-format=absolute` call each, read whole. Each `start` MUST stop a watcher it already made before making another, and only the latest `start` makes one: a `start` overtaken by a `stop` or another `start` before git answers makes nothing.
- **watcher-canonical-roots**: The watcher MUST canonicalise its three roots the way the file-system event stream spells paths (symlinks resolved, `/private` kept), so a repository under a symlinked directory such as the temporary directory still reports changes and still excludes `objects/`.
## Appearance

Not applicable: the model draws nothing; the git window's views do.

## States

Not applicable: the model is a non-visual component. It holds the last loaded refs, stashes, submodules, worktrees, history page and status, and whether paging has ended.

## Accessibility

Not applicable: the model presents no view.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-repository-model-001 | start-loads, working-copy-split | Fixture with two commits on `main`, tag `v1`, one staged and one untracked file; `start()` | `refs` has `main` (head) and `v1`; two commits and two graph rows; staged lists the staged file; unstaged lists the untracked file with `isUntracked`; the fake watcher was started. |
| git-repository-model-002 | history-paging | Fixture with five commits, query `limit` 2; `start()`, then `loadMore()` three times | Commits 2, 4, 5; graph rows equal a single layout of all five; the third `loadMore()` asks for nothing more. |
| git-repository-model-003 | refs-at | `main` and tag `v1` on the tip | `refs(at: tip)` lists both; `refs(at: "0000")` is empty. |
| git-repository-model-004 | watcher-drives-refresh, observe | `git checkout -b x` in the fixture, then the fake watcher fires `.refs` | An observer receives a set containing `.refs`; `refs` contains `x` with `isHead`. |
| git-repository-model-005 | unborn | `git init`, one untracked file; `start()` | No commits, no graph rows, no refs; unstaged lists the file. |
| git-repository-model-006 | failures-keep-state | `start()`, delete the repository directory, `refresh` of every kind | Refs, commits and status are unchanged; nothing throws. |
| git-repository-model-007 | watcher-classify | `.git/HEAD`, `.git/refs/heads/main`, `.git/packed-refs`, `.git/index`, `.git/MERGE_HEAD`, `.git/rebase-merge/done`, `.git/objects/ab/cd`, `.git/index.lock`, `.git/refs/heads/main.lock`, `.git/config`, `src/a.swift` | refs+history ×3, working copy, operation ×2, nothing ×4, working copy. |
| git-repository-model-008 | watcher-classify | `.git/worktrees/other`, `.git/worktrees/other/HEAD`, `.git/worktrees/other/index`, `.git/worktrees/other/HEAD.lock` | refs ×2, nothing ×2. |
| git-repository-model-009 | watcher-canonical-roots | The real watcher started on a fixture under the temporary directory, then `git checkout -b x` | `onChange` receives a set containing `.refs` within 10 s. |
## Edge Cases

- **Null / empty input**: An unborn repository loads empty history and refs; a repository with no stashes, submodules or linked worktrees loads empty lists (worktrees still lists the main one).
- **Boundary values**: A history shorter than one page ends paging after the first load; a refresh after paging reloads at least as many commits as were shown, so the list does not shrink under the user.
- **Concurrent access**: Main actor only. Overlapping loads are ordered by a generation counter: the newest request's result wins, and an older one is dropped.
- **Error states**: A failed git call keeps that part's last value and is logged, never thrown. A deleted repository keeps its last state.
- **Offline / disconnected state**: Not applicable: no network.
- **Cancellation**: A superseded history load still runs to completion, and its result is dropped.
- **Linked worktrees**: The git directory (`<common>/worktrees/<name>`) and the common directory lie outside the working tree, so all three are watched.
- **Event storms**: A checkout or rebase writes many files; the 300 ms debounce folds them into one refresh, and lock files and objects never trigger one.
- **Symlinked location**: A repository under `/tmp` or `/var` is reported by the event stream as `/private/...`; the roots are canonicalised with realpath to match, never with a resolver that strips `/private`.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `root` | `URL` | none | The working tree the model reads. |
| `client` | `GitClient` | `.shared` | The door every git call goes through. |
| `watcher` | `GitRepositoryWatching` | none | What reports changes; `GitRepositoryWatcher` in the app, a fake in tests. |
| `query` | `GitLogQuery` | `GitLogQuery()` (all branches, tags, remotes and HEAD; 500 per page) | Which history to load; replaced with `setQuery(_:)`. |
| debounce | `TimeInterval` | 0.3 s | The watcher's quiet period before it reports. |

## Deep Linking

Not applicable: the model defines no URL scheme, route or navigation destination.

## Localization

Not applicable: the model has no user-facing text.

## Accessibility Options

Not applicable: the model presents nothing.

## Feature Flags

Not applicable: the model contains no feature-flag reference.

## Analytics

Not applicable: the model contains no analytics call.

## Privacy

The model reads the local repository only and sends nothing anywhere. Its log lines name the failing verb, not file contents.

## Logging

A failed load logs one line at error level naming the part (refs, history, status) and the error's log-facing description, which keeps paths out of the log.

## Platform Notes

- **SwiftUI**: The model could be `@Observable`; this toolkit's views are AppKit and use `observe(_:)` instead.
- **Compose**: A `ViewModel` exposing `StateFlow`s per part, with a `WatchService` on the three directories.
- **React/Web**: Not applicable in a browser. An Electron host runs `chokidar` on the three directories and pushes change kinds over IPC.
- **AppKit / UIKit**: AppKit: `@MainActor final class GitRepositoryModel` in `AgenticDeveloperHubSDKMacOS`; the watcher wraps the toolkit's FSEvents `FileSystemWatcher` (several roots, one stream). UIKit: not applicable (no git on iOS).
- **WinUI 3**: `System.IO.FileSystemWatcher` per directory feeding the same classifier.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Model/` | confirmed (1.0.1) |

## Design Decisions

**Decision**: The model is reached through four protocols, one per view family, rather than as one concrete type.
**Rationale**: Each view needs a narrow slice, and a fake of that slice is a few lines, so view tests need no repository.
**Approved**: pending

**Decision**: The watcher reports kinds of change, and the model reloads by kind rather than by path.
**Rationale**: git's own files say which part changed (a ref, the index, an operation's state file); reloading a whole part is cheap and avoids patching state from paths.
**Approved**: pending

**Decision**: A failed load keeps the last value instead of clearing it or surfacing an error.
**Rationale**: A repository deleted or moved under an open window should leave the window readable, and a transient failure (a lock held by another git) heals on the next event.
**Approved**: pending

**Decision**: Staged and unstaged come from the existing status parser, which keeps each column too, not from a second parser.
**Rationale**: One porcelain parser; the merged map the file browser uses and the per-column maps come from the same pass.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |

`separation-of-concerns` passes because git runs only through the client, change detection only in the watcher, and views see protocols. `unit-test-coverage` passes: `GitRepositoryModelTests` covers loading, paging, refs by commit, an external branch switch, an unborn repository, a deleted repository and path classification, against fixture repositories and a fake watcher. `data-integrity` passes because superseded results are dropped and a failed load never clears loaded state.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.0 | 2026-11-14 | Mike Fullerton | Final review: refs, stashes, submodules and worktrees load independently; cancelled loads log at debug; contents pass a size cap; a capped file history is logged; the deferred watcher makes one watcher per latest start |
| 1.0.1 | 2026-11-14 | Mike Fullerton | fileHistory returns the client's entries, each commit with the file's path at that commit |
| 1.0.0 | 2026-11-13 | Mike Fullerton | Initial creation |
