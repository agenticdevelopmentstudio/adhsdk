
- **Data collected**: None collected or retained. The component prints mail data the client returns (sender and recipient addresses, subjects, label names, bodies and snippets) and account email addresses to the supplied `stdout`.
- **Storage**: None; nothing is written to disk and no state is kept between calls.
- **Transmission**: The component sends nothing itself. Account names, label names, ids, search queries and date bounds go to the injected `MailClient`, which owns transport to the mail service. Message content goes only to `stdout` as the host wires it.
- **Retention**: Not applicable; the component retains nothing. Whatever the host does with the output is outside this code.

