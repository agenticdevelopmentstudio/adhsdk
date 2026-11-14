
**Decision**: The set is generic over the controller and builds windows through closures rather than owning a window type.
**Rationale**: The File Browser opens its windows through the project window manager, which must keep knowing about them; the git window builds its own. Closures let both share the bookkeeping without the set depending on either.
**Approved**: pending

**Decision**: The persisted setting is passed in rather than named by the set.
**Rationale**: The File Browser's list already lives under `open_file_browser_directories`; taking the setting keeps remembered windows restoring across the upgrade that moved the File Browser onto the set.
**Approved**: pending

