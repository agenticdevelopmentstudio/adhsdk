
**Decision**: The file is created 0600 at creation, never written then chmod-ed.
**Rationale**: The source comment says the file carries the bearer token, "so it is never readable by others at any moment". Creating with the mode and `O_EXCL` closes the window in which a file with the default umask would be readable.
**Approved**: pending

**Decision**: Write to a sibling temp file and rename over the target.
**Rationale**: The rename is atomic on one volume, so the partner's `claude` never reads a half-written file, and it replaces a pre-existing file of looser mode with a fresh 0600 file.
**Approved**: pending

**Decision**: The parent directory is forced to 0700 on every write.
**Rationale**: A directory created earlier with looser permissions would otherwise expose the file name and allow others to swap files; the tests assert the 0755 to 0700 tightening.
**Approved**: pending

**Decision**: The endpoint address is fixed to `127.0.0.1` over plain `http`.
**Rationale**: The endpoint is the app's own local MCP server, so the token never leaves the machine; fixing the host removes a configuration that could point the token at another machine.
**Approved**: pending

**Decision**: `json` halts with `preconditionFailure` instead of throwing if serialization fails.
**Rationale**: The input is all plain strings, so failure would be a programming error and not a runtime condition worth a throwing signature; the message records the reason.
**Approved**: pending

**Decision**: The type neither issues, rotates nor revokes the token.
**Rationale**: It only records what the caller supplies; token lifetime and revocation are owned by the MCP endpoint that creates the token, which keeps this type a pure file writer.
**Approved**: pending

