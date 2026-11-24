
- **Null and empty input**: an empty override value is treated as unset (MUST). An empty directory string is not checked by the source; a relative or empty path resolves against the process working directory through the file URL initializer, and the source defines nothing further. An empty envelope encodes to the two-character object and is written like any other.
- **Boundary values**: a configuration name with no ASCII letters or digits yields a variable made only of underscores plus the suffix (MUST, per `variable-name`). Names are upper-cased before filtering, so a lowercase ASCII letter keeps its letter.
- **Tilde forms**: `expandingTildeInPath` handles a leading `~` and a leading `~user`; a `~` anywhere else is literal (MUST, per `tilde-expansion`).
- **Concurrent access**: concurrent writers into one directory (many hook processes at once) cannot collide on a name except by a repeated millisecond and a repeated 32-bit random suffix; if they did, the second move would throw and leave its `.tmp` file (MUST, per `no-overwrite`). No lock is taken.
- **Error states**: a directory that cannot be created, a full disk, a permission failure or a failed move surface as thrown errors, never as return values (`errors-thrown`). The caller `HookCaptureCommand` swallows them; the status-line feed also swallows them with `try?`.
- **Leftover temporary files**: a crash or a move failure between the write and the rename leaves a `.tmp` file that nothing in this component removes or reports; scanners that filter on the `.json` extension ignore it (see `temp-left-on-move-failure`).
- **Unrepresentable envelope**: see the open question on `envelope-serializable`.
- **Offline or disconnected state**: not applicable — the component only touches the local file system and never uses the network; its purpose is to work when no daemon is reachable.
- **File permissions**: the directory and file are created with the file system's default permissions; the source sets no mode.

