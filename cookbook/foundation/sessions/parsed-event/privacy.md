This type stores no data of its own beyond its in-memory fields and transmits nothing, but it carries personal data (`accountEmail`, `oauthAccountEmail`, and whatever the hook payload and `context` hold). Storage and retention belong to the spool, the quarantine and the ingest store.

- **no-logging-of-fields**: A port MUST NOT write `accountEmail`, `oauthAccountEmail`, `hookData` or `context` to a log, and MUST NOT include them in a `description` or other default string representation of the value.
