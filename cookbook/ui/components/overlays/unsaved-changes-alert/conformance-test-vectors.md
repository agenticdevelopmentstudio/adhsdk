
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| unsaved-001 | show-modal-when-open | `open={true}` | Modal dialog is visible; overlay blocks interaction outside the modal |
| unsaved-002 | hide-modal-when-closed | `open={false}` | Modal dialog is not rendered or is hidden |
| unsaved-003 | fixed-title | Any props | Modal title displays "Discard unsaved changes?" |
| unsaved-004 | fixed-button-labels | Any props | Destructive button is labeled "Discard"; cancel button is labeled "Stay" |
| unsaved-005 | render-description | `description="Staged users will not be saved."` | Description text "Staged users will not be saved." appears in modal body |
| unsaved-006 | default-description | No `description` prop (`undefined`) | Description text "Your unsaved changes will be lost." appears in modal body |
| unsaved-007 | custom-description | `description="Composed invitation cannot be sent."` | Description is overridden with "Composed invitation cannot be sent." |
| unsaved-008 | discard-callback, controlled-visibility | User clicks "Discard" button | `onDiscard` callback is invoked once; modal remains open until the parent sets `open` to `false` |
| unsaved-009 | dismissal-outcomes | User clicks "Stay" button | `onStay` callback is invoked once |
| unsaved-010 | dismissal-outcomes, discard-requires-explicit-action | User presses Escape key while modal is open | Nothing happens; Escape does not dismiss the modal, invoke `onDiscard`, or invoke `onStay` |
| unsaved-011 | discard-requires-explicit-action | User presses Enter key while modal is open | Nothing happens; Enter does not invoke `onDiscard` |
| unsaved-012 | no-persistence | Either callback invoked | No network request or persistence operation occurs; caller retains responsibility for persistence |
| unsaved-013 | dismissal-outcomes | User clicks the close (✕) button | `onStay` callback is invoked once; the modal does not close itself |
| unsaved-014 | dismissal-outcomes | User clicks or taps the backdrop/overlay outside the modal | Nothing happens; neither `onDiscard` nor `onStay` is invoked, and the modal remains open |
| unsaved-015 | discard-requires-explicit-action | Modal is closed (`open={false}`) and immediately reopened (`open={true}`) | Initial focus lands on the "Stay" button |
| unsaved-016 | render-description | `description=""` | Modal still renders an empty description region; the default description text is NOT shown |
| unsaved-017 | controlled-visibility | Parent sets `open` to `false` while the modal is displayed | Modal closes; neither `onDiscard` nor `onStay` is invoked as a result of that transition |
| unsaved-018 | render-description | `description` exceeds the modal's content width | Text wraps within the modal body without breaking layout; no horizontal overflow |
| unsaved-019 | controlled-visibility | `onDiscard`/`onStay` omitted at a call site (TypeScript) | Compilation fails; the props are required, not optional, and the component defines no runtime fallback for their absence |

