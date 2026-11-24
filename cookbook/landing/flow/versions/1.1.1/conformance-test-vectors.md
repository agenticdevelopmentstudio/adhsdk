
| ID | Requirement | Input | Expected |
|-------|------|--------|----------|
| flow-001 | main-root | `<Flow><div>Content</div></Flow>` | The rendered root element's tag name is `MAIN`. |
| flow-002 | programmatic-focus | `<Flow><div>Content</div></Flow>` | The rendered `<main>` element's `tabindex` DOM attribute is `"-1"`; pressing Tab does not move focus onto it, and calling `.focus()` on it directly succeeds. |
| flow-003 | render-children | `<Flow><p>Hello</p></Flow>` | `<p>Hello</p>` appears inside the rendered `<main>` element exactly as passed. |
| flow-004 | default-class | `<Flow><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow"`. |
| flow-005 | custom-class | `<Flow className="custom"><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow custom"`. |
| flow-006 | class-merge | `<Flow className={undefined}><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow"`, with no extra spaces and no literal `undefined`. |
| flow-007 | no-height-or-overflow | Inspect the rendered `<main>` element's inline `style` attribute | The `style` attribute sets no `height`, `max-height`, or `overflow` value (it is empty or absent); computed styles contributed by the `lp-flow` stylesheet are out of scope for this vector. |
| flow-008 | no-scroll-ownership | Render `<Flow>` with content taller than the viewport; scroll with arrow keys or wheel events | `main.scrollTop` stays `0` throughout while `document.scrollingElement.scrollTop` changes, showing the document — not Flow — owns the scroll position. |
| flow-009 | class-merge | `<Flow className=""><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow"`, not `"lp-flow "`. |
| flow-010 | custom-class | `<Flow className="foo bar"><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow foo bar"`. |
| flow-011 | single-main-landmark | Render two `<Flow>` instances in the same document | `document.querySelectorAll('main').length` is `2`, which the requirement forbids; a conforming page keeps this count at `1`. |

