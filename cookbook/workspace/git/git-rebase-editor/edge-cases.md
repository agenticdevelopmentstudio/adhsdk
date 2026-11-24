
- **Null / empty input**: an empty plan shows no rows and Start disabled (`validationError` reports it); the window never builds one, since the plan verb refuses an empty range.
- **Boundary values**: one entry can only be picked, reworded, edited or dropped usefully; a lone squash or fixup disables Start.
- **A reword switched away and back**: the message typed is kept on the entry, since only the action changed.
- **Field still being edited at Start**: every keystroke has already reached `plan`, so ending editing adds nothing and loses nothing.
- **A drag from elsewhere**: refused; only the table's own rows move.
- **Concurrent access**: UI thread only.
