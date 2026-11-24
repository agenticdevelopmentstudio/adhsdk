
Vectors 001, 002 and 025 are the runtime assertions in `dashboard-types-parity.test.ts`; the others are compile-time type checks in the same file. Client reading rules over server data are not vectors here: that behavior is not in this module (see Design Decisions).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| dtypes-001 | ranges-list, mirror-constants | test "offer the same ranges": the web `ANALYTICS_RANGES` and the server's | equal lists `["24h","7d","30d"]` |
| dtypes-002 | dimensions-list, vercel-breakdowns-list, vitals-list, mirror-constants | test "name the same breakdowns and vitals": the three web lists and the server's | each pair equal, in order |
| dtypes-003 | mirror-parity | type check: the exported `responsesAgree` tuple of five mutual-assignability checks | compiles only while the analytics response, errors response, runtime report and both views agree; fails the type check otherwise |
| dtypes-009 | errors-envelope | errors response with `refreshingSources` of glitchtip true and posthog false | `refreshing` true |
| dtypes-012 | runtime-window | runtime report | `window` is `"24h"` |
| dtypes-015 | analytics-sections, section-shape | analytics response | exactly the six sections `traffic`, `dimensions`, `paths`, `vitals`, `health`, `vercel`, each typed with nullable `data`, `error` and `updatedAt` |
| dtypes-016 | errors-sections | errors response | exactly the four sections `issues`, `sites`, `detail`, `runtime` |
| dtypes-017 | envelope-common | either response | carries `generatedAt`, `refreshing`, `configured` and `views` |
| dtypes-018 | analytics-envelope | analytics response | carries `range` and `configured` flags for `posthog` and `vercel` |
| dtypes-025 | types-only | importing the module | only the four lists exist at run time; nothing else runs at load |
