
**Decision**: A named instance exists only if its definition file does, and asking for a name with no definition is a hard error.
**Rationale**: The type's doc comment states that creating an empty store for a typo would look like data loss. Refusing with `undefined`, which names the expected path and the command that creates it, makes the typo visible.
**Approved**: pending

**Decision**: The environment variable wins over the `-instance` argument, and a present but empty variable selects the default.
**Rationale**: The doc comment on `requestedName` states that the daemon and the CLI are selected by environment and that an app passes its own selection to the daemon the same way, so the environment is the authoritative channel. The empty-value rule follows from the source checking for the key before its value.
**Approved**: pending

**Decision**: Reserved names and ports are fixed sets: names `usagewidget`, `instances` and `daemon`; ports 22848 and 22849.
**Rationale**: The doc comments on `reservedNames` and `reservedHTTPPorts` give each reason: the label `<baseLabel>.<name>` is already taken by the usage widget, the definitions directory and the installed daemon's launch-throttle identifier (whose `/tmp/<identifier>.launches` an instance's app guard would share), and the ports belong to the installed account router and the retired Kitchen daemon adkd that an installed Kitchen may still run. The retired stenographerd's 22847 was reserved until adhd took over serving Stenographer (apps suite phase 3); nothing listens there now.
**Approved**: pending

**Decision**: A named instance's data root may not equal, contain or lie inside anything the installed copy owns: the current and legacy data roots, the current and legacy logs, and `~/.claude`.
**Rationale**: The doc comment on `protectedRoots` lists these, and `~/.claude` holds the hook socket, the drop directory and `settings.json`. A named instance is a development copy, and the guard keeps it from writing into the installed copy's state.
**Approved**: pending

**Decision**: Two named definitions may not share or nest data roots.
**Rationale**: The comment in `validate` states that each instance's lock is keyed on its own label, so nothing else stops two definitions that share a data root from running on one set of databases.
**Approved**: pending

**Decision**: Paths are compared after Python `os.path.realpath`-style canonicalisation, lowercased, with a leading `/System/Volumes/Data` dropped before and after resolving, and dangling symlinks followed.
**Rationale**: The doc comment on `canonicalComponents` states the rules match what `check_definition` in `scripts/stenographer_instance.py` uses, so the script and the Swift resolver refuse the same definitions. Lowercasing reflects the case-insensitive default APFS volume, and the firmlink rule reflects that `/System/Volumes/Data` reaches the same files while realpath keeps it as written. The dangling-link branch exists because `realpath(3)` fails on a dangling link where `os.path.realpath` follows it, per the comment in `canonicalPath`; the 32-link depth bound keeps a cycle finite.
**Approved**: pending

**Decision**: A peer definition that cannot be read is skipped in the overlap check rather than failing the instance being resolved.
**Rationale**: The doc comment on `otherDefinitions` states that one that cannot be read is resolved, and refused, on its own, so a broken sibling file does not block every other instance.
**Approved**: pending

**Decision**: A process whose instance cannot be resolved exits with status 78 (`EX_CONFIG`) and the reason on stderr, rather than crashing.
**Rationale**: The doc comment on `current` states that a normal exit keeps launchd's `KeepAlive: {Crashed: true}` from relaunching the process into the same failure.
**Approved**: pending

**Decision**: The socket path `<dataRoot>/stenographer.sock` must be under 104 UTF-8 bytes.
**Rationale**: The doc comment on `socketPathLimit` states that `sockaddr_un.sun_path` is 104 bytes on Darwin including the NUL, so a longer path could not be bound; refusing at definition time surfaces this before the daemon starts.
**Approved**: pending

