
- **Missing file**: MUST create it with mode 0600, its directory if needed, and return the new token.
- **Empty or whitespace-only file**: MUST count as no token and be overwritten with a new one.
- **Existing token with odd content**: any non-empty text, trimmed, is returned; a hand-edited short token is accepted.
- **Wider file mode**: MUST be tightened to 0600 on every load; the token is kept.
- **Unwritable location**: a path under a file, or a read-only volume, MUST throw `LoadError.unwritable`; covered by `testTokenLoadFailureIsThrown`.
- **Unreadable existing file**: a file the process cannot read MUST throw `LoadError.unreadable`.
- **Symbolic link, directory or device at the path**: MUST be refused with `LoadError.unreadable`; covered by `testASymlinkAtTheTokenPathIsRefused` for links.
- **Link planted between the check and the write**: the open uses the no-follow flag, so the write is refused and `LoadError.unwritable` is thrown.
- **Secure random failure**: MUST stop the process with a precondition failure; the source does not fall back.
- **Concurrent first load**: see the open question on `concurrent-first-load`.
- **Concurrent load of an existing file**: each caller reads the same content, so each returns the same token; tightening is idempotent.
- **Offline or disconnected state**: not applicable — the component uses only the local file system and the system random generator.
- **Token wiped while the app runs**: a caller that loaded the token once keeps using its copy; the new file is read only on the next `load(from:)`.
- **Non-UTF-8 content in an existing file**: reading as UTF-8 throws and MUST surface as `LoadError.unreadable`; the file is not overwritten.

