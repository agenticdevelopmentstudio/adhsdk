
- **Decision**: Compute the verdict on the server and publish it as `selfCheck`.
  **Rationale**: Stated in the source comment: so the bar and the KPI pill "render a verdict instead of each filtering the checks with its own copy of the rule".
  **Approved**: pending
- **Decision**: Show missing env vars in one deduped chip and keep those checks out of `issues`.
  **Rationale**: Stated in the source comment: a check that reports them "is not chipped again as an issue".
  **Approved**: pending
- **Decision**: Never chip the internal `cron` check.
  **Rationale**: Stated in the source comment: it is "wallboard noise". It is a hardcoded id with no shared constant tying it to the code that creates the cron check, so a renamed check would reappear in the bar. This coupling is a known risk.
  **Approved**: pending
- **Decision**: Collapse correlated provider failures into the Connectivity chip by excluding them from `issues`.
  **Rationale**: Stated in the source comment; the `correlated` flag and the synthetic `connectivity` check come from `self-check-stability.ts`.
  **Approved**: pending
- **Decision**: Take severity from the checks' own state and never force an unset variable red.
  **Rationale**: Stated in the source comment ("an unset variable is never forced red"); `missingEnvError` is red only when a check already reported `error`.
  **Approved**: pending
- **Decision**: Count missing variables (distinct names) and issues together in `issueCount`.
  **Rationale**: The `SelfCheckView` doc comment says it is "how many things the bar lists (issues + missing variables) — the KPI pill's count".
  **Approved**: pending

