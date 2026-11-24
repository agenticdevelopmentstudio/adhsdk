
- **Data collected**: None. Message bodies are parsed only for `id`, `method` and `params.requestId`, and are not stored or logged.
- **Storage**: Owed ids are held in memory until paid or the process ends.
- **Transmission**: Messages travel between the process's standard input and output and the server; nothing else is sent.
- **Retention**: Not applicable: nothing is persisted.

