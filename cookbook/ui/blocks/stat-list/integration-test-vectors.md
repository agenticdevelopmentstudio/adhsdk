
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-a-dot-per-row, truncate-the-label, right-align-trailing | `<StatListRow tone="error" label="app" labelTitle="app" trailing={<span>1h</span>} />` | a decorative dot, a label that clips with an ellipsis and carries `title="app"`, and "1h" rendered right-aligned and non-shrinking after the label |
| T2 | truncate-the-label, right-align-trailing | a row 375 px wide with a label far longer than the row and `trailing={<span>1h</span>}` | the label clips with an ellipsis while "1h" stays fully visible |
| T3 | right-align-trailing | `StatListRow` with no `trailing` | no trailing slot element rendered |
| T4 | right-align-trailing | `<StatListRow trailing={0} />` | the trailing slot renders (containing `0`) — a falsy-but-non-null value is not treated as absent |
| T5 | honor-row-element | `as="li"` | the row is an `li` |
| T6 | honor-row-element | `StatListRow` with no `as` | the row is a `div` |
| T7 | stack-rows, divide-when-asked, honor-list-element | `<StatList as="ul" divided>` | a `ul` arranged as a single vertical column with row spacing, no list-marker bullets, and a top divider (border + padding) |
| T8 | divide-when-asked | `<StatList>` (no `divided`) | no top divider rendered |
| T9 | honor-list-element | `StatList` with no `as` | the list is a `div` |
| T10 | spread-host-attributes | `<StatList data-testid="list-1">` | the root carries `data-testid="list-1"` |
| T11 | spread-host-attributes | `<StatListRow data-testid="row-1">` | the root carries `data-testid="row-1"` |
| T12 | as-consistency | `<StatListRow as="li" />` rendered outside any `StatList` | still renders as an `li` — the component does not check its parent, so the caller alone keeps the `as="li"`/`as="ul"` pairing valid |
| T13 | right-align-trailing | `<StatListRow trailing={false} />` and `<StatListRow trailing="" />` | each renders the trailing slot wrapper, empty — only `null`/`undefined` omit it |
| T14 | truncate-the-label | `<StatListRow label="app" />` with no `labelTitle` | the label element carries no `title` attribute (none is derived from `label`) |

