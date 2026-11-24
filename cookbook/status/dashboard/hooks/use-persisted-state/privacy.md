
- **Data collected**: the values callers choose to persist; the dashboard's callers store reader preferences only (a boolean flag, a time-span key, a list of selected source names).
- **Storage**: browser local storage under the caller's key, as JSON text, unencrypted and readable by any script on the same origin.
- **Transmission**: none; the data never leaves the browser through this module.
- **Retention**: until the browser's storage is cleared or the same key is overwritten; the module never deletes or expires an entry.

