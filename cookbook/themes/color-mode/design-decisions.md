
**Decision**: Persist `auto` by removing the stored key instead of writing `auto`.
**Rationale**: Inferred from the source, which removes the key when `mode` is `auto`; it keeps storage empty for users who never chose, but it makes `defaultMode` and the legacy key take effect again after an `auto` choice.
**Approved**: pending

**Decision**: Keep the pre-rename key `agentic-toolkit:color-mode` as a read-only fallback for the default `storageKey`.
**Rationale**: The source comment says builds from before the SDK rename stored the same choice there; reading it preserves users' choices without a migration step, at the cost of never deleting the old value.
**Approved**: pending

**Decision**: Keep this Provider-based context separate from the newer appearance system and forbid mounting both.
**Rationale**: The header comment states the two use different keys and attributes and the legacy one stays until the toolkit migrates; `useAppearancePreferences` is canonical for ADH.
**Approved**: pending

**Decision**: Cycle in the order `auto`, `dark`, `light`.
**Rationale**: The `CYCLE` constant fixes the order; the source gives no reason, so the order is recorded as observed.
**Approved**: pending

**Decision**: Broadcast changes and accept cycle requests through `window` events (`awt:appearance-changed`, `awt:appearance-cycle`).
**Rationale**: Inferred from the source: it lets non-React code and unrelated components react to or trigger a cycle without sharing the context.
**Approved**: pending

