
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | renders-badge-body, forwards-chip-props | `<RemovableChip removeLabel="Remove x" onRemove={fn} id="c1">x</RemovableChip>` | a `data-slot="badge"` element containing "x" and carrying `id="c1"` |
| T2 | renders-remove-button, remove-button-named | same as T1 | a `<button type="button">` with `aria-label="Remove x"` |
| T3 | invokes-onremove-on-click | click the remove button | `onRemove` called once |
| T4 | stateless-removal | after T3 without consumer re-render | the chip is still in the DOM (removal is the consumer's job) |
| T5 | applies-badge-variant | `variant="success"` | the `Badge` element carries the `border-apt-green` and `text-apt-green` classes |
| T6 | disabled-blocks-remove | `disabled` then click the ✕ | button is `disabled`; `onRemove` NOT called |
| T7 | remove-icon-decorative | inspect the `X` glyph | the icon carries `aria-hidden` |
| T8 | remove-button-named, keyboard-operable (Playwright) | query by role `button` name "Remove x", then press Enter/Space while it has focus | the ✕ is found by its accessible name and `onRemove` fires on Enter/Space |

