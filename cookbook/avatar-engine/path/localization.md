
Not applicable: the error strings this layer throws (`PathError.description`
in `ParsedPath.swift`; the `Error` messages in `parse.ts`/`build.ts`/
`morph.ts`/`promote.ts`) are internal diagnostic text read by callers and
tests, not user-facing UI copy, and none of the given sources contains a
localization or string-table mechanism.

