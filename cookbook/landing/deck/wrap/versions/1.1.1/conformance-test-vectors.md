
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| wrap-001 | render-children | `<Wrap><span>Hello</span></Wrap>` | Rendered output includes `<span>Hello</span>` |
| wrap-002 | apply-lp-wrap-class | `<Wrap><div></div></Wrap>` | Rendered div has class `lp-wrap` |
| wrap-003 | class-composition | `<Wrap className={undefined}><div></div></Wrap>` | Rendered div has only the `lp-wrap` class, no `undefined` token in the class attribute |
| wrap-004 | class-composition | `<Wrap className=""><div></div></Wrap>` | Rendered div has only the `lp-wrap` class |
| wrap-005 | class-composition | `<Wrap className="custom"><div></div></Wrap>` | Class attribute reads exactly `lp-wrap custom` |
| wrap-006 | constrains-width | `<Wrap><div></div></Wrap>` rendered in a 1200px-wide block with `--lp-measure` unset | Computed width is `min(100% - 2.5rem, 70rem)` — `70rem` (1120px at a 16px root) rather than the full 1200px |
| wrap-007 | centers-horizontally | `<Wrap><div></div></Wrap>` rendered in a block wider than `--lp-measure` | Computed `margin-inline-start` equals computed `margin-inline-end` |

