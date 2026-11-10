
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.security.secure-storage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bb5dfc9b-c5b0-54fa-882f-007ae7dad0e9) | passed | Security |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | Security |
| [adc.check.security.cors-allowlist](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/7f948bd2-a0b7-580c-ae8a-338ca39339d4) | passed | Security |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy and Data |

`separation-of-concerns` passes: `port.ts` defines the contract and its pure
derived helpers, `env.ts` is the one shipped adapter for a twelve-factor
host, and `seed.ts` is an independent port for a differently-shaped concern
(the host's site roster); the fan-out logic, HTTP routes, and every
consumer named in Overview live one layer up, outside all three files.
`unit-test-coverage` passes: `config-env.test.ts` exercises the guard, the
credential map, `deploySyncSeconds`, `glitchtipProjects`, and
`monitorLabel`; `config-cadence.test.ts` exercises `deploySyncIntervalMs`;
`config-clone.test.ts` exercises the structured-clone/plain-data contract;
and `config.int.test.ts` exercises the seed roster's empty and populated
fan-out counts. `explicit-error-handling` is `partial`: the SEC-M5 guard
fails fast with a specific, descriptive `Error`, but `port` and
`probeIntervalSeconds` let a malformed numeric env value become `NaN` with
no error and no distinguishable signal — see the open question on
numeric-env-validation, recorded as a fact rather than defended.
`secure-storage` passes for what these three files themselves do: none of
them writes a credential to disk, a database, or any other store; the
process environment is the storage, owned by the host's deployment
platform, external to this recipe's three files. `secure-log-output`
passes trivially — per Logging, there is no log output in these files to
leak a credential into. `cors-allowlist` passes: `corsAllowedHosts` and
`mcpAllowedHosts` are built as an explicit, finite array of host names with
no wildcard sentinel in the type or the `list()` helper; the check's
"never wildcards with credentials" concern is a decision for the external
middleware that reads this array, not something these three files could
violate on their own. `no-pii-in-logs` passes the same way
`secure-log-output` does — there is no log output in these files to carry a
credential or an admin email into.

