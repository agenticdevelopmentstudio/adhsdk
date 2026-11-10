
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| tree-001 | flatten-parent-child-forest | Flat array of 3 rows: root A, root B, child of A | Output: A (depth 0), A's child (depth 1), B (depth 0). |
| tree-002 | order-by-roots-first, order-siblings-in-input-order | Array: [child of 'missing', root C, root A, child of A] | Output: child-of-missing (depth 0, orphan), C (depth 0), A (depth 0), child-of-A (depth 1). |
| tree-003 | treat-orphans-as-roots | Array: [row X with parentId='ghost-parent' (no row in the array has id='ghost-parent'), root Y with no parent] | X and Y both appear at depth 0; X is not dropped despite its missing parent. Output length is 2. |
| tree-004 | sort-if-provided | Array of 3 root rows and a compare function sorting by a custom field | All roots are sorted per the compare function. |
| tree-005 | handle-cycles | Array: [row A parented to B, row B parented to A, row C with no parent] | A and B are not reached by descent from C; they are surfaced at depth 0 in input order. |
| tree-006 | handle-self-parenting | Array: [row with id='X' and parentId='X', root Y] | Row X is treated as a root at depth 0. |
| tree-007 | surface-every-row-exactly-once | Array with mixed hierarchy and cycles, no `expanded` option, unique ids | Output length equals input length; each row appears once. |
| tree-008 | track-children-availability | Array: [root A with child B, root C with no children] | A has hasChildren=true; C has hasChildren=false; B has hasChildren=false. |
| tree-009 | compute-ancestor-path | Rows: A (root), B (parent A), C (parent B); focusId='C' | `ancestorIds()` returns {'A', 'B'}. |
| tree-010 | halt-ancestor-search-at-cycle | Rows forming cycle A→B→A; focusId='A' | `ancestorIds()` returns exactly {'A', 'B'} — the target id 'A' ends up included because the cycle loops back to it after one full traversal — and terminates rather than looping forever. |
| tree-011 | render-label-span | TreeRowLabel with depth=1, hasChildren=true, label='Item', children=<span>Content</span> | Renders a span with flex layout, padding-inline-start: 1.25em, a button, and the children span. |
| tree-012 | indent-with-ems | TreeRowLabel with depth=2 | Rendered span has style `paddingInlineStart: 2.5em`. |
| tree-013 | render-toggle-button-if-children | TreeRowLabel with hasChildren=true | Button element is present. |
| tree-014 | render-spacer-if-no-children | TreeRowLabel with hasChildren=false | Spacer span is present; button is absent. |
| tree-015 | show-toggle-icon | TreeRowLabel with hasChildren=true | ChevronRight icon (14px) is rendered inside the button. |
| tree-016 | rotate-icon-when-expanded | TreeRowLabel with expanded=true | Icon has `rotate-90` class. |
| tree-017 | call-on-toggle-on-click | TreeRowLabel with mock onToggle callback; click the button | onToggle() is called exactly once. |
| tree-018 | set-aria-label-on-toggle | TreeRowLabel with expanded=false, label='Folder' | Button aria-label is "Expand Folder". |
| tree-019 | set-aria-expanded-on-toggle | TreeRowLabel with expanded=true | Button aria-expanded is "true". |
| tree-020 | provide-title-on-toggle | TreeRowLabel with expanded=false, label='Folder' | Button title attribute is "Expand Folder". |
| tree-021 | accept-custom-classname | TreeRowLabel with className="custom-class" | Rendered span includes "custom-class" in its className. |
| tree-022 | accept-children-prop | TreeRowLabel with children=<strong>Bold text</strong> | Strong element is rendered after the toggle/spacer. |
| tree-023 | omit-collapsed-descendants | Rows: A (root), B (parent A), C (parent B); expanded = {A} | Output: A (depth 0, hasChildren=true), B (depth 1, hasChildren=true). C is withheld — it is reached during the walk but never pushed to the output because B is not in `expanded`. |
| tree-024 | halt-ancestor-search-at-missing-parent | Rows: A (root, no parent), B (parentId='missing', no row has id='missing'); focusId='B' | `ancestorIds()` returns {'missing'} — the missing parent id is itself added to the result before the search halts, since the next lookup finds no matching row. |
| tree-025 | use-flex-layout-in-label | TreeRowLabel with any valid props | The outer `<span>` has computed `display: flex`, `align-items: center`, and a small consistent `gap` between the toggle/spacer and the children content. |
| tree-026 | allow-shrinking-toggle | TreeRowLabel with hasChildren=true | The toggle `<button>` has computed `flex-shrink: 0`. |
| tree-027 | allow-content-truncation | TreeRowLabel with hasChildren=true or false | The outer `<span>` has computed `min-width: 0`, letting it shrink below its content's natural width. |
| tree-028 | flatten-parent-child-forest | `flattenTree([], options)` — empty rows array | Returns `[]`. |
| tree-029 | treat-orphans-as-roots | Single row whose `parentId()` returns `null` | Row is treated as a root at depth 0, the same as a missing or undefined parentId. |

