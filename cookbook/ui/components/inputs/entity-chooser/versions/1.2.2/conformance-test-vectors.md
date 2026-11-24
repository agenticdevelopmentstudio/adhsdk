
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | accept-single-value, close-on-accept-single, delegate-list-behavior | single, open, click "engineering" | `onChange("engineering")`; browser closes |
| T2 | accept-single-value, close-on-accept-single | single, type "design", Enter | `onChange("design")`; browser closes |
| T3 | accept-single-value, close-on-accept-single | single, `value="engineering"`, open, click "design" | `onChange("design")`, replacing the prior value; browser closes |
| T4 | block-create-when-disallowed | single, `allowCreate=false`, type "nope", Enter | no `onChange`; no create row shown |
| T5 | show-trigger-value-single | single, `value="research"` | trigger shows "research" |
| T6 | show-trigger-label-single-when-null | single, `value=null` | trigger shows the configured trigger label (e.g. "Choose…") |
| T7 | render-removable-chips-multi, show-empty-hint-multi | multi, `value=[]` then `["vision"]` | empty hint shown; then "vision" chip shown |
| T8 | trigger-label-only-multi | multi, `value=["vision"]`, closed | trigger reads the trigger label (e.g. "Choose…"), not "vision" |
| T9 | add-to-set-multi, keep-open-on-accept-multi | multi, `value=["vision"]`, open, click "attention" | `onChange(["vision","attention"])`; browser stays open |
| T10 | hide-selected-options-multi | multi, `value=["vision"]`, open | "vision" option absent; "attention" and others present |
| T11 | render-removable-chips-multi | multi, `value=["vision","attention"]`, click "Remove vision" | `onChange(["attention"])` |
| T12 | prevent-duplicates-multi | multi, `value=["vision"]`, type "vision", Enter | no `onChange` |
| T13 | host-mode-renders-trigger-only | multi, `selectionPlacement="host"` | only the trigger renders; no chip group |
| T14 | respect-disabled | single, `disabled=true` | trigger non-interactive |
| T15 | respect-disabled | multi, `value=["vision"]`, `disabled=true` | trigger non-interactive; the "Remove vision" button non-interactive |
| T16 | chips-remove-calls-onRemove | `EntitySelectionChips`, `values=["vision","attention"]`, click "Remove vision" | `onRemove("vision")` |
| T17 | chips-remove-calls-onRemove | `EntitySelectionChips`, `disabled=true`, click "Remove vision" | no `onRemove` |
| T18 | chips-omit-empty-hint-when-unset | `EntitySelectionChips`, `values=[]`, no `emptySelectionLabel` | nothing renders |
| T19 | chips-omit-empty-hint-when-unset | `EntitySelectionChips`, `values=[]`, `emptySelectionLabel="None"` | the hint "None" renders in a labelled group |
| T20 | prevent-duplicates-multi | multi, `value=["vision"]`, type "Vision", Enter | `onChange(["vision","Vision"])`: comparison is case-sensitive |

