
- **Data handled**: Transcript text of human prompts and agent replies, plus the project folder name, git branch, session title and terminal program for each row.
- **Storage**: None by the type; the daemon stores the transcript lines the entries are extracted from.
- **Transmission**: The entry crosses XPC and loopback HTTP from daemon to app; the type applies no redaction or encryption.
- **Retention**: Not applicable to the type; retention is the daemon store's concern.

