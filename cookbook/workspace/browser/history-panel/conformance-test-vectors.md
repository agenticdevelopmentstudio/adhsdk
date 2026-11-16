
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| history-panel-001 | empty-filter-lists-recent, change-is-announced | Store holds three visits; model created with an empty filter; reload | The model lists all three, newest first; its observer is notified |
| history-panel-002 | filter-searches-title-and-address | Visits titled "Kitchen" at `https://a.example`, titled "Other" at `https://kit.example`, and titled "Other" at `https://b.example`; set the filter to "kit" | The model lists the first two only, newest first |
| history-panel-003 | filter-is-trimmed | Same store; set the filter to "  kit " | Same visits as filter "kit" |
| history-panel-004 | filter-is-trimmed, empty-filter-lists-recent | Set the filter to "   " | The model lists recent visits, as with an empty filter |
| history-panel-005 | list-is-bounded-by-page-size | Store holds five visits; model created with page size 2 | The model lists the two newest visits only |
| history-panel-006 | latest-filter-wins | Set the filter to "a", then to "ab", without waiting for the first reload | The model ends up listing the visits matching "ab"; the "a" answer never replaces them |
| history-panel-007 | remove-deletes-from-store, change-is-announced | Store holds three visits; remove one by id | The store's count drops by one; the model no longer lists it; the observer is notified |
| history-panel-008 | clear-all-empties-store | Store holds three visits; clear all | The store's count is 0; the model lists nothing |
| history-panel-009 | store-work-off-ui-thread | Reload, remove and clear all from the UI thread | Each store call runs off the UI thread; the visits are published and the observer notified on the UI thread |
| history-panel-010 | panel-filter-drives-model | Panel loaded; type "ki" into the filter field without pressing Return | The field's placeholder is "Filter History"; the model's filter is "ki" |
| history-panel-011 | panel-rows-show-visit | Model lists two visits | The list shows two rows in the model's order, each with title, address and a relative time |
| history-panel-012 | panel-sidebar-list-style | Panel loaded | A search field sits above a source-style list, as in the Settings sidebar |
| history-panel-013 | panel-remove-selected | Select two rows; press the remove button | The model is asked to remove exactly those two visits; the button's tooltip is "Remove Selected Visits" |
| history-panel-014 | panel-clear-confirms | Press Clear History…; confirm | A confirmation is shown first; after confirming, the model clears all; the button's tooltip is "Clear All History" |
| history-panel-015 | panel-clear-confirms | Press Clear History…; cancel | No visit is removed |
| history-panel-016 | panel-opens-visit | Double-click a row; separately, select a row and press Return | Each time the open callback receives that visit's address, once |
| history-panel-017 | panel-every-button-has-tooltip | Panel loaded | Every button in the panel has a non-empty tooltip |
| history-panel-018 | panel-no-inline-help | Empty store; and a filter that matches nothing | The list is empty and no help or empty-state text is shown |
| history-panel-019 | panel-independent-of-host | Create the panel with a model and an open callback, outside any window | It loads and works; it references no window or shelf type |
| history-panel-020 | window-hosts-panel-in-shelf | Show the History window | A shelf with a panel bar holding one "History" button, with the History panel beneath |
| history-panel-021 | window-is-single | Show the History window twice | One window exists with the fixed identifier; its frame and visibility are saved under it and restored on the next launch |
| history-panel-022 | window-opened-from-browser-menu | Key window has no browser pane; choose Browser › Show History | The command is enabled and the History window is shown |
| history-panel-023 | window-opens-visit-in-browser | Open a visit from the window while the frontmost other window has a focused browser pane | The visit opens as a new tab in that pane |
| history-panel-024 | window-opens-visit-in-browser | Open a visit from the window while no browser pane exists | The visit opens in a new browser window |
| history-panel-025 | recording-gated-on-setting | Record history on, pane not private; navigate | One visit is recorded |
| history-panel-026 | recording-gated-on-setting | Record history off, pane not private; navigate | No visit is recorded |
| history-panel-027 | private-browsing-never-records | Record history on, pane in private browsing; navigate | No visit is recorded; the panel lists nothing new |
| history-panel-028 | reloads-on-store-change | List model on a store showing two visits; record a third visit through the store | The model reloads and lists three visits, newest first |
| history-panel-029 | panel-opens-visit | Select rows 0 and 2 of three; press Return | The open callback receives row 0's address, then row 2's |
| history-panel-030 | panel-opens-visit | Rows 0 and 1 selected; double-click row 2 | The open callback receives row 2's address only |

