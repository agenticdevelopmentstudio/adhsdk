
SearchDialogConnected holds no state of its own — it defines no `useState`. The query text, result list, and selected index live in the `SearchState` returned by `useSearchState`; whether the dialog is open is owned by the caller via the forwarded `open` prop.

