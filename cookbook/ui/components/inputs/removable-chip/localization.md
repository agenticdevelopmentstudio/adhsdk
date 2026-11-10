
RemovableChip hardcodes no user-facing strings itself, but both `children` and
`removeLabel` are caller-supplied, user-facing text. `removeLabel` in particular is a
sentence fragment (e.g. `Remove ${value}`), not just a value substitution, so callers
MUST pass an already-localized string — building it from the current locale's messages,
not a fixed English template.

