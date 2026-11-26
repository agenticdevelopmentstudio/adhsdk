
**Decision**: Every stored field is a mutable `var`, and `ownLockName` and `statusLineEntryName` are filled once at initialization.
**Rationale**: Plain mutable fields let an owner adjust one value of a configuration without rebuilding it; the cost is that changing `name` later leaves the two derived fields stale, so a caller that renames SHOULD set them again.
**Approved**: pending

**Decision**: One value type carries every per-owner difference, and several owners install into one `settings.json`.
**Rationale**: Claude Code runs every matching hook entry, so owners coexist when each recognises, updates and removes only entries carrying its own marker; a single configuration keeps those differences in one place.
**Approved**: pending

**Decision**: `defaultHookedEvents` excludes the delegation and non-hook types, but a caller-supplied `hookedEvents` is stored as given.
**Rationale**: The installer applies the exclusion again at registration, so the filter at this type is a default and not the only guard; the exclusion rule itself lives in `ClaudeHookInstaller`.
**Approved**: pending

**Decision**: The initializer does no validation and derives file names by concatenation.
**Rationale**: The shipped owners pass fixed literals, so a check would guard no real caller; the cost is that a bad `name` produces odd file names silently, which is deliberate debt, and why callers only SHOULD pass a short `name` of letters, digits and hyphens.
**Approved**: pending

**Decision**: The drop directory is stored in tilde form and the helper path is absolute.
**Rationale**: Hooks run the helper by absolute path so they follow a bundle wherever it lives; the tilde form is what hook commands carry and the writer expands it.
**Approved**: pending

**Decision**: `bundledHelperPath` force-unwraps `Bundle.main.executableURL` in its default argument.
**Rationale**: A running macOS process normally has an executable URL, so the default keeps the common call short; a process that cannot guarantee one MUST pass `executable`, and tests pass it explicitly. Without one the default traps instead of returning an error.
**Approved**: pending

