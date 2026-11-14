
### Refs sidebar

- **sidebar-section-order**: The sidebar MUST list its sections in this order: `Workspace` (one row, `Working Copy`), `Branches` (local branches), one section per remote titled `Remotes · <remote>` (in the order each remote first appears in the refs), `Tags`, `Stashes`, `Submodules`, `Worktrees`. Rows keep the data source's order within a section.
- **sidebar-empty-sections-omitted**: A section with no rows MUST be left out, header included; `Workspace` always has its one row.
- **sidebar-row-titles**: A local branch or tag row MUST be titled with its name; a remote branch row with its name less the `<remote>/` prefix, or its whole name when nothing follows the prefix; a stash row with its message, or `stash@{N}` when the message is empty; a submodule row with its path; a worktree row with its directory's last path component. Bare worktrees MUST be left out.
- **sidebar-ahead-behind-badge**: A local branch row MUST carry a badge `↑n ↓m`, each half present only when its count is non-zero (`↑2 ↓1`, `↑2`, `↓1`), and no badge when both are zero. Other rows carry none.
- **sidebar-head-bold**: The checked-out branch's row MUST be emphasized (bold); no other row is.
- **sidebar-selection**: Selecting a row MUST call the delegate once: the working copy → `sidebarDidSelectWorkingCopy`; a branch, remote branch or tag → `didSelect ref`; a stash → `didSelectStash`; a submodule → `open directory` with the repository root joined with the submodule's path; a worktree → `open directory` with the worktree's directory. A submodule or worktree row is an action, not a place: after it opens, the previous selection, when there is one, is restored, so the same row can be chosen again. Clearing the selection calls nothing.
- **sidebar-reload**: `reload()` MUST rebuild every section from the data source's current values, keeping the selected row selected when its id is still present (by the topic list's restore-by-id) without calling the delegate. When the selected row is gone, the sidebar MUST select `Working Copy` and call `sidebarDidSelectWorkingCopy` once, so the owner never keeps showing a ref or stash that no longer exists.
- **sidebar-ui-thread**: The sidebar MUST be used on the UI thread.

