
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
| points-010 | ordered-class-exclusion | `{entries: [{detail: "Item"}]}` (`ordered` omitted) | Root is a `<ul>` and does not have class `lp-points--ordered` |
| points-011 | detail-text, content-span | `{entries: [{detail: ""}]}` | Renders `<li><span></span></li>` |
| points-012 | term-omission, term-bold | `{entries: [{term: null, detail: "D"}, {term: "", detail: "D"}, {term: 0, detail: "D"}]}` | Each item renders a `<b>` followed by a space: `<li><span><b></b> D</span></li>` for `null` and `""`, and `<li><span><b>0</b> D</span></li>` for `0`; only `undefined` omits the `<b>` |
