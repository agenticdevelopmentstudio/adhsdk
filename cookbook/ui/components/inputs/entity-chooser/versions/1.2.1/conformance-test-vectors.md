
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | accept-single-value, delegate-list-behavior | single, open, click "engineering" | `onChange("engineering")`; browser closes |
| T2 | accept-single-value | single, type "design", Enter | `onChange("design")`; browser closes |
| T3 | accept-single-value | single, `value="engineering"`, open, click "design" | `onChange("design")`, replacing the prior value; browser closes |
| T4 | block-create-when-disallowed | single, `allowCreate=false`, type "nope", Enter | no `onChange`; no create row shown |
| T5 | show-trigger-value-single | single, `value="research"` | trigger shows "research" |
| T6 | show-trigger-label-single-when-null | single, `value=null` | trigger shows the configured trigger label (e.g. "Choose…") |
| T7 | render-removable-chips-multi, show-empty-hint-multi | multi, `value=[]` then `["vision"]` | empty hint shown; then "vision" chip shown |
| T8 | trigger-label-only-multi | multi, `value=["vision"]`, closed | trigger reads the trigger label (e.g. "Choose…"), not "vision" |
| T9 | add-to-set-multi | multi, `value=["vision"]`, open, click "attention" | `onChange(["vision","attention"])`; browser stays open |
| T10 | hide-selected-options-multi | multi, `value=["vision"]`, open | "vision" option absent; "attention" and others present |
| T11 | render-removable-chips-multi | multi, `value=["vision","attention"]`, click "Remove vision" | `onChange(["attention"])` |
| T12 | prevent-duplicates-multi | multi, `value=["vision"]`, type "vision", Enter | no `onChange` |
| T13 | host-mode-renders-trigger-only | multi, `selectionPlacement="host"` | only the trigger renders; no chip group |
| T14 | respect-disabled | `disabled=true` | trigger non-interactive; chip remove buttons non-interactive |

