
| ID | Requirement | Input | Expected |
|-------|------|--------|----------|
| flow-001 | main-root | `<Flow><div>Content</div></Flow>` | The rendered root element's tag name is `MAIN`. |
| flow-002 | programmatic-focus | `<Flow><div>Content</div></Flow>` | The rendered `<main>` element's `tabindex` DOM attribute is `"-1"`; calling `.focus()` on it directly succeeds. For the Tab check, render `<button id="before"></button><Flow><div>Content</div></Flow><button id="after"></button>` in a real browser (Playwright), focus `#before`, press Tab once: focus lands on `#after`, never on `<main>`. |
| flow-003 | render-children | `<Flow><p>Hello</p></Flow>` | `<p>Hello</p>` appears inside the rendered `<main>` element exactly as passed. |
| flow-004 | default-class | `<Flow><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow"`. |
| flow-005 | custom-class | `<Flow className="custom"><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow custom"`. |
| flow-006 | class-merge | `<Flow className={undefined}><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow"`, with no extra spaces and no literal `undefined`. |
| flow-007 | no-height-or-overflow | Inspect the rendered `<main>` element's inline `style` attribute | The `style` attribute sets no `height`, `max-height`, or `overflow` value (it is empty or absent); computed styles contributed by the `lp-flow` stylesheet are out of scope for this vector. |
| flow-008 | no-scroll-ownership | Run in Playwright at a real viewport (jsdom has no layout and cannot scroll): render `<Flow>` holding a `<div style="height: 3000px">` in a 800x600 viewport, click the page body, then press `PageDown` and also dispatch a mouse wheel of 400px | `main.scrollTop` stays `0` throughout while `document.scrollingElement.scrollTop` changes, showing the document — not Flow — owns the scroll position. |
| flow-009 | class-merge | `<Flow className=""><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow"`, not `"lp-flow "`. |
| flow-010 | custom-class | `<Flow className="foo bar"><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow foo bar"`. |
| flow-011 | single-main-landmark | Render one `<Flow><div>Content</div></Flow>` as the only Flow in the document | `document.querySelectorAll('main').length` is `1`: a single Flow contributes exactly one `<main>` landmark. A host that renders two Flows breaks the usage constraint; Flow cannot detect that. |
| flow-012 | class-merge | `<Flow className="  "><div>Content</div></Flow>` | The rendered `<main>` element's `class` DOM attribute is `"lp-flow   "` (not trimmed), and its `classList` is `["lp-flow"]`. |

