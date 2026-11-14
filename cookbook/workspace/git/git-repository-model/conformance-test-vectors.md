
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-repository-model-001 | start-loads, working-copy-split | Fixture with two commits on `main`, tag `v1`, one staged and one untracked file; `start()` | `refs` has `main` (head) and `v1`; two commits and two graph rows; staged lists the staged file; unstaged lists the untracked file with `isUntracked`; the fake watcher was started. |
| git-repository-model-002 | history-paging | Fixture with five commits, query `limit` 2; `start()`, then `loadMore()` three times | Commits 2, 4, 5; graph rows equal a single layout of all five; the third `loadMore()` asks for nothing more. |
| git-repository-model-003 | refs-at | `main` and tag `v1` on the tip | `refs(at: tip)` lists both; `refs(at: "0000")` is empty. |
| git-repository-model-004 | watcher-drives-refresh, observe | `git checkout -b x` in the fixture, then the fake watcher fires `.refs` | An observer receives a set containing `.refs`; `refs` contains `x` with `isHead`. |
| git-repository-model-005 | unborn | `git init`, one untracked file; `start()` | No commits, no graph rows, no refs; unstaged lists the file. |
| git-repository-model-006 | failures-keep-state | `start()`, delete the repository directory, `refresh` of every kind | Refs, commits and status are unchanged; nothing throws. |
| git-repository-model-007 | watcher-classify | `.git/HEAD`, `.git/refs/heads/main`, `.git/packed-refs`, `.git/index`, `.git/MERGE_HEAD`, `.git/rebase-merge/done`, `.git/objects/ab/cd`, `.git/index.lock`, `.git/refs/heads/main.lock`, `.git/config`, `src/a.swift` | refs+history ×3, working copy, operation ×2, nothing ×4, working copy. |

