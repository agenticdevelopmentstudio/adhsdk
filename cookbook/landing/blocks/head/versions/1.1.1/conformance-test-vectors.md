
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| head-001 | render-container | No props | `<div class="lp-head"></div>` rendered |
| head-002 | conditional-eyebrow, preserve-order | `eyebrow="Section"` | `<div class="lp-head"><span class="lp-eyebrow">Section</span></div>` |
| head-003 | conditional-title, preserve-order | `title="Heading"` | `<div class="lp-head"><h2>Heading</h2></div>` |
| head-004 | render-children, preserve-order | `children={<p>Content</p>}` | `<div class="lp-head"><p>Content</p></div>` |
| head-005 | conditional-eyebrow, conditional-title, render-children, preserve-order | `eyebrow="Nav"`, `title="Title"`, `children={<p>Body</p>}` | `<div class="lp-head"><span class="lp-eyebrow">Nav</span><h2>Title</h2><p>Body</p></div>` |
| head-006 | conditional-eyebrow | `eyebrow={null}` | `<div class="lp-head"><span class="lp-eyebrow"></span></div>` — the `!== undefined` check passes, so the span renders, but `null` produces no child text |
| head-007 | conditional-title | `title=""` | `<div class="lp-head"><h2></h2></div>` — the check passes on the empty string, producing an empty heading |
| head-008 | render-children | `children={0}` | `<div class="lp-head">0</div>` — `0` is a valid `ReactNode` and renders as text |

