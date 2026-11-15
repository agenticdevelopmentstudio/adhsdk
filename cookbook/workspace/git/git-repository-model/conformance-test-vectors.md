
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
| git-repository-model-010 | perform-refreshes, observe | One commit and an untracked `a.txt`; `perform(.stage(paths: ["a.txt"]))` | `staged` lists `a.txt`; an observer received a set containing `.workingCopy`; `isPerforming` is false. |
| git-repository-model-011 | perform-refreshes | `perform(.checkout(branch: "nope"))` | Throws a `GitClientError`; observers were still told of the refresh. |
| git-repository-model-012 | is-performing | A client whose executable sleeps 0.3 s before running git; `perform(.stage(...))` started in a task, read after 100 ms | `isPerforming` true while it runs, false once it returns. |
| git-repository-model-013 | head-branch, has-commits | `git init`, `start()`; then a commit and a refresh of every kind | nil and false; then `main` and true. |
| git-repository-model-014 | reads-pass-through | A clone of a bare remote; `lastCommitMessage()`, a commit, then `remotes()` and `lastCommitMessage()` | nil; then `["origin"]` and the commit's message. |
| git-repository-model-015 | watcher-classify | `.git/REVERT_HEAD`, `.git/sequencer`, `.git/sequencer/todo` | Operation, each. |
| git-repository-model-016 | operation-state, operation-state-observed | `main` and `topic` both changing `a.txt`; `perform(.merge(ref: "topic", fastForward: .allowed))`; then `perform(.operation(.merge, .abort))` | Throws, `operationState` is merging with `topic`'s commit and an observer was told `.operation`; then none. |
| git-repository-model-017 | operation-state | A conflicting merge started by the fixture outside the model; the watcher reports `.operation` | `operationState` is merging. |
