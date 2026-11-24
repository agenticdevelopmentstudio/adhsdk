
Derived from `SectionTopicsPanelTests` beside the source. Panels in the
vectors are plain settings panels titled as shown. Vectors 005 to 011 have no
test beside the source and are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| section-topics-001 | list-needs-two, single-panel-fills (onePanelHidesList) | Section "Web Browser"; `setSectionPanels` with one panel; load the view | `showsSidebar` is false and the first split item is collapsed |
| section-topics-002 | list-needs-two, rows-keep-order, contained-panels (twoPanelsShowList) | Section "AI"; two panels "Providers" and "Summaries"; load the view | `showsSidebar` is true, the first split item is not collapsed, `containedPanels` titles are Providers then Summaries |
| section-topics-003 | list-hides-again (twoPanelsShowList) | After 002, `setSectionPanels` with only the first panel | `showsSidebar` is false and the first split item is collapsed |
| section-topics-004 | selection-survives, select-contained, selected-contained (selectionSurvivesAddition) | Section "File Browser" with Editor and Excluded; load; select Excluded; call again with Editor, Excluded and File Types | `selectedContainedPanel` is still the Excluded panel (same object) |
| section-topics-005 | late-panel-selects-first | View loaded, no selection; `setSectionPanels` with two panels | `selectedContainedPanel` is the first panel |
| section-topics-006 | no-select-before-load | View not loaded; `setSectionPanels` with two panels | The call selects nothing itself; `selectedContainedPanel` is none until the view appears |
| section-topics-007 | empty-section | View loaded; `setSectionPanels` with an empty list | `showsSidebar` is false and `selectedContainedPanel` is none |
| section-topics-008 | select-contained | `selectContainedPanel` with a panel that is not in the section | The selection does not change |
| section-topics-009 | titled-for-section, icon-from-initializer | Initialize with section "AI" and a nil icon | The descriptor title is "AI" and the descriptor icon is none |
| section-topics-010 | no-sidebar-title, no-section-titles, list-hidden-before-panels | A new panel before any `setSectionPanels` call | Its sidebar title is none, the list shows no section titles, and `showsSidebar` is false |
| section-topics-011 | container-seen-through | A section hosted in a settings window with two panels; search for a term in the second panel before the section's view has loaded | The search harvests the second panel's title, section, keywords and help terms; its on-screen labels are added only if that panel's own view has loaded |

