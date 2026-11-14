
**Decision**: One dispatcher owns the slot and each tool owns one file beside it.
**Rationale**: The slot holds a single command; per-tool files let a failing tool drop out of the line instead of blanking it and let no tool refuse or wrap another's command.
**Approved**: pending

**Decision**: The installed dispatcher is replaced only by a strictly higher version, and an unversioned copy counts as none.
**Rationale**: A newer copy came from a newer tool that relies on it; ordering needs a number, so an unversioned file can never be ordered and is overwritten.
**Approved**: pending

**Decision**: A bundle with a missing or unversioned dispatcher still works when a versioned one is installed.
**Rationale**: The installed copy is enough to run; failing would cost a user the status line over a packaging detail.
**Approved**: pending

**Decision**: A command found in the slot is adopted as a renderer, and earlier adopted renderers are removed.
**Rationale**: The slot holds one command, so the one found there replaced the previous; resurrecting the old would bring back a line the person replaced.
**Approved**: pending

**Decision**: The dispatcher command string is identical to the one claudehelpers' Python writes.
**Rationale**: Two writers of different strings would rewrite the slot back and forth.
**Approved**: pending

**Decision**: This type edits no `settings.json`.
**Rationale**: The lock and the merge with hooks belong to the installer; keeping the file side separate leaves the dependency pointing downward.
**Approved**: pending

**Decision**: The tree is owner-only and each file is created at its final mode.
**Rationale**: An adopted command may carry a token, so no window may exist where it is readable by others.
**Approved**: pending

