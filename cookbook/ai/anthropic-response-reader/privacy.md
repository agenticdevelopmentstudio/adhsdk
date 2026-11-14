
- **Data collected**: only the model name, four token counts and the stop reason; the reader does not keep message text, tool input or credentials, and discards every other field it parses.
- **Storage**: in memory only, for the life of the instance; the reader writes nothing.
- **Transmission**: None; the reader makes no network call.
- **Retention**: until the instance is released. A non-streaming reader holds up to 4 MiB of raw response body in memory until `finish`, which can contain the full reply text.

