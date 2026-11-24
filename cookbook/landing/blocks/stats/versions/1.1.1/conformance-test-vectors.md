
| ID | Requirements | Input | Expected |
|-------|----------------------------------------|-------------------|-------------|
| stats-001 | render-entries, wrap-each-entry | `entries: [{term: "10", detail: "Users"}]` | Component renders one entry as a `div` child of the `dl` |
| stats-002 | render-entries | `entries: [{...}, {...}, {...}]` (3 items) | Component renders three entry wrapper divs |
| stats-003 | render-term-and-detail | `entries: [{term: "42", detail: "Days"}]` | Rendered as `<dt>42</dt><dd>Days</dd>` within the entry div |
| stats-004 | preserve-node-content | `entries: [{term: <strong>99</strong>, detail: "Active"}]` | Strong element is preserved and rendered within the `dt` |
| stats-005 | preserve-node-content | `entries: [{term: "10", detail: <em>Total Users</em>}]` | Em element is preserved and rendered within the `dd` |
| stats-006 | use-semantic-markup | Any valid entries array | Top-level element is `dl` with class `lp-stats` |
| stats-007 | maintain-order | `entries: [{term: "A", detail: "First"}, {term: "B", detail: "Second"}]` | First entry renders before second entry in DOM order |
| stats-008 | render-entries | `entries: []` | Component renders an empty `dl` with class `lp-stats` and no child `div`s |
| stats-009 | preserve-node-content | `entries: [{term: null, detail: "Users"}]` | Component renders an empty `dt` within the entry `div`; `dd` renders normally |

