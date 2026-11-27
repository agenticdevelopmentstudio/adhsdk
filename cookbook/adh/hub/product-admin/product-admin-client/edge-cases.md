
- **Empty and absent ids (MUST)**: the read hooks are disabled for an empty, null or undefined ecosystem id and make no request; a hook given no id still builds a stable query key from an empty string.
- **Missing wire fields (MUST)**: a roster body with no `items` reads as an empty page, a missing `next_cursor` as `null`, and a row's missing `roles` or `sets` as empty lists.
- **Quota above the default (MUST NOT validate)**: the client sends any byte count; the 403 for a value above `DEFAULT_QUOTA_BYTES` is the backend's, and the panes check the ceiling themselves before sending.
- **A pause that fails (MUST)**: a refusal is rethrown unchanged to the caller, and the roster is not invalidated.
- **A manager calling the roster (MUST NOT recover)**: the backend answers a manager 403; the client does not retry or fall back.

