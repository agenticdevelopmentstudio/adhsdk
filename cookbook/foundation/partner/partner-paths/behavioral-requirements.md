
- **value-semantics**: `PartnerPaths` MUST be a value type that is `Sendable`, holding exactly the two stored values `home` (a URL) and `token` (a string) given to its initializer.
- **equality**: `PartnerPaths` MUST be `Equatable`, and two values MUST be equal when their `home` and `token` are equal.
- **partner-directory**: `directory` MUST be `home`, then a path component of a dot followed by `token`, then the component `partner`.
- **mcp-config-file**: `mcpConfig` MUST be the file `mcp.json` inside `directory`.
- **system-prompt-file**: `systemPrompt` MUST be the file `system-prompt.md` inside `directory`.
- **jobs-directory**: `jobsDirectory` MUST be the directory `jobs` inside `directory`.
- **reviews-directory**: `reviewsDirectory` MUST be the directory `reviews` inside `directory`.
- **skills-directory**: `skillsDirectory` MUST be `home`, then `.claude`, then `skills`; it MUST NOT depend on `token`.
- **skill-file**: `skillFile(jobID:)` MUST be the file `SKILL.md` inside a directory named `adkitchen-partner-` followed by the job ID, inside `skillsDirectory`.
- **no-file-access**: Every derived location MUST be computed from the two stored values alone; no property or function MAY read, create or check the file system.
- **no-validation**: The type MUST NOT validate `home`, `token` or `jobID`; a caller that takes any of them from outside the app owns checking it before use.

