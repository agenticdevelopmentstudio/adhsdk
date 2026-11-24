
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | applies-display-treatment, renders-children-as-label | `<SectionLabel>Recent activity</SectionLabel>` | text "Recent activity" is present; its className contains every token of `sectionLabelClass` |
| T2 | bare-div-without-trailing | same as T1 | label is a single div (no justify-between wrapper row) |
| T3 | row-with-trailing, renders-children-as-label | `<SectionLabel trailing={<button>gear</button>}>Stats</SectionLabel>` | outer wrapper's className contains `justify-between`; the label element (text "Stats") and the button named "gear" are both direct children of that wrapper |
| T4 | exports-class-string | import `sectionLabelClass` | it is a string containing `font-mono`, `text-[0.625rem]`, `uppercase`, `tracking-[0.1em]`, `text-apt-text-dim` |
| T5 | merges-classname-on-label | `<SectionLabel className="mb-2">Env</SectionLabel>` | label className contains both `mb-2` and `text-apt-text-dim` |
| T6 | distinct-from-caption-and-title | compare to `fieldCaptionClass` | `sectionLabelClass` differs (`text-[0.625rem]`/`apt-text-dim` vs `text-[0.7rem]`/`apt-text-muted`) |
| T7 | distinct-from-caption-and-title | compare `sectionLabelClass` to `SectionHeader`'s title treatment | `sectionLabelClass` contains no `apt-gold` token — it differs entirely from `SectionHeader`'s gold title color, not only from `fieldCaptionClass` |

