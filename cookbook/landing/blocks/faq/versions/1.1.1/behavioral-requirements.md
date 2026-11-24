
- **one-details-per-entry**: Each entry in the `entries` array MUST render as its own `<details>` element, in the same order as the array.
- **entries-prop**: Component MUST accept an `entries` prop of type `FaqEntry[]`.
- **question-in-summary**: The `question` field of each FaqEntry MUST render inside a `<summary>` element as the disclosure label.
- **answer-as-content**: The `answer` field of each FaqEntry MUST render as content inside the `<details>` element, outside the `<summary>`.
- **initial-open-state**: Each FaqEntry's `open` field MUST cause the corresponding `<details>` element's `open` attribute to be set to match `open === true` on every render. Because the value is re-applied whenever `entries[i].open` changes, a later render that changes the value overrides whatever the user had toggled in the browser; when `entries[i].open` does not change between renders, the user's own toggle is left alone. See #edge-cases/re-render-with-changed-open.
- **reactnode-content**: Both `question` and `answer` MUST accept any valid React `ReactNode` value, including strings, numbers, components, and fragments.
- **browser-native-toggle**: Users MUST be able to toggle disclosure by clicking the summary, using Enter or Space keys on keyboard focus, or tapping on mobile, with no custom event handlers required — browser-native `<details>` behavior applies.
- **print-preserves-open**: When the page is printed, all expanded entries MUST remain open in the print layout.
- **findable-text**: Question text and the content of any currently open entry MUST be discoverable using the browser's Find feature (Ctrl+F / Cmd+F) without JavaScript interception. Only Chromium-based browsers additionally search inside a *closed* `<details>` element and auto-expand it on a match; other browsers do not search collapsed content, so a closed answer is not guaranteed findable across browsers. See #test-vectors/faq-007.

