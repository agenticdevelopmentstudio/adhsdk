
Constants

- **server-name**: `serverName` MUST be the string `adkitchen`; it is the only key under `mcpServers`.
- **caller-header-name**: `callerHeader` MUST be the string `X-ADHD-Pane`, `HostMCPServer.callerHeader`.

Building the JSON (`json(port:token:callerID:)`)

- **json-shape**: The output MUST be a JSON object with one key, `mcpServers`, whose value is an object with one key, `adkitchen`, whose value is an object with exactly the keys `type`, `url` and `headers`.
- **json-type**: `type` MUST be the string `http`.
- **json-url**: `url` MUST be `http://127.0.0.1:` followed by the decimal port and `/mcp`; the host MUST be the loopback address, never a hostname or a configurable value.
- **json-headers**: `headers` MUST be an object with exactly two keys: `Authorization`, whose value is `Bearer ` followed by the token, and `X-ADHD-Pane`, whose value is the caller id.
- **json-sorted-keys**: Keys MUST be written in sorted order, so equal inputs give byte-identical output.
- **json-unescaped-slashes**: Forward slashes MUST NOT be escaped, so the url reads `http://127.0.0.1:...` rather than with `\/`.
- **json-compact**: The output MUST be compact (no pretty-printing whitespace).
- **json-no-validation**: The function MUST NOT validate the token or the caller id: an empty or unusual string is written as given (JSON-escaped), and any `UInt16` port, 0 included, is written as is.
- **json-cannot-fail**: Serialization MUST be treated as infallible, because every value is a plain string; if it ever fails the function MUST halt (trap) rather than return empty data; the source halts with `preconditionFailure`, and the message text is not part of the contract.
- **json-pure**: The function MUST be pure: no I/O, no clock, no shared state.

Writing the file (`write(port:token:callerID:to:)`)

- **write-parent-directory**: The function MUST create the parent directory of the target, with intermediate directories, with permissions 0700.
- **write-parent-tightened**: The function MUST then set the parent directory's permissions to 0700 even when it already existed with looser permissions.
- **write-temp-sibling**: The data MUST first go to a temporary file in the same directory, named `.<target file name>.<UUID>.tmp`, so the later rename stays on one volume and the name cannot collide.
- **write-temp-mode**: The temporary file MUST be created with `open` using `O_CREAT | O_EXCL | O_WRONLY` and mode 0600, so it is never readable by others at any moment; the data MUST NOT be written before the file has its final restrictive mode.
- **write-open-failure**: If `open` fails, the function MUST throw `CocoaError(.fileWriteNoPermission)`, whatever the cause; the underlying errno is not carried in the error.
- **write-content**: The temporary file MUST hold exactly the bytes from `json` for the same arguments.
- **write-atomic-rename**: After writing and closing the handle, the function MUST `rename` the temporary file over the target, so a concurrent reader sees the old complete file or the new complete file, never a partial one. This makes no promise about crash durability: the source does not `fsync` before the rename, so after a crash or power loss the target may be empty or partly flushed.
- **write-rename-failure**: If `rename` fails, the function MUST throw `CocoaError(.fileWriteUnknown)`, whatever the cause; the underlying errno is not carried in the error.
- **write-cleanup**: If writing, closing or renaming fails, the function MUST remove the temporary file (ignoring any error from the removal) and rethrow the original error.
- **write-overwrite-mode**: When the target already exists with looser permissions (for example 0644), the result MUST be at most mode 0600 and never group- or world-accessible (the `open` mode is masked by the process umask, so a umask of 0277 gives 0400), because the new file replaces the old one rather than being written into it.
- **write-no-residue**: After a successful write the directory MUST hold no leftover temporary file.
- **write-errors-propagate**: Errors from directory creation or from setting permissions MUST propagate to the caller unchanged; the function MUST NOT swallow them.

