
The control and its sibling `UnsavedChangesGuard` compose their labels from
fixed English strings plus the consumer-supplied `subject`; none are
externalized today. The `subject` value itself is the consumer's data and is
out of scope here.

| String Key | Default (en) | Context |
|---|---|---|
| `inlineCommitControl.delete` | "Delete{subject}" | Idle trash `aria-label`/`title` |
| `inlineCommitControl.saveChanges` | "Save changes{subject}" | Commit button `aria-label`/`title` when dirty |
| `inlineCommitControl.discardChanges` | "Discard changes{subject}" | Cancel button `aria-label`/`title` when dirty |
| `inlineCommitControl.confirmDelete` | "Confirm delete{subject}" | Commit button `aria-label`/`title` when a delete is armed |
| `inlineCommitControl.cancelDelete` | "Cancel delete{subject}" | Cancel button `aria-label`/`title` when a delete is armed |
| `inlineCommitControl.deleteArmed` | "Delete armed{subject} — click to keep" | Armed red trash `aria-label`/`title` |
| `inlineCommitControl.commitChangesGroup` | "Commit changes{subject}" | `role="group"` label when dirty |
| `inlineCommitControl.confirmDeletingGroup` | "Confirm deleting{subject}" | `role="group"` label when a delete is armed |
| `unsavedChangesGuard.title` | "Discard unsaved changes?" | Navigation-guard confirm dialog title |
| `unsavedChangesGuard.discard` | "Discard" | Navigation-guard confirm action |
| `unsavedChangesGuard.stay` | "Stay" | Navigation-guard cancel action |

Layout is trailing-aligned (logical, following the writing direction), not
literally right-aligned, so it flips correctly under `dir="rtl"`; the
control's own flex-row markup carries no `right`-specific CSS, but the
recipe's earlier "right-justified" phrasing described the LTR case only.

