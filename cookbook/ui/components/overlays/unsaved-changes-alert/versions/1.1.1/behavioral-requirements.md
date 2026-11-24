
- **show-modal-when-open**: Component MUST display a modal dialog when `open` is `true`, blocking all interaction outside the modal until dismissed.
- **hide-modal-when-closed**: Component MUST NOT display when `open` is `false`.
- **fixed-title**: Component MUST display the title associated with the `title` localization key ("Discard unsaved changes?" in `en`) and MUST NOT accept a `title` prop — the string may vary by locale but is never caller-supplied.
- **fixed-button-labels**: Component MUST display the destructive action using the `confirmLabel` key ("Discard" in `en`) and the cancel action using the `cancelLabel` key ("Stay" in `en`), and MUST NOT accept customizable button-label props — the strings may vary by locale but are never caller-supplied.
- **render-description**: Component MUST render the description text in the modal body, including when `description` is the empty string.
- **default-description**: Component MUST use "Your unsaved changes will be lost." as the description when the `description` prop is `undefined`.
- **custom-description**: Component MUST accept an optional `description` prop to override the default description for surfaces that can name what is at risk.
- **discard-callback**: Component MUST call the `onDiscard` callback when the user confirms the destructive action (clicks or taps "Discard").
- **dismissal-outcomes**: Every dismissal path MUST have a defined outcome: clicking "Stay" invokes `onStay`; clicking the close (✕) button invokes `onStay`; clicking or tapping the backdrop/overlay does nothing (pointer dismissal outside a button is disabled); pressing Escape does nothing (see discard-requires-explicit-action). No path other than clicking "Discard" MUST invoke `onDiscard`.
- **discard-requires-explicit-action**: Component MUST ensure neither pressing Enter nor pressing Escape invokes `onDiscard`; discarding requires an explicit click or tap on "Discard". Initial focus MUST land on "Stay" when the modal opens.
- **controlled-visibility**: Component MUST be fully controlled by the `open` prop; it MUST NOT close itself or otherwise change its own visibility in response to `onDiscard` or `onStay` being invoked — the parent MUST set `open` to `false`.
- **no-persistence**: Component MUST NOT persist data; it returns control to the caller to handle persistence on the editing surface.

