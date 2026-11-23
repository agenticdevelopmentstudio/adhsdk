
- **Switch off (MUST)**: the grants read is 404 while the backend's `consented_access` switch is off; the client rethrows and `isSupportOff` lets a caller hide its surface.
- **A lapsed request (MUST)**: a request undecided for seven days is read as `ended` by `grantState`, whatever the backend has recorded yet.
- **Empty and absent ids (MUST)**: the read hooks are disabled and make no request.
- **A write that fails (MUST)**: a refusal is rethrown unchanged; nothing is invalidated.
- **A refused table (MUST)**: a 404 from the viewer path reaches the caller as the transport's error; the client does not fall back to another route.

