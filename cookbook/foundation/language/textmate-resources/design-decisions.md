
**Decision**: Themes are filtered by the same licence list as grammars.
**Rationale**: A GPL-3.0 theme file shipped in the app carries the same obligation as a GPL-3.0 grammar; one rule for both keeps the licence position in one place.
**Approved**: pending

**Decision**: Licence texts come from the packages' NOTICE files, never from the network.
**Rationale**: The build must be a pure function of the lock file for `--check` to mean anything; every shipped item's NOTICE entry carries its text, and an item without one stops the build instead of shipping unlicensed.
**Approved**: pending

**Decision**: Grammar and theme files are copied verbatim, not re-serialised.
**Rationale**: Their bytes stay identical to the pinned package, which keeps the checksums comparable with upstream and the diff of a version bump honest.
**Approved**: pending

