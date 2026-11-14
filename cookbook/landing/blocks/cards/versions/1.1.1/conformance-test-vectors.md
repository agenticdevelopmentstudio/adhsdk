
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cards-001 | render-as-div | No props | Renders `<div>` element |
| cards-002 | base-class | No props | Element has class `lp-cards` |
| cards-003 | pass-children | `children: <span>Item</span>` | Span element is rendered within container |
| cards-004 | pair-layout | `pair={true}` | Element has classes `lp-cards lp-cards--pair` |
| cards-005 | trio-layout | `trio={true}` | Element has classes `lp-cards lp-cards--trio` |
| cards-006 | reject-conflicting-props | `pair={true} trio={true}` | Throws error: `"Cards: \`pair\` and \`trio\` set the same column track — pass at most one"` |
| cards-007 | classname-prop | `className="custom"` | Element has classes `lp-cards custom` |
| cards-008 | combine-classes | `pair={true} className="custom"` | Element has classes `lp-cards lp-cards--pair custom` in output |
| cards-009 | pass-children | No `children` prop (omitted) | Renders `<div>` with no child nodes |
| cards-010 | pass-children | `children={null}` | Renders `<div>` with no child nodes |
| cards-011 | classname-prop, combine-classes | `className=""` | Element's class attribute is exactly `lp-cards`; no trailing or double space |
| cards-012 | pair-layout | `pair={false}` | Element has class `lp-cards` only; no `lp-cards--pair` class |
| cards-013 | pair-layout | `pair={1}` (truthy, not the literal `true`) | Element has class `lp-cards` only; `lp-cards--pair` is NOT applied |
| cards-014 | trio-layout, classname-prop | `trio={true} className="custom"` | Element has classes `lp-cards lp-cards--trio custom` |

