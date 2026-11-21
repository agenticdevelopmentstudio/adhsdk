
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-count-text, render-percent | `<ProgressSummary done={1} total={3} />` | "1 of 3 items done" and "33%" |
| T2 | render-count-text | `done={2} total={4} label="steps"` | "2 of 4 steps done" |
| T3 | label-bar | `done={2} total={4}` | a progressbar named "2 of 4 items done", `aria-valuenow` 50 |
| T4 | render-percent, green-when-complete | `done={0} total={0}` | "0%", indicator not green |
| T5 | green-when-complete | `done={3} total={3}` and `done={2} total={3}` | green only for the first |
| T6 | render-percent | `done={199} total={200}` | "99%" |
| T7 | forward-host-attributes | `className="mt-4" data-testid="ps"` | the root carries both |
