
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-views-001 | sidebar-section-order, sidebar-row-titles | A fake source with branches `main` (head) and `dev`, remote branches `origin/main`, `upstream/main`, `origin/dev`, tag `v1`, a stash `WIP on main`, a stash with an empty message at index 1, submodule `lib/sub`, worktrees `/r` (main) and `/w/feature` | Sections `Workspace`, `Branches`, `Remotes · origin`, `Remotes · upstream`, `Tags`, `Stashes`, `Submodules`, `Worktrees`; rows `Working Copy`; `main`, `dev`; `main`, `dev`; `main`; `v1`; `WIP on main`, `stash@{1}`; `lib/sub`; `r`, `feature`. |
| git-views-002 | sidebar-ahead-behind-badge | Branches with (ahead, behind) (2, 1), (2, 0), (0, 3), (0, 0) | Badges `↑2 ↓1`, `↑2`, `↓3`, none. |
| git-views-003 | sidebar-head-bold | `main` is head, `dev` is not | `main` emphasized, `dev` not. |
| git-views-004 | sidebar-empty-sections-omitted | A source with one local branch and nothing else | Sections `Workspace`, `Branches` only. |
| git-views-005 | sidebar-selection | Select each row kind in turn | The delegate receives working copy; ref `refs/heads/main`; ref `refs/remotes/origin/main`; ref `refs/tags/v1`; the stash; directory `<root>/lib/sub`; directory `/w/feature`, once each. |
| git-views-006 | sidebar-reload | Source gains a branch `x`; `reload()` | `Branches` lists `x`; the delegate is not called. |

