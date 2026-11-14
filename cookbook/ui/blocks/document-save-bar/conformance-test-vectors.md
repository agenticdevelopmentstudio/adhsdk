
The tests beside the source are `documentSaveBar.test.tsx`; each vector names the test it comes from where one exists.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| save-bar-001 | render-button-bar (test: "is the standard editing button bar, with Cancel and Save and nothing else") | Clean document | A toolbar named "Editing actions" holds exactly two buttons, "Cancel" then "Save" |
| save-bar-002 | cancel-enabled-by-dirty, save-enabled-by-dirty (test: "disables Cancel and Save with nothing to save") | `dirty=false` | Save and Cancel are both disabled |
| save-bar-003 | cancel-reverts, save-saves (test: "wires Save and Cancel when dirty, and holds both while saving") | `dirty=true`; click Save, then Cancel | `save` and `revert` are each called (the test asserts called, not a count) |
| save-bar-004 | saving-state (test: same) | `dirty=true`, `saving=true` | A disabled button named "Saving…" and a disabled Cancel |
| save-bar-005 | gone-notice, noun-default, changed-notice (test: "names the document in its default notices") | `noun="note"`, `gone=true`, `changedElsewhere=true` | Alert reads "This note no longer exists."; text "This note changed since it was opened." is shown |
| save-bar-006 | messages-override (test: "takes host wording for any notice") | `changedElsewhere=true`, `messages.changedElsewhere="This file changed on disk."` | Text "This file changed on disk." is shown |
| save-bar-007 | conflict-warning, reload-theirs, overwrite, changed-notice-hidden-on-conflict (test: "offers Reload theirs and Overwrite on a conflict, and hides the changed notice under it") | `noun="file"`, `dirty=true`, `changedElsewhere=true`, `conflict={text:"t",version:"v9"}`; click Reload theirs, then Overwrite | "Someone else saved this file." shown inside an alert; no "changed since" text; `takeTheirs` and `overwrite` are each called (the test asserts called, not a count) |
| save-bar-008 | save-error-notice, error-lines-alert (test: "shows a failed save inline as an alert") | `saveError="disk full"` | One alert reading "Save failed: disk full" |
| save-bar-009 | overwrite-disabled-while-saving | `conflict` set, `saving=true` | "Overwrite" disabled; "Reload theirs" enabled |
| save-bar-010 | accept-class-name, wrapper-slot | `className="mt-4"` | The element with `data-slot="document-save-bar"` has class `mt-4` |
| save-bar-011 | conflict-warning | `conflict` null | No `data-slot="document-save-conflict"` element renders |
| save-bar-012 | notices-leading | `gone=true`, `changedElsewhere=true`, `saveError="x"` | The leading area holds, in order, the gone line, the changed line, then "Save failed: x" |
| save-bar-013 | messages-override | `noun="file"`, `messages.conflict="Taken."`, `conflict` set | The warning reads "Taken." and not "Someone else saved this file." |

