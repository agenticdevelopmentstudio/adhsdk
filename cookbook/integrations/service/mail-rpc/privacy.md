
- **Data collected**: None by this file. The records carry the mail the service already holds: addresses (`from`, `to`, `cc`, `account`), subjects, snippets, bodies and label names.
- **Storage**: None. `MailClient` keeps nothing; it holds only the transport.
- **Transmission**: Requests and replies leave the process over whatever transport is injected; this file adds no encryption or authentication. The full OAuth client secret is sent once, inside `importOAuthClient`, and never comes back; replies carry at most the last 5 characters.
- **Retention**: None in this file.

