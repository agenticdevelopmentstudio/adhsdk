
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | partial | Reliability |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | Reliability |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`explicit-error-handling` is partial: an unmixable color pair degrades
explicitly to a snap (handled), but an unknown ease name and a malformed
same-kind path both crash/throw uncaught rather than surfacing a catchable,
documented error (see **tween-ease-resolution-fails-closed** and the
malformed-path edge case). `graceful-degradation` is partial for the same
reason, mirrored: recognized-but-unmixable color/path pairs degrade to a snap,
but an unrecognized ease name or malformed path grammar does not degrade —
it fails hard. `fault-tolerance` is partial because the Scheduler's
1000-iteration catch-up guard protects both platforms equally, but the
one-shot stale-time clamp that bounds a long-stopped reflex chain's replay
exists only on Apple (see the corresponding Design Decision). `unit-test-coverage`
is partial because `Channels`/`createChannels` has no dedicated test file on
either platform (`ChannelsTests.swift` and `channels.test.ts` do not exist);
it is exercised only indirectly through `TweenTests.swift`/`tween.test.ts`
and the higher-level `EngineTests.swift`.

