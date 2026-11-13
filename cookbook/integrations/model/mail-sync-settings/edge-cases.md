
- **Empty object**: `{}` MUST decode to `default`; the doc comment says a missing key takes its default.
- **Null key**: A key set to null MUST take the default, the same as a missing key.
- **Unknown extra keys**: Keys other than the five MUST be ignored (decode-ignore-unknown).
- **Wrong-typed value**: A key with the wrong JSON type MUST make decoding throw; leniency covers absent keys only.
- **Boundary values**: `windowDays` of 1 and 3650 and `pollIntervalMinutes` of 1 and 1440 MUST pass validation; 0, 3651 and 1441 MUST fail.
- **Negative numbers**: A negative `windowDays` or `pollIntervalMinutes` is outside its range and MUST fail validation with the offending value in the message.
- **Both numbers invalid**: Only the `windowDays` error is raised, because it is checked first.
- **Unvalidated instances**: An instance built by decoding or the initializer can hold out-of-range numbers; a caller that skips `validated()` carries them forward. The service validates on update, and this type does not stop other callers.
- **Concurrent access**: Not applicable; the type is a `Sendable` value with no shared state, so each thread works on its own copy.
- **Offline or error states from dependencies**: Not applicable; the type has no network, file or database dependency. The only error it raises is `IntegrationError.invalidSettings`.
- **Cancellation and timeouts**: Not applicable; every operation is synchronous and returns immediately.

