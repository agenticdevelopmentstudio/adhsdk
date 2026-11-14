
| ID | Requirements | Input | Expected |
|----|----|----|----|
| dismissible-hint-001 | accept-id-prop, render-children | `<DismissibleHint id="test-hint">Example hint text</DismissibleHint>` | Container with `role="note"` renders; text "Example hint text" is visible |
| dismissible-hint-002 | render-close-button, label-close-button, render-close-glyph | Render with close button visible | Button with `aria-label="Dismiss"` and text content "×" is present |
| dismissible-hint-003 | persist-dismissal-state | Click close button; inspect localStorage | Entry `{{app_prefix}}-hint-dismissed:test-hint=1` exists in localStorage |
| dismissible-hint-004 | load-dismissal-state-on-mount | localStorage already contains `{{app_prefix}}-hint-dismissed:test-hint=1`; mount component | Component renders as null; nothing displayed |
| dismissible-hint-005 | not-render-when-dismissed | Click close button; inspect the DOM immediately, in the same session, without remounting | Container is removed from the DOM immediately after the click |
| dismissible-hint-006 | accept-classname-prop | `<DismissibleHint id="test" className="custom-class">text</DismissibleHint>` | Container has class list containing both `{{app_prefix}}-hint` and `custom-class` |
| dismissible-hint-007 | handle-missing-localstorage | localStorage.getItem raises exception during read | Component treats hint as not dismissed; renders normally |
| dismissible-hint-008 | handle-missing-localstorage | localStorage.setItem raises exception on close button click | Component's in-memory state updates (local state shows as dismissed) but localStorage write silently fails |
| dismissible-hint-009 | apply-note-role | Render component | Container div has `role="note"` |
| dismissible-hint-010 | render-close-button, label-close-button | Tab to close button (keyboard focus); press Enter or Space | Hint dismisses, same as a pointer click — the native `<button>` element responds to Enter/Space activation |

