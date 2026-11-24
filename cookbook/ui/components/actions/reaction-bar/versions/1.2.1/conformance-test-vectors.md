
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | renders-one-chip-per-tally, chip-shows-emoji-and-count, names-the-subject | `reactions=[{👍,2,mine},{🎉,1}]`, `subjectLabel="Ada's comment"` | buttons named `👍 2 on Ada's comment` and `🎉 1 on Ada's comment` |
| T2 | announces-own-reaction | same as T1 | the 👍 chip has `aria-pressed="true"`; the 🎉 chip `"false"` |
| T3 | chip-is-a-toggle | click the 👍 chip (the viewer's own) | `onToggle` called with `"👍"` |
| T4 | stateless-tallies | after T3 without a consumer re-render | the chip still reads `2` and still reads pressed |
| T5 | palette-offers-choices, palette-uses-the-same-toggle | open the palette, pick `DEFAULT_REACTIONS[1]` | `onToggle` called with that emoji; the popover closes |
| T6 | palette-offers-everything | open the palette while 👍 is on the subject | 👍 is still offered in the palette |
| T7 | busy-goes-inert | `busy` | every chip is `disabled`; the same two chips are still present, in order |
| T8 | disabled-hides-the-way-in | `disabled` | the chips render and are disabled; no control named `React to <subject>` exists |
| T9 | renders-one-chip-per-tally | `reactions=[]` | no chip; the palette trigger alone |
| T10 | glyph-is-decorative | inspect a chip's glyph | the emoji `<span>` carries `aria-hidden` |
| T11 | names-the-subject (Playwright) | two bars with different `subjectLabel` | each bar's chips are addressable by name without ambiguity |

