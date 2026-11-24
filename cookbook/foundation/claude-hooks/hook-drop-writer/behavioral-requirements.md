
### Override variable

- **variable-name**: `dropDirectoryVariable` MUST return the configuration's `name` upper-cased, with every Unicode scalar that is not an ASCII letter or digit replaced by one `_`, followed by `_DROP_DIR`.
- **variable-per-configuration**: Two configurations with different names MUST yield different variables, so one daemon's override is never read by another.
- **variable-empty-name**: An empty `name` currently yields `_DROP_DIR` because the source adds no validation of the name; a port MAY reject an empty name instead.

### Directory choice

- **override-wins**: `dropDirectory` MUST return the value of the configuration's override variable from the supplied environment when that variable is present and not the empty string.
- **empty-override-ignored**: `dropDirectory` MUST return `configuration.dropDirectory` when the override variable is absent or is the empty string.
- **other-variable-ignored**: `dropDirectory` MUST NOT read the override variable of any other configuration.
- **tilde-preserved**: `dropDirectory` MUST return its result without expanding a leading `~`; expansion is the job of `writeDropFile`.
- **environment-default**: The `environment` parameter of `dropDirectory` MUST default to the current process environment.
- **production-no-override**: Production hooks SHOULD NOT set the override variable; it exists so tests can route output to a temporary directory without rewiring installed hooks.

### Writing

- **tilde-expansion**: `writeDropFile` MUST expand a leading `~` in the directory to the user's home directory before use.
- **directory-created**: `writeDropFile` MUST create the directory, with any missing intermediate directories, before writing, and MUST NOT fail when it already exists.
- **json-encoding**: `writeDropFile` MUST encode the envelope as a single JSON object with default options as a single compact line; key order is unspecified.
- **file-name**: The final file name MUST be the current Unix time in milliseconds (base 10, no padding or sign), a hyphen, eight lowercase hexadecimal characters taken from a fresh random UUID, and the extension `.json`, so it matches `^\d+-[0-9a-f]{8}\.json$`.
- **unique-names**: Two calls MUST produce different names even within the same millisecond, because of the random suffix.
- **atomic-publish**: `writeDropFile` MUST write the encoded bytes to a file named like the final one with `.tmp` appended, and MUST then move that file to the final name, so that no file with the `.json` extension is ever partially written.
- **errors-thrown**: `writeDropFile` MUST throw, and not return a status, when the directory cannot be created, the encoder reports a Swift error for the envelope, the temporary file cannot be written, or the move fails; the caller decides whether to ignore the error.
- **no-overwrite**: The move to the final name MUST fail rather than replace an existing file of that name.
- **temp-left-on-move-failure**: When the move fails, the `.tmp` file is currently left in place because the source does not remove it; a port MAY remove it on a best-effort basis.
- **envelope-serializable**: NEEDS REVIEW: Not implemented in source. `writeDropFile` never checks that the envelope is valid JSON before encoding, and the encoder reports an unrepresentable value by raising an Objective-C exception that a Swift error handler cannot catch, so the declared `throws` contract does not cover it; a test passing a `Date` or a NaN value would show whether the process aborts.

### Concurrency

- **stateless**: The type MUST hold no shared mutable state; concurrent callers in one or many processes coordinate only through the file system and the unique names.

