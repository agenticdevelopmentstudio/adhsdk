
- **Target exists, looser mode**: Replaced by a 0600 file through rename (MUST; see write-overwrite-mode).
- **Parent exists, looser mode**: Tightened to 0700 (MUST; see write-parent-tightened). This changes the mode of a directory the caller may have created for other uses, so the caller MUST pass a target that lives in a directory dedicated to the partner.
- **Failure between temp creation and rename**: The temp file is removed; the target is untouched (MUST).
- **Failure of the cleanup itself**: Ignored; the original error is thrown (MUST).
- **Process killed between temp creation and rename**: A hidden `.tmp` file holding the token, mode 0600, can remain in the directory. The source has no sweep for it; the 0700 parent and the 0600 mode keep it private to the owner.
- **Empty or odd token or caller id**: Written as given, JSON-escaped (MUST; see json-no-validation); rejecting them is the caller's job.
- **Concurrent writers to one target**: Each uses its own unique temp name and renames atomically, so the target always holds one complete writer's output; which writer wins is not defined.
- **Token or port changes between starts**: The file is rewritten on each partner start by the controller, so a stale file is replaced rather than edited.
- **Network, timeouts, offline**: Not applicable — the type opens no connection; it only writes the address and credentials of a local endpoint.
- **Symbolic link at the target**: `rename` replaces the link itself, not its destination; the source does not follow or check links.

