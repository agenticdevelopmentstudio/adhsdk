
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | copies-gettext-at-click, labels-from-prop | render `<CopyButton getText={() => "rows"} label="Copy rows" />`, click the button | `navigator.clipboard.writeText` called with `"rows"`; button's accessible name is `"Copy rows"` |
| T2 | flashes-success-check, sets-copied-title | after a successful click (T1) | button `title` becomes `"Copied!"`; glyph is the `Check` icon |
| T3 | skips-empty-text | `getText={() => ""}`, click | `writeText` NOT called; no success flash |
| T4 | reverts-after-timeout, idle-title-from-label | after a successful copy, advance 1200 ms | `title` returns to `label`; glyph reverts to `Copy` |
| T5 | swallows-copy-failure, idle-title-from-label | `writeText` rejects, click | no success state; no error thrown; `title` stays `label` |
| T6 | reflects-current-selection | `getText` reads a variable mutated between render and click | `writeText` receives the value current at click, not at render |
| T7 | decorative-icon, labels-from-prop | render `<CopyButton getText={…} label="Copy" />` | rendered svg glyph carries `aria-hidden`; accessible name is `"Copy"` |
| T8 | forwards-classname | `className="ml-2"` | button element carries the `ml-2` class |
| T9 | reverts-after-timeout | after a successful copy, click again (also successful) at 1000 ms, before the first timer fires | the check persists until 2200 ms from the second click (timer is cleared and re-armed), not 1200 ms from the first |
| T10 | reverts-after-timeout | unmount the component before the 1200 ms timer fires | the pending timer is cleared on cleanup; no state update occurs after unmount |

