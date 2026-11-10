
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| editable-list-001 | render-search | Component rendered with list prop | Search input visible in bar with label "Filter [ariaLabel]" |
| editable-list-002 | update-search | User types "abc" in search input | `list.setSearch("abc")` called; controller (not the component) recomputes `list.rows` from the new term |
| editable-list-003 | render-text-filters | list.textFilters contains one filter with id="status", placeholder="Status" | Text input visible in bar with placeholder "Status" |
| editable-list-004 | update-text-filter-values | User types "active" in text filter input | `list.setTextFilterValue("status", "active")` called |
| editable-list-005 | render-facet-menus | list.facets contains one facet with id="role", label="Role", options ["Admin", "User"] | Dropdown menu visible with label "Role" and options shown on click |
| editable-list-006 | update-facet-selection | User selects "Admin" in role facet | `list.setFacetSelection("role", new Set(["Admin"]))` called |
| editable-list-007 | render-table | list.rows contains 3 rows; list.columns defined | Data table renders with 3 rows |
| editable-list-008 | render-column-headers | Column has header="Name" and value=(row) => row.name | Table header shows "Name"; cells show row.name values |
| editable-list-009 | support-sorting | Column key="name", sortable=true, list.sort=null; user clicks the "Name" header once | `list.setSort({ key: "name", dir: "asc" })` called |
| editable-list-010 | preserve-sort-state | list.sort = { key: "name", direction: "asc" } | Table header shows sort indicator on "Name" column pointing up |
| editable-list-011 | support-column-resizing | columnWidthsKey="users_table"; column key="email" dragged to 220px | Column resizes to (at least) the 48px minimum; `localStorage.setItem("data-table-cols:users_table", JSON.stringify({ email: 220 }))` called — widths are stored as a column-key-to-pixel-integer map under the `data-table-cols:<key>` prefix |
| editable-list-012 | render-selection-checkboxes | selectable=true; list.rows contains 2 rows | Checkbox in header and checkbox in each of 2 rows visible |
| editable-list-013 | update-selection | User checks checkbox on row 1 | `list.setSelectedIds(new Set([row1_id]))` called; row1 highlighted |
| editable-list-014 | show-selection-count | selectable=true; 2 rows selected | Count button shows "2 selected" |
| editable-list-015 | show-hidden-selected-count | selectable=true; 3 rows selected but filter hides 1 | Count button shows "3 selected (1 not shown)" with hidden count in gold |
| editable-list-016 | provide-clear-selection-button | Count button displayed with 2 rows selected; user clicks button | `list.clearSelection()` called; all rows deselected; count button hidden |
| editable-list-017 | render-actions | actions=`<button>Delete</button>` | Delete button visible in bar to right of filters |
| editable-list-018 | support-row-activation | onRowActivate=(id) => {...}; user double-clicks row with id="row123" | `onRowActivate("row123")` called |
| editable-list-019 | render-empty-state | list.rows is empty, no filter applied, emptyLabel="No data" | Table shows "No data" message; bar and filters still visible |
| editable-list-020 | render-filtered-empty-state | list.rows is empty due to filter, emptyFilteredLabel="No matches" | Table shows "No matches" message |
| editable-list-021 | render-loading-state | loading=true | Table shows loading indicator |
| editable-list-022 | handle-error-no-rows | error={new Error("API failed")}, list.allRows=[], loading=false | Entire list replaced with error alert; bar and table not shown |
| editable-list-023 | handle-error-with-rows | error={new Error("Refetch failed")}, list.allRows contains 3 rows | Error alert shown above table; table and all 3 rows still visible |
| editable-list-024 | render-truncation-notice | truncationNotice="Showing 500 of 1000+" | Alert with truncation message shown above table |
| editable-list-025 | render-details-pane | `details={render: (row) => <div>{row.name}</div>}` | Split view rendered with table on top, details pane on bottom |
| editable-list-026 | show-single-row-details | details provided; 1 row selected with data {id: "1", name: "Alice"} | Details pane calls `render({id: "1", name: "Alice"})`; output shown in bottom pane |
| editable-list-027 | show-details-empty-message | details provided with emptyLabel="Select a row"; 0 rows selected | Details pane shows "Select a row" |
| editable-list-028 | show-details-many-message | details provided with manyLabel="Select one"; 2 rows selected | Details pane shows "Select one" |
| editable-list-029 | render-details-header | details provided; 1 row selected; describeRow=(row) => row.name | Details header shows row's name; had describeRow been omitted or returned "", it would show details.label (default "Details") instead |
| editable-list-030 | render-details-actions | `details.actions=(row) => row ? <button>Edit</button> : null`; 1 row selected | Header shows Edit button; passed the selected row object |
| editable-list-031 | render-details-actions | `details.actions=(row) => row ? <button>Edit</button> : null`; 0 or 2+ rows selected | Header actions button not shown; passed null to actions() |
| editable-list-032 | render-footer | footer=`<div>Total: 100</div>` | Footer rendered below table |
| editable-list-033 | render-null-values | Column with value=(row) => row.optional (null value); row rendered | Cell displays em dash (—) in dim color |
| editable-list-034 | preserve-selection-across-filter-changes | 2 rows selected; search filter applied hiding 1 selected row | Selection still includes both row IDs; count shows "2 selected (1 not shown)" |
| editable-list-035 | describe-rows-for-accessibility | describeRow=(row) => row.email; row1 has email="alice@example.com" | Checkbox has aria-label containing "alice@example.com" |
| editable-list-036 | select-all-scope | list.rows contains 2 visible rows (of 3 total; the 3rd is hidden by a filter and already selected); user clicks the header checkbox | `list.setSelectedIds()` called with a set that adds/removes only the 2 visible rows' ids; the hidden, already-selected row's id is left untouched |
| editable-list-037 | grid-role-and-focus | selectable=true; table renders; user Tabs into the grid, then presses ArrowDown | The grid container (not any row) receives DOM focus (`role="grid"`, `tabIndex=0`); `aria-activedescendant` moves to the next row's id; no row carries its own `tabIndex` |
| editable-list-038 | loading-preempts-error-replacement | error={new Error("Failed")}, list.allRows=[], loading=true | List is NOT replaced: bar renders, an error alert renders above the table, and the table shows its loading indicator (not the empty message) |
| editable-list-039 | error-with-rows-suffix | error={new Error("Refetch failed")}, list.allRows contains 2 rows | Error alert text reads "Refetch failed — showing the last rows that loaded." |
| editable-list-040 | default-error-title | error={new Error("x")}, errorTitle omitted, ariaLabel="Users" | Alert title reads "Couldn't load users" (ariaLabel lowercased) |
| editable-list-041 | support-sorting | Column key="name", sortable=true, list.sort={key:"name",dir:"asc"}; user clicks the "Name" header again | `list.setSort({ key: "name", dir: "desc" })` called — the toggle is asc↔desc only; there is no third click that clears the sort |

