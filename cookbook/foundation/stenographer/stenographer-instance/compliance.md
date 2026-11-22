
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.reliability.data-integrity](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d773e5db-bb22-5da8-a6f1-953c35a3798d) | passed | Reliability |
| [adc.check.user-safety.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | passed | User Safety |

`separation-of-concerns` passes because the type only selects, reads and validates an instance; writing definitions belongs to `scripts/stenographer_instance.py`, deriving labels, ports and paths for the rest of the product belongs to `StenographerIdentifiers`, and the passive gates belong to the daemon's `InstancePolicy` and the app's `StenographerInstances`. `unit-test-coverage` fails because no test in this repository exercises `StenographerInstance`; the doc comment on `validate` names a shared fixture, `tests/fixtures/instance_definition_cases.json`, that is not present among these sources. `explicit-error-handling` passes because every refusal is a distinct `ResolutionError` case with its context, and `current` reports the error before a deliberate exit. `input-sanitization` is partial: names, data roots, ports, overlaps and socket length are all checked, but a port already held by another named definition is not, which is the open question on `port-unique-across-instances`. `data-integrity` passes because a named data root can never equal, contain or sit inside the installed copy's data or another instance's, compared after symlink, case and firmlink canonicalisation. `safe-defaults` passes because no selection means the installed default, and an unknown name is refused instead of creating an empty store.

