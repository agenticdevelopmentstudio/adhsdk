
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | passed | Accessibility |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | Reliability |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | Security |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |

`reduced-motion` is passed: `Reflexes`/`reflexes.ts` gate ambient loop
re-arming on the environment's predicate, tested on both platforms.
`explicit-error-handling` is passed: `setMood` and `play` validate before
committing and raise a named, message-bearing error rather than failing
silently or corrupting state. `unit-test-coverage` is passed:
`EngineTests.swift` (13 methods) and `engine.test.ts` cover construction,
determinism, frame-rate independence, every command, and the shared-PRNG and
reduced-motion contracts. `fault-tolerance` is partial: the `Scheduler` this
engine ticks first every frame tolerates a non-monotonic `now` and bounds its
catch-up loop, but the saying-list-emptiness path is fatal and uncatchable on
Apple rather than degrading gracefully (see the corresponding Design
Decision). `input-sanitization` is passed: `setMood` and `play` both check
their string argument against the loader-approved mood/timeline sets before
any state mutation. `separation-of-concerns` is passed: `Engine.swift`/
`engine.ts` hold only the tick/state-machine orchestration and
`Environment.swift`/`env.ts` hold only the injected clock/reduced-motion
predicate, with no rendering code in either file — the render path lives
entirely in the sibling avatar-engine-render recipe.

