
| Version | Date | Author | Summary |
|---------|------|--------|---------|
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
