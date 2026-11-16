
The fixture is a plan of three entries `commit 0`, `commit 1`, `commit 2`, all pick, each with the message `commit <n>`, a blank line, `body <n>`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-rebase-editor-001 | rebase-rows | the fixture | three rows in order; columns `action`, `sha`, `subject`; each pop-up `pick` of the six names; shas the first 8 characters; subjects `commit 0` to `commit 2`, labels |
| git-rebase-editor-002 | rebase-action-change | choose `drop` in row 1's pop-up | actions `pick`, `drop`, `pick` |
| git-rebase-editor-003 | rebase-reword-field | reword row 0; type `renamed` | an editable field `git.rebase.message` holding `commit 0\n\nbody 0`; then the message `renamed` |
| git-rebase-editor-004 | rebase-action-change | row 2 with no message; reword it | its message `commit 2`; Start enabled |
| git-rebase-editor-005 | rebase-reorder | move 0 to 3; 2 to 0; 1 to 1 and 1 to 2; 2 to 1 | `1, 2, 0`; back to `0, 1, 2`; unchanged; `0, 2, 1` with row 1 selected |
| git-rebase-editor-006 | rebase-reorder | row 2's pasteboard writer | the local type carries `2`, read back as 2 |
| git-rebase-editor-007 | rebase-start-enablement | squash row 0; then pick it | disabled with the validation reason as tooltip; enabled, no tooltip |
| git-rebase-editor-008 | rebase-start-enablement | reword row 1; message `   `; then `fine` | enabled; disabled with the reason; enabled |
| git-rebase-editor-009 | rebase-finish | Cancel, twice | `onFinish(nil)` once |
| git-rebase-editor-010 | rebase-finish | fixup row 0 and Start; then pick row 0, drop row 2, move 1 to 0, Start | nothing; then `onFinish` once with the plan, actions `pick`, `pick`, `drop` |
| git-rebase-editor-011 | rebase-reword-field, rebase-finish | reword row 0; `insertNewline:` then `insertLineBreak:` in its field at the end of `subject` | both handled; the text is `subject\n\n`; `onFinish` not called; `cancelOperation:` not handled. |
| git-rebase-editor-012 | rebase-reword-field | reword row 0 (`commit 0\n\nbody 0`); then five lines; then `one` | taller than a plain row; taller still; a plain row again. |
| git-rebase-editor-013 | rebase-move-buttons | nothing selected; select row 0; Move Down twice; Move Up twice | both disabled; Up disabled; order 1 0 2 then 1 2 0 with Down disabled; order 0 1 2, row 0 selected, Up disabled. |
| git-rebase-editor-014 | rebase-reword-field | reword row 0 with one line long enough to wrap; then double the subject column's width | `subjectWidth` equals the cell frame's width; taller than a plain row and at least the field's cell height at that width; shorter after the resize. |
| git-rebase-editor-015 | rebase-move-buttons, rebase-reword-field | reword row 0 editing with the caret at 3; ⌥⌘↓ | the row moved to 1; its field still editing with the caret at 3 and the text `commit 0\n\nbody 0`. |
| git-rebase-editor-016 | rebase-move-buttons | an editor whose view is not loaded; `moveEntry(from: 0, to: 3)` | order 1 2 0; the view still not loaded. |
