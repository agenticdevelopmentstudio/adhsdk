
- **Null and empty input, empty panes**: With `panes` of length 0 the component MUST behave as compound mode and render children. With no panes at all the sidebar is empty, no selection is made and the detail area is empty.
- **Null and empty input, empty persist key**: An empty or undefined `persistKey` MUST disable both reading and writing.
- **Null and empty input, absent default**: With no `defaultPaneId` and nothing persisted the initial selection is none and auto-selection MUST choose the first enabled pane.
- **Boundary values, all panes disabled**: The component MUST leave the selection unset and MUST NOT call `onSelect`.
- **Boundary values, single pane**: A single enabled pane MUST be auto-selected and rendered.
- **Boundary values, duplicate ids**: In compound mode a second registration with the same id replaces the first. In data-driven mode the array is used as given, so duplicate ids render duplicate rows with the same React key; the source defines no handling for that.
- **Stale selection, persisted id no longer exists**: A persisted or default id with no matching pane MUST be replaced by the first enabled pane, and the replacement is not written back to storage.
- **Selected pane becomes disabled or removed**: The component MUST auto-select the first enabled pane and call `onSelect`.
- **Controlled selection pointing at a disabled pane in data-driven mode**: The detail area looks the entry up by id without checking `isDisabled`, so the disabled pane's body renders while the auto-selection effect asks the parent to move away; in compound mode the selected disabled Pane also renders its children. A parent that ignores `onSelect` keeps seeing that body.
- **Concurrent access**: Registration and unregistration use functional state updates, so several Panes mounting in the same commit all register. Auto-selection runs in an effect after render, so one extra render can show the stale selection first.
- **Error states, storage unavailable or full**: Storage errors MUST be swallowed silently; selection still works but does not persist, and the user receives no notice.
- **Error states, subcomponent outside the panel**: `Sidebar` and `Pane` MUST throw the Error described in context-required.
- **Controlled parent that never updates**: Clicks still call `onSelect` and write persistence, but the displayed pane does not change.
- **Compound mode without a Sidebar child**: No sidebar is rendered, because compound mode only renders what the caller supplies.
- **Server rendering**: Persistence is skipped when `window` is undefined, so server output uses `defaultPaneId`, and the effect-driven registration means compound-mode sidebars are empty on the first render pass.
- **Offline or disconnected state**: Not applicable: the component performs no network calls and keeps its state in memory and in local storage.

