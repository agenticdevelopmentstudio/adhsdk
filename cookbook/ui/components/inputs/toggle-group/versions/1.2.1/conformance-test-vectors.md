
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | renders-item-toggle-buttons | render group with items `left`/`center`/`right` | three focusable toggle buttons, one per value |
| T2 | marks-selected-item-pressed, single-select-via-value-array | `value={["center"]}` | the `center` item has `data-pressed`; the others do not |
| T3 | pressed-item-gold-fill | `value={["center"]}` | the pressed item carries `bg-apt-gold` + `text-apt-bg` |
| T4 | emits-value-on-select | click the `right` item | `onValueChange` called with `["right"]` |
| T5 | single-select-via-value-array | in the demo, click `right` then read `next[0]` | selection becomes `right`; exactly one item pressed |
| T6 | keyboard-operable (Playwright) | focus first item, press ArrowRight then Enter | focus moves to next item; that item activates |
| T7 | focus-visible-ring (Playwright) | tab focus onto an item | item shows `ring-2 ring-apt-gold/40` |
| T8 | disabled-item-inert | render an item with `disabled` and click it | no `onValueChange`; item renders `opacity-50` |
| T9 | single-select-keeps-selection | in the demo, click the already-pressed `right` item | `onValueChange` is called with `[]`; the single-select consumer ignores the empty array and its selection stays at `right` |
| T10 | disabled-item-inert, keyboard-operable | render `left`/`center` (disabled)/`right`, focus `left`, press ArrowRight | focus moves to `right`, skipping the disabled `center` item |

