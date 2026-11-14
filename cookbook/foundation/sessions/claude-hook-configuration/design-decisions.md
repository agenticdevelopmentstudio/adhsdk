
**Decision**: One value type carries every per-owner difference, and several owners install into one `settings.json`.
**Rationale**: Claude Code runs every matching hook entry, so owners coexist when each recognises, updates and removes only entries carrying its own marker; a single configuration keeps those differences in one place.
**Approved**: pending

**Decision**: `defaultHookedEvents` excludes the delegation and non-hook types, but a caller-supplied `hookedEvents` is stored as given.
**Rationale**: The installer applies the exclusion again at registration, so the filter at this type is a default and not the only guard; the exclusion rule itself lives in `ClaudeHookInstaller`.
**Approved**: pending

**Decision**: The initializer does no validation and derives file names by concatenation.
**Rationale**: The shipped owners pass fixed literals, so a check would guard no real caller; the cost is that a bad `name` produces odd file names silently.
**Approved**: pending

**Decision**: The drop directory is stored in tilde form and the helper path is absolute.
**Rationale**: Hooks run the helper by absolute path so they follow a bundle wherever it lives; the tilde form is what hook commands carry and the writer expands it.
**Approved**: pending

**Decision**: `bundledHelperPath` force-unwraps `Bundle.main.executableURL` in its default argument.
**Rationale**: A running macOS process always has an executable URL; the force-unwrap makes the impossible case a trap, and tests pass `executable` explicitly.
**Approved**: pending

