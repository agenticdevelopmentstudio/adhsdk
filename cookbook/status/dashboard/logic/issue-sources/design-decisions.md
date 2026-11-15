
**Decision**: Mirror the server's vocabulary by hand instead of sharing a module.
**Rationale**: Both files' doc comments name each other and promise "same union, same labels, same order". The client indexes `SOURCE_LABEL[row.source]`, so agreement is what keeps labels from rendering `undefined`. No shared package, generator or parity test exists, so agreement rests on editing both files together.
**Approved**: pending

**Decision**: Keep `glitchtip` as its own source rather than folding it into `http`.
**Rationale**: The doc comment says the other sources answer reachability while GlitchTip answers whether the site is throwing, and a site can be up on every probe with an error Problem open.
**Approved**: pending

**Decision**: The stuck-deploy threshold was removed from the client and stays on the server.
**Rationale**: The client once held a mirror of `STUCK_DEPLOY_MS` that no client code read. The threshold is now the server's alone (`STUCK_DEPLOY_MS` and `deployIsStuck`); the board publishes the resulting Problem and the client renders it, so a second copy could only drift.
**Approved**: pending

**Decision**: Add `isIssueSource` on the client only.
**Rationale**: Its doc comment says it lets a caller "filter/index by it without an unchecked `as IssueSource` cast". `row-model.ts` explains that `Row.source` is a plain string that can fall back to an activity `kind`, and the guard turns the fallback into a real branch.
**Approved**: pending

**Decision**: The platform-unreachable debounce stays out of this module.
**Rationale**: The closing note says the server's `applyPlatformIssues` and the `platform_health_state` table own the streak and threshold and publish a `platform-health|<source>` Problem, which the client renders as given.
**Approved**: pending

