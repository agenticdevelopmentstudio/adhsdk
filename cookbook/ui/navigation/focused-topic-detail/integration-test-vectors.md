
Every vector is derived from the source and covered by `focusedTopicDetail.test.tsx`; the selector and the cards are also covered separately by the `PopupMenu` and `ResourceCard` tests.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| ftd-001 | focused-state-from-known-id, selection-follows-focus | `focusedId` names an item, `activeTopicId="apps"` | the rail selects "apps"; the pane shows the focused header and `children` |
| ftd-002 | unknown-id-falls-back-to-all | `focusedId="gone"`, no such item | the All header and cards show; no `children` rendered |
| ftd-003 | topics-dim-when-unfocused, selector-bar-when-unfocused | `focusedId=null` | every topic is disabled, none is selected, the bar sits on the selector row |
| ftd-004 | focused-header-derived | topic "Applications", item "Temporal", `nameSuffix="Ecosystem"` | header reads "Applications (Temporal Ecosystem)" |
| ftd-005 | focused-header-override | `title="Custom"` plus `nameSuffix` | header reads "Custom" |
| ftd-006 | focused-header-omitted | focused, no `title`, no `nameSuffix` | no header row; `children` render |
| ftd-007 | all-cards | three items, unfocused | three cards; clicking the second calls `onFocus` with its id |
| ftd-008 | all-empty-copy | `items=[]`, unfocused | "Nothing here yet." shows, no grid |
| ftd-009 | focused-pane-remounts | focus changes from item A to item B | `children` unmount and mount again with fresh state |
| ftd-010 | all-choice-clears-focus | choose All in the selector | `onFocus(null)` |
| ftd-011 | popup-new-entry-optional | `onNew` omitted | the selector shows no New entry |

