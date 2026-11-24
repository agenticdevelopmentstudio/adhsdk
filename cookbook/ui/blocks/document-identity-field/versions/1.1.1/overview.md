
A compound field that captures the two values that identify a document: its human-readable title and its URL-safe slug. The slug initially tracks title edits through a user-supplied slugify function; once the user manually edits the slug, it decouples and stays as edited. An optional availability checker reports whether the current slug is free, in progress, or taken.

