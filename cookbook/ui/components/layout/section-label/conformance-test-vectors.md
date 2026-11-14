
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | applies-display-treatment, renders-children-as-label | `<SectionLabel>Recent activity</SectionLabel>` | text "Recent activity" is present; its className contains every token of `sectionLabelClass` |
| T2 | bare-div-without-trailing | same as T1 | label is a single div (no justify-between wrapper row) |
| T3 | row-with-trailing, renders-children-as-label | `<SectionLabel trailing={<button>gear</button>}>Stats</SectionLabel>` | outer wrapper's className contains `flex items-center justify-between gap-2`; the label element (text "Stats") and the button named "gear" are both direct children of that wrapper |
| T4 | exports-class-string | import `sectionLabelClass` | it is a string containing every token of the treatment in `applies-display-treatment` |
| T5 | merges-classname-on-label | `<SectionLabel className="mb-2">Env</SectionLabel>` | label className contains both `mb-2` and `text-apt-text-dim` |
| T6 | distinct-from-caption-and-title | compare to `fieldCaptionClass` | `sectionLabelClass` differs (`text-[0.625rem]`/`apt-text-dim` vs `text-[0.7rem]`/`apt-text-muted`) |
| T7 | distinct-from-caption-and-title | compare `sectionLabelClass` to the className of the `h2` rendered by `<SectionHeader title="x" />` (`font-mono text-sm font-medium tracking-wide text-apt-gold`) | `sectionLabelClass` contains no `apt-gold` token and no `text-sm` — it differs entirely from `SectionHeader`'s gold title treatment, not only from `fieldCaptionClass` |

