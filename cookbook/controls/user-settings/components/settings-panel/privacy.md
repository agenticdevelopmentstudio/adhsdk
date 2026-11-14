
- **Data collected**: The id of the last selected pane, only when `persistKey` is set.
- **Storage**: Browser local storage under `aws-settings:<persistKey>`; it is not encrypted.
- **Transmission**: None; the value never leaves the browser.
- **Retention**: Until the caller or user clears site storage; the component never deletes it.

