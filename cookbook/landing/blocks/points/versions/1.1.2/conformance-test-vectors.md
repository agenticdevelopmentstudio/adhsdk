
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| points-001 | list-element, base-class, empty-entries | `{entries: [], ordered: false}` | Renders `<ul class="lp-points"></ul>` |
| points-002 | list-element, ordered-class | `{entries: [], ordered: true}` | Renders `<ol class="lp-points lp-points--ordered"></ol>` |
| points-003 | list-items, content-span | `{entries: [{detail: "Content"}]}` | Renders `<li><span>Content</span></li>` |
| points-004 | term-bold, term-detail-spacing | `{entries: [{term: "Term", detail: "Description"}]}` | Renders `<li><span><b>Term</b> Description</span></li>` |
| points-005 | list-element | `{entries: [{detail: "First"}]}` (`ordered` prop omitted) | Renders `<ul class="lp-points">…` — omitting `ordered` defaults to unordered |
| points-006 | term-bold, term-omission, term-detail-spacing | `{entries: [{term: "A", detail: "First"}, {detail: "Second"}]}` | First item: `<li><span><b>A</b> First</span></li>`. Second item: `<li><span>Second</span></li>` with no `<b>` |
| points-007 | ordered-class | `{entries: [{detail: "First"}, {detail: "Second"}], ordered: true}` | Root element has class `lp-points--ordered` |
| points-008 | ordered-class-exclusion | `{entries: [{detail: "Item"}], ordered: false}` | Root element does not have class `lp-points--ordered` |
| points-009 | term-bold, detail-text | `{entries: [{term: <em>Note</em>, detail: <a href="#more">link</a>}]}` | Renders `<li><span><b><em>Note</em></b> <a href="#more">link</a></span></li>` — ReactNode `term`/`detail` render as-is |

