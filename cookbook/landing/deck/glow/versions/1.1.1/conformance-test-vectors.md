
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| glow-001 | render-as-div | None | Component renders as HTML `<div>` element |
| glow-002 | aria-hidden | None | Rendered element includes `aria-hidden="true"` |
| glow-003 | base-class | None | Rendered element has class 'lp-glow' |
| glow-004 | combine-classnames | `className="custom-glow"` | Rendered element has classes 'lp-glow' and 'custom-glow' |
| glow-005 | combine-classnames | `className=""` | Rendered element has class 'lp-glow' only (empty string filtered) |
| glow-006 | combine-classnames | `className={undefined}` | Rendered element has class 'lp-glow' only (undefined filtered) |
| glow-007 | classname-prop, combine-classnames | No className prop | Rendered element has class 'lp-glow' only |
| glow-008 | combine-classnames | `className="a b"` | Rendered element's class attribute is `lp-glow a b`; class list contains the tokens `lp-glow`, `a`, and `b` |
| glow-009 | combine-classnames | `className="   "` (whitespace only) | Rendered element's class attribute is `lp-glow` followed by the whitespace-only string; the browser's class-attribute tokenizer resolves this to the single class-list token `lp-glow` |

