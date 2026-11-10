
- **Data collected**: None beyond what the caller already holds. The
  container is a generic, caller-typed editor with no field kind specific to
  credentials, tokens, or other sensitive data; every field's sensitivity is
  defined entirely by the caller's `TRecord` type, not by this package.
- **Storage**: None of its own. `draft`/`baseline` live in React state for
  the lifetime of the mounted component and are discarded on unmount;
  nothing is written to `localStorage`, `IndexedDB`, or any other browser
  storage.
- **Transmission**: None of its own. The container performs no network
  I/O — every write goes through the caller-supplied, opaque `onSave`/
  `onRepair` functions.
- **Retention**: None beyond the component's own lifetime; see Storage
  above.

