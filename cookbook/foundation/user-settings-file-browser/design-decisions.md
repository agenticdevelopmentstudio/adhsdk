
**Decision**: The excluded patterns are one shared setting for every file browser, not a per-browser or per-root setting.
**Rationale**: The doc comment reads "What every file browser in the app leaves out", and every browser takes the same setting as the default of its `exclusions` parameter. Per-root control is not offered by this setting.
**Approved**: pending

**Decision**: The default is the empty list, so nothing is hidden until the user adds a pattern.
**Rationale**: The doc comment says "Empty by default, so the setting changes nobody's tree until it is used."
**Approved**: pending

**Decision**: The patterns are stored as raw strings in gitignore syntax and are not parsed or validated at the setting.
**Rationale**: Parsing belongs to `GitIgnoreMatcher`, so the stored list stays editable text in order, comments and blanks included, and a list copied from a `.gitignore` behaves the same. Validation at write time would reject input the matcher already tolerates.
**Approved**: pending

**Decision**: The setting is a `static var` extension member on `UserSettings` rather than a constant.
**Rationale**: It follows the sibling declarations in `UserSettings+Git.swift`, `UserSettings+Editor.swift` and `UserSettings+Theme.swift`, which each add typed settings to the same namespace in their own file. The source gives no further reason for `var` over `let`.
**Approved**: pending

