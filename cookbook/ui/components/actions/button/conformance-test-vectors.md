
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | press-on-pointerdown-inside | `pointerdown` on the button | `data-pressed` present |
| T2 | release-clears-pressed | `pointerdown` then `pointerup` | `data-pressed` absent |
| T3 | leave-while-held-clears-pressed | `pointerdown` then `pointerleave` | `data-pressed` absent |
| T4 | reenter-while-held-restores-pressed | after T3, `pointerenter` (still held) | `data-pressed` present |
| T5 | forwards-consumer-pointer-handlers | `pointerdown` with `onPointerDown` prop | consumer handler called once AND `data-pressed` present |
| T6 | release-outside-ends-hold | `pointerdown`, `pointerleave`, window `pointerup` | hold ends; a later `pointerenter` does NOT re-press |
| T7 | keyboard-activates (Playwright) | focus, press Enter/Space | click fires; no pointer dip |
| T8 | haspopup-suppresses-dip (Playwright) | `pointerdown` on `aria-haspopup` button | no `translate-y-px` dip |
| T9 | cancel-clears-pressed | `pointerdown` then `pointercancel` | `data-pressed` absent |
| T10 | no-pointer-capture | `pointerdown` on the button | `element.hasPointerCapture(pointerId)` is `false` throughout |
| T11 | stable-public-api | render `<Button variant="secondary" size="lg" data-testid="b"/>` | root node has `data-slot="button"`; no runtime error |
| T12 | supports-eight-variants, warning-variant-uses-warning-role | render `<Button variant="warning">` | class list includes `bg-apt-orange/15` and `text-apt-orange` |
| T13 | defaults-to-default-variant-and-size | render `<Button/>` with no props | class list includes `bg-primary` and `h-8` |
| T14 | respects-ancestor-min-height-var | render `<Button size="sm"/>` under an ancestor with `style="--adh-button-min-height:44px"` | computed `min-height` is `44px` |
| T15 | icon-sizes-square-to-height-floor, respects-ancestor-min-width-var | render `<Button size="icon"/>` under an ancestor with `style="--adh-button-min-height:44px"` | computed `min-width` is `44px` |
| T16 | icon-svgs-non-interactive | render `<Button><svg data-testid="icon"/></Button>` | svg computed `pointer-events` is `none`; computed `flex-shrink` is `0` |
| T17 | unsized-icon-svgs-scale-with-button-size | render default-size `<Button><svg data-testid="icon"/></Button>` (svg has no `size-*` class) | svg renders at 16×16px |
| T18 | consumer-classname-precedence | render `<Button className="bg-brand-500"/>` | class list includes `bg-brand-500`; class list does not include `bg-primary` |
| T19 | respects-ancestor-min-width-var | render `<Button size="default"/>` (non-icon) under an ancestor with `style="--adh-button-min-width:120px"` | computed `min-width` is `120px` |
| T20 | pressed-visual-from-data-attr | render `<Button/>`, trigger native `:active` (e.g. `mousedown` without a `pointerdown` event reaching the pressed-tracking handler) without `data-pressed` being set | class list does not include `translate-y-px`/`brightness-95`; computed `transform` shows no dip |
| T21 | unsized-icon-svgs-scale-with-button-size | render `size="sm"` `<Button><svg data-testid="icon"/></Button>` (svg has no `size-*` class) | svg renders at 14×14px |
| T22 | unsized-icon-svgs-scale-with-button-size | render `size="xs"` (and separately `size="icon-xs"`) `<Button><svg data-testid="icon"/></Button>` (svg has no `size-*` class) | svg renders at 12×12px |

