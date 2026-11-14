
**Decision**: The file is created with mode 0600 in the `open(2)` call itself, with `fchmod` as a second step.
**Rationale**: The source comment says this leaves no window in which the file is wider than 0600. The `fchmod` result is not checked. A umask can only narrow the open mode, so the call matters only when the file already existed, and the tightening step has already run in that case.
**Approved**: pending

**Decision**: A symbolic link, directory or device at the token path is refused, and the write uses `O_NOFOLLOW`.
**Rationale**: The source comment says that following a link would read the token from, or write it to, wherever the link points; `O_NOFOLLOW` covers a link planted after the check in `load(from:)`.
**Approved**: pending

**Decision**: An existing file wider than 0600 is tightened instead of refused, and its token is kept.
**Rationale**: A token written by an earlier version or by hand keeps working; `testLoadTightensAWiderExistingFileAndKeepsItsToken` asserts it. The directory's mode is left alone because it may be shared.
**Approved**: pending

**Decision**: An empty or whitespace-only file counts as no token and is regenerated.
**Rationale**: The source returns a token only when the trimmed content is non-empty, so an empty bearer token is never handed out; the source does not say what leaves an empty file behind.
**Approved**: pending

**Decision**: Existing token text is trimmed but not checked against the 64-hex format.
**Rationale**: The source returns any non-empty content; the test keeps `keepme`. A hand-chosen secret keeps working, at the cost that the strength of an existing token is the file owner's responsibility.
**Approved**: pending

**Decision**: A failure of the secure random generator stops the process.
**Rationale**: The source uses a `precondition`; returning a weaker or empty token would silently weaken the only credential protecting the local endpoint.
**Approved**: pending

**Decision**: The token is stored as plain text in a file, not in the Keychain, with no expiry and no rotation.
**Rationale**: The source comment names the token as shared with processes the app hands the MCP URL to, which read the same file. Rotation is by deleting the file. The source gives no reason for omitting expiry, so this is recorded as the actual behaviour.
**Approved**: pending

