
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| overlay-001 | closed-non-interactive | open=false | Header, close button, and body remain present but the root has no `open` class, `pointer-events: none` applies, and clicking the close button does not invoke `onClose` |
| overlay-002 | apply-open-class | open=true | Root div has class `pc-content-overlay open` |
| overlay-003 | omit-open-class | open=false | Root div has class `pc-content-overlay` (no `open` class) |
| overlay-004 | invoke-on-close | open=true; user clicks close button; onClose is a spy function | onClose is called exactly once |
| overlay-005 | render-children | children="<div>test content</div>", open=true | Text "test content" appears in body element |
| overlay-006 | close-label | closeLabel="Custom Label", open=true | Close button displays "Custom Label" |
| overlay-007 | default-close-label | closeLabel is undefined, open=true | Close button displays "← back" |
| overlay-008 | custom-class-name | className="custom-style", open=true | Root div includes class `custom-style` |
| overlay-009 | close-label | closeLabel="", open=true | Close button renders with empty text content; button remains present and clickable |
| overlay-010 | invoke-on-close | open=true; user clicks close button 3 times in rapid succession; onClose is a spy function | onClose is called exactly 3 times, once per click (invocations are not merged or debounced) |
| overlay-011 | render-children | children=null, open=true | Body element renders with no content and no thrown error |

