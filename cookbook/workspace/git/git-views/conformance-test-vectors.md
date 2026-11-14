
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

