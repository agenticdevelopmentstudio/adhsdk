
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
