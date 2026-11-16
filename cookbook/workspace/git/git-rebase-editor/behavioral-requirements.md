
### Rows

- **rebase-rows**: The table MUST show one row per plan entry in the plan's order, oldest at the top, in three columns: `action`, a pop-up of the six actions by name (`pick`, `reword`, `edit`, `squash`, `fixup`, `drop`) with the entry's selected; `sha`, the commit's first 8 characters; `subject`, the entry's subject.
- **rebase-reword-field**: For a `reword` entry the subject cell MUST be an editable text field holding the entry's message (its whole message, body included), and every keystroke and the end of editing MUST set that message in `plan`. Every other action shows the subject as a label; the message is not shown for them.
- **rebase-action-change**: Choosing an action in a row's pop-up MUST set that entry's action in `plan` and redraw the row. Switching to `reword` an entry with no message MUST fill the message with its subject, so the field never starts empty.
- **rebase-reorder**: Rows MUST be draggable to a new place, drop-above as the table names it: the entry moves to sit above the row it was dropped on (after the last for the end), and the moved row is selected. A drop onto its own place moves nothing. The drag MUST carry the row's index on a pasteboard type local to the table (`com.agenticdeveloperhub.git.rebase.row`), and the table MUST accept only drags it started.

### Buttons

- **rebase-start-enablement**: `Start Rebase` MUST be enabled exactly while `plan.validationError` is nil, re-checked after every change, and carry that reason as its tooltip while it is not (no tooltip otherwise). The reason is never shown as inline text.
- **rebase-finish**: `Start Rebase` MUST end any field editing and call `onFinish` with `plan`; `Cancel` MUST call `onFinish` with nil. Either clears `onFinish` first, so it is called at most once. Return is Start's key equivalent and Escape Cancel's.
- **rebase-runs-nothing**: The editor MUST NOT run git; running the plan is the caller's.
- **rebase-ui-thread**: The editor MUST be used on the UI thread.
