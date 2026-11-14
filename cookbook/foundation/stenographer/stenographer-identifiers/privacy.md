
- **Data handled**: Names and paths only. The keychain service names say where credentials live, but the types store or read no credential.
- **Storage**: None, apart from the closure the caller passes to `writeSupportFile`, which decides what is written.
- **Transmission**: None; the base URLs are loopback strings.
- **Retention**: Not applicable: no data is kept.

