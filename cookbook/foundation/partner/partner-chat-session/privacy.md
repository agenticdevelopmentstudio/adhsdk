
- **Data collected**: The conversation text (owner lines and assistant replies) and tool names, held in memory in the transcript.
- **Storage**: In memory only. The type persists nothing; it returns the assistant replies from `apply` so the caller can persist them, and the caller persists owner lines itself.
- **Transmission**: The type transmits nothing itself; owner text leaves only through the injected send closure.
- **Retention**: Until the instance is released. `close()` does not clear the transcript.

