
The stack-frontier helper that `useSelectedTopicLabel` calls has tests beside it (`stack-frontier.test.ts`); vectors 12 to 14 derive from its `deepestSelectedLevel` assertions. `detailTitle.test.tsx` exercises the module through a real `HierarchicalTopicDetail` and `HierarchicalMenuDetail`; vectors 7, 8, 10, 11, 15 and 16 cite its assertions, and the rest derive from the source's documented behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| detail-title-001 | register-appends, last-registered-wins, published-flag | Host with no ids; register "a", then "b" | `published` is true and the active id is "b" |
| detail-title-002 | last-registered-wins | Ids "a" and "b" registered; unregister "b" | Active id is "a" |
| detail-title-003 | register-idempotent | Ids ["a"]; register "a" again | Ids remain ["a"]; no state change |
| detail-title-004 | unregister-idempotent, published-flag | No ids; unregister "x" | Ids remain empty; `published` is false; active id is undefined |
| detail-title-005 | suppress-withdraws-titles | A pane with a title below `DetailTitleSuppressed when={true}` | The pane's id is unregistered and `published` is false |
| detail-title-006 | suppress-restores-titles, suppress-never-remounts | Same pane; `when` goes true then false | The pane registers again and its children are the same mounted instances |
| detail-title-007 | strip-titled-rule, strip-heading-role (test: detailTitle "falls back to the stack's detailTitle prop when no pane claims the slot" and "is the pane's level-2 heading") | Nothing published; `fallback="Profile"` | `titled` is true; the cell has `role="heading"` and `aria-level="2"` and shows "Profile" |
| detail-title-008 | strip-no-empty-heading, strip-optout (test: detailTitle "honours a host's detailTitle={null} as an opt-out") | Nothing published; `fallback=null` | `titled` is false; the cell has no role and no aria-level |
| detail-title-009 | strip-published-wins, strip-fallback-when-unpublished | A pane publishes "Milestones"; `fallback="Profile"` | The slot holds "Milestones"; the fallback text is not drawn |
| detail-title-010 | pane-hoisted-rule, pane-inline-when-not-hoisted (test: detailTitle "keeps the title inline with no stack around it") | A pane with title "A" outside any stack (no registrar) | `hoisted` is false and `portal` is null; the pane draws "A" inline |
| detail-title-011 | pane-hoisted-rule, pane-portal-when-hoisted (test: detailTitle "gives the strip to the LAST registrant") | Panes "A" then "B" both titled in one stack | "B" has `hoisted` true and a portal into the slot; "A" has `hoisted` false and draws inline |
| detail-title-012 | selected-label-none (test: stack-frontier "is -1 for an empty stack") | `levels=[]` | `useSelectedTopicLabel` returns undefined |
| detail-title-013 | selected-label-none (test: stack-frontier "is -1 when the hole is the very first level") | `levels=[{selectedId:null,...},{selectedId:"b",...}]` | Returns undefined; the selection under the hole is unreachable |
| detail-title-014 | selected-label-live (test: stack-frontier "is the level above the first unselected one") | Levels selected "a", "b", then null; level 1 items include `{id:"b",label:"Beta"}` | Returns "Beta" |
| detail-title-015 | selected-label-held (test: detailTitle "keeps naming the open row after a filter drops it") | Selected "n1" with label "Note"; the level's items then drop "n1" | Returns "Note", not the id |
| detail-title-016 | selected-label-id-fallback (test: detailTitle "falls back to the selected id") | Selected "n1" never present in items (a deep link before its list loads) | Returns "n1" |
| detail-title-017 | selected-label-keyed-on-depth | "x" held at depth 0 as "One"; selection becomes "x" at depth 1, absent from items | Returns "x", not "One" |
| detail-title-018 | pane-has-title | Title `false`, `null` and `undefined` in turn | Each yields no registration and `hoisted` false |
| detail-title-019 | pane-registration-not-keyed-on-title | A titled pane re-renders with a new title node each render | `register` is not called again after the first registration |
| detail-title-020 | pane-server-inline | Server render of a titled pane inside a stack | HTML contains the inline title; `portal` is null |

