
No test beside the source drives this panel; the spacing control's own tests (layout, accessibility and reset) cover the control. These vectors are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| spacing-panel-001 | panel-title, panel-icon | Construct the panel and read its descriptor | Title "Spacing"; icon is the rectangle-split-three-columns symbol with no accessibility description |
| spacing-panel-002 | search-keywords, search-before-open | Read the keywords on a panel whose view has never loaded | Exactly the ten keywords in the stated order |
| spacing-panel-003 | three-groups, one-control-per-group, groups-build-on-load | Load the view | Three groups titled in order, each with one spacing control; none exist before load |
| spacing-panel-004 | frame-bound, content-bound | Change the frame control's top value to 12 and the content control's top value to 6 | The frame top setting reads 12 and the content top setting reads 6; neither changes the other |
| spacing-panel-005 | divider-bound | Change the between-columns value to 8 | The between-columns gutter setting reads 8 |
| spacing-panel-006 | live-apply, no-local-store | With a project window open, change a frame value | The open window re-spaces at once; the panel holds no copy of the value |
| spacing-panel-007 | frame-identifier, divider-identifier, content-identifier | Read the three controls' accessibility identifiers | `settings.spacing.frame`, `settings.spacing.dividers`, `settings.spacing.content` |
| spacing-panel-008 | tab-frame-to-dividers, tab-join-after-build | Read the next key view of the frame control's last number field | It is the divider control's first number field |
| spacing-panel-009 | tab-dividers-to-content, shift-tab-reverse | Read the next key view of the divider control's last field and the previous key view of the content control's first field | Next is the content control's first field; previous is the divider control's last field |
| spacing-panel-010 | tab-ends-unjoined | Read the next key view of the content control's last field | No link is set by the panel |
| spacing-panel-011 | help-topics | Read the help content | Four topics in order with titles Frame Spacing, Pane Divider Spacing, Pane Content Spacing, Everywhere |
| spacing-panel-012 | help-divider-body | Read the Pane Divider Spacing body | It states each number is the whole gap and a gap of zero still drags |
| spacing-panel-013 | no-archive-init | Attempt to construct from an archive | The attempt is rejected with a fatal error |

