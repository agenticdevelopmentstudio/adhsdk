
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |

`unit-test-coverage` is `partial`: `deploy-env.test.ts` thoroughly exercises `envFromBranch` and `deployEnv`, including the Object.prototype boundary and every signal-precedence case, and exercises `isRealEnvDeployRow` indirectly through `providerDeployToDTO`'s `tier` assertions — but `isRealEnvDeploy`, `deployLinks`, and the `Indicator`/`IndicatorState` shapes have no dedicated test anywhere in this package. `separation-of-concerns` passes: the file's own header comment states its scope precisely (deploy/environment and link derivation only), explicitly disclaiming row construction (the web client's job) and problem derivation (the board's job); it reads no configuration and performs no I/O of its own. `explicit-error-handling` passes: every "no signal" case is propagated as an explicit `null` return (`envFromBranch`, and `isRealEnvDeployRow`'s DTO-level `tier` gate in `provider-deploy.ts`) rather than silently defaulting or throwing, and the one place a real exception could occur — URL parsing inside `projectPageUrl` — is caught there and turned into an explicit fallback value, not swallowed without a trace. `fault-tolerance` passes: the module accepts arbitrary caller-supplied strings (branch names, project names, URLs) including ones deliberately shaped to break a naive object-literal lookup, and every function returns a well-typed result rather than throwing for any input in its documented domain.

`unit-test-coverage`'s gap is the open question on `isRealEnvDeploy`/`deployLinks`/`Indicator`/`IndicatorState` — see the corresponding Design Decision above.

