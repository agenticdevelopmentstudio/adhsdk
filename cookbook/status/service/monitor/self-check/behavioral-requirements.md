
### Missing environment variables

- **missing-env-collection**: `selfCheckView` MUST gather the `missingEnv` arrays of every check whose `missingEnv` is present and non-empty, concatenated in check order.
- **missing-env-dedupe**: The result's `missingEnv` MUST contain each variable name once, at the position of its first occurrence in check order.
- **missing-env-error-flag**: The result's `missingEnvError` MUST be `true` if and only if at least one check that reports missing variables has `state === "error"`; a check with `state` `"warn"` that reports missing variables MUST NOT set it.
- **missing-env-not-an-issue**: A check that reports missing variables MUST NOT appear in `issues`, so it is shown once in the env chip and not chipped again as an issue.

### Issues

- **issue-selection**: `issues` MUST contain, in input order, exactly those checks that satisfy all four conditions: `state` is not `"ok"`, `id` is not `"cron"`, `missingEnv` is absent or empty, and `correlated` is not truthy.
- **cron-excluded**: A check with `id === "cron"` MUST NOT appear in `issues`, per the source comment that the internal cron check "is wallboard noise and never chipped". It still counts toward `missingEnv` if it reports missing variables.
- **correlated-excluded**: A check with a truthy `correlated` MUST NOT appear in `issues`, per the source comment that a correlated provider failure is collapsed into the backend's Connectivity chip. The synthetic `connectivity` check (an ordinary non-ok check) is therefore the one that appears.
- **issue-identity**: `issues` MUST hold the original check objects from the input, not copies.
- **warn-is-issue**: A check with `state === "warn"` that meets the other conditions MUST appear in `issues`; only `"ok"` is excluded by state.

### Verdict

- **null-when-clean**: The function MUST return `null` when `missingEnv` is empty and `issues` is empty.
- **result-shape**: Otherwise the function MUST return an object with exactly the fields `missingEnv`, `missingEnvError`, `issues`, `hasError` and `issueCount`, as declared by `SelfCheckView` in `types.ts`.
- **has-error**: `hasError` MUST be `true` if and only if `missingEnvError` is `true` or at least one entry of `issues` has `state === "error"`.
- **issue-count**: `issueCount` MUST equal `issues.length + missingEnv.length`, where `missingEnv.length` counts distinct variable names, not checks. It is the count the KPI pill shows.
- **severity-follows-state**: Severity MUST come only from the checks' own `state`; the function MUST NOT raise an unset-variable check to error on its own ("an unset variable is never forced red").
- **purity**: The function MUST NOT mutate `checks`, any check, or any `missingEnv` array, and MUST NOT perform I/O, read the clock or log.
- **readonly-input**: The function MUST accept a `readonly IntegrationCheck[]`.

