
Not applicable: the module stores nothing and handles no token or credential itself. Request bodies pass through `JSON.stringify` and the request layer, which attaches the bearer token. Token storage and transmission are the auth client's concern.

