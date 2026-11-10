
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | partial | Performance |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | partial | Reliability |

`separation-of-concerns` **passed**: each of the three pieces has exactly one
job — `AppleScriptRunner` only compiles/executes AppleScript source and
structures the outcome, `MainActorScriptCommand` only bridges Cocoa
Scripting's dispatch onto the main actor, and `applicationElementSpecifier`
only builds one kind of `NSScriptObjectSpecifier` — with no UI, persistence,
or networking code mixed into any of them. `unit-test-coverage` is
**partial**: `AppleScriptRunner` and `MainActorScriptCommand` each have a
dedicated `Tests/.../Scripting/*Tests.swift` suite with meaningful
assertions (see Conformance Test Vectors), but `applicationElementSpecifier`
has no test file among the given sources or found elsewhere in the
repository. `explicit-error-handling` **passed**: `AppleScriptRunner.run(_:)`
never drops a compile or runtime failure — every failure path returns a
distinct, inspectable `Result` case; nothing is caught and discarded.
`main-thread-freedom` is **partial**: `AppleScriptRunner.run(_:)` executes
synchronously and can block whichever thread calls it for the duration of
the AppleScript's execution, with no timeout and no async variant; the
component leaves avoiding a main-thread block entirely to the caller (see
`caller-main-thread-marshaling`). `fault-tolerance` is **partial**:
`applicationElementSpecifier` degrades safely to `nil` when its AppKit
dependency is in an unexpected state, but it and
`MainActorScriptCommand.performDefaultImplementation()` both trap via
`MainActor.assumeIsolated` if ever invoked off the main thread — a
deliberate fail-fast choice (see Design Decisions) that satisfies
[adc.principle.fail-fast](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/425271ea-92b6-4df6-9a83-94795f1be377) but not this check's literal
"without crashing" bar.

