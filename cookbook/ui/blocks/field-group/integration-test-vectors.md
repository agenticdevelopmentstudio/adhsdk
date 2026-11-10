
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-title, render-title-as-heading | `title="Profile"` | An `<h3>` carrying the `fieldCaptionClass` classes (`font-mono uppercase tracking-wider text-apt-text-muted`) renders in the top row, containing "Profile" |
| T2 | render-trailing-when-set | `trailing={<Button>Reset</Button>}` | The Reset button renders right-aligned in the title row, opposite the title |
| T3 | render-trailing-when-set | `trailing` omitted | The title row shows the title alone; no trailing element exists in the DOM |
| T4 | stack-children | two `Field` children | Both Fields render stacked below the title row with the group's `gap-3` |
| T5 | bordered-card | any props | The root `section` has the bordered rounded recessed-surface treatment |
| T6 | merge-classname | `className="mt-6"` | Root keeps `flex flex-col … border …` and adds `mt-6` |

