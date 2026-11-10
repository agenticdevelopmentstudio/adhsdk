
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| help-enabled-001 | renders-children | `<HelpEnabled id="test-id">Help Text</HelpEnabled>` with valid help entry | "Help Text" appears in the document |
| help-enabled-002 | renders-badge, marks-badge-data-slot | `<HelpEnabled id="test-id">Help Text</HelpEnabled>` with valid help entry | Info icon badge is rendered next to the text with `data-slot="help-enabled-badge"` |
| help-enabled-003 | accepts-id-prop | `<HelpEnabled id="unique-id">Text</HelpEnabled>` with a stored entry `{ body: "Stored help" }` for `"unique-id"` | The popover shows "Stored help" — the entry stored for `unique-id` |
| help-enabled-004 | opens-popover-on-trigger | User clicks the trigger element | Popover opens and displays help content |
| help-enabled-005 | shows-popover-content | `<HelpEnabled id="test-id">Text</HelpEnabled>` with valid entry `{ body: "Help", flavor: "info" }` | HelpPopoverContent is rendered inside the Popover with the entry |
| help-enabled-006 | accepts-fallback, wraps-fallback-as-info-entry, suppresses-warning-when-fallback-given | `<HelpEnabled id="no-entry" fallback="Fallback help">Text</HelpEnabled>` with no stored entry | Popover opens with fallback text in an `info` flavor entry; no console warning is emitted |
| help-enabled-007 | accepts-classname | `<HelpEnabled id="test-id" className="custom-class">Text</HelpEnabled>` with valid entry | `custom-class` is applied to the PopoverTrigger root element |
| help-enabled-008 | renders-plain-text-fallback | `<HelpEnabled id="no-entry">Text</HelpEnabled>` with no stored entry and no fallback | Renders as plain text in a span; no popover opens |
| help-enabled-009 | marks-plain-text-variant | `<HelpEnabled id="no-entry">Text</HelpEnabled>` with no stored entry and no fallback | span element has `data-slot="help-enabled-plain"` attribute |
| help-enabled-010 | preserves-layout-on-missing-entry | `<HelpEnabled id="no-entry" className="layout-class">Text</HelpEnabled>` with no entry and no fallback | `layout-class` is preserved on the plain text span |
| help-enabled-011 | warns-on-missing-entry | First render of `<HelpEnabled id="unknown">Text</HelpEnabled>` with no entry and no fallback | Console outputs warning: `[HelpEnabled] no help entry for id "unknown" — rendering plain text` |
| help-enabled-012 | warns-on-missing-entry | Second render of `<HelpEnabled id="unknown">Text</HelpEnabled>` in same session | No additional console warning (warning throttled by id) |
| help-enabled-013 | marks-interactive-variant | `<HelpEnabled id="test-id">Text</HelpEnabled>` with valid entry | PopoverTrigger root has `data-slot="help-enabled"` attribute |
| help-enabled-014 | badge-hidden-by-default | Component renders with valid entry | Badge's computed opacity is 0 |
| help-enabled-015 | shows-badge-on-hover | User hovers over trigger element | Badge's computed opacity transitions to 0.7 |
| help-enabled-016 | shows-badge-on-focus | User tabs to trigger element with keyboard | Badge's computed opacity transitions to 0.7 |
| help-enabled-017 | shows-badge-when-popover-open | Popover is open | Badge's computed opacity is 0.7 |
| help-enabled-018 | marks-badge-aria-hidden | Component renders badge | Info icon has `aria-hidden="true"` |

