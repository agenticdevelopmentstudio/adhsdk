
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| label-001 | renders-label-element | Render with no props | HTML `label` element in DOM |
| label-002 | forwards-label-props | Pass `htmlFor="input-id"` and `id="label-1"` | Label renders with matching `htmlFor` and `id` attributes |
| label-003 | default-typography | Render with default props | Computed `font-weight: 500`, small-size `font-size`, `line-height: 1`, and `user-select: none` |
| label-004 | merges-classname | Pass `className="custom-class"` | Rendered element has both default classes and `custom-class` |
| label-005 | peer-disabled-style | Render label as a sibling immediately after a peer input; input becomes disabled | Label's computed `opacity` becomes `0.5` and `cursor` becomes `not-allowed` |
| label-006 | peer-disabled-style | Render label as a sibling immediately after a peer input; input is not disabled | Label's computed `opacity` remains `1` and `cursor` remains the default |
| label-007 | focuses-associated-control | Click the label's text when `htmlFor` references an `<input type="checkbox">`'s `id` | The checkbox receives focus and its checked state toggles |

