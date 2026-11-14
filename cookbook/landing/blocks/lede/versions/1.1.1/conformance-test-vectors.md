
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| lede-001 | render-as-paragraph | `<Lede>Text</Lede>` | Element is rendered as `<p>` in the DOM |
| lede-002 | render-children | `<Lede>Hello World</Lede>` | Text content "Hello World" appears in paragraph |
| lede-003 | apply-lede-class | `<Lede>Text</Lede>` | Rendered element includes `lp-lede` class |
| lede-004 | accept-additional-class | `<Lede className="extra">Text</Lede>` | Rendered element includes both `lp-lede` and `extra` classes |
| lede-005 | clean-class-attribute | `<Lede className={undefined}>Text</Lede>` | Rendered element class is `lp-lede` only (undefined filtered out) |
| lede-006 | clean-class-attribute | `<Lede className="">Text</Lede>` | Rendered element class is `lp-lede` only (empty string filtered out) |
| lede-007 | clean-class-attribute | `<Lede className=" ">Text</Lede>` | Rendered element class attribute is `lp-lede  ` (two spaces): a whitespace-only value is truthy, so it is not filtered and leaves a stray blank token |
| lede-008 | constrain-paragraph-measure | `<Lede>Text</Lede>` | Computed style of the rendered `<p>` has `max-width: 72ch` |
| lede-009 | Edge Case: empty children | `<Lede></Lede>` | Component renders `<p className="lp-lede"></p>` with no children guard |

