
Not applicable: harper.js lints entirely client-side (see **use-worker-linter**), so the component makes no third-party calls, sends no document content off the device, and collects or stores no data of its own (the lazy load fetches harper's code chunk, with its inlined WASM, from the host that serves the app); it only holds the `value` source string and reports edits back through `onApply`.

