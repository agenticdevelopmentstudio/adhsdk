
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | partial | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | passed | Reliability |
| [adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674) | passed | Reliability |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | passed | Performance |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

Notes: separation-of-concerns is partial because eight of the nine given
sources (`HTDVController`, `HTDVModel`, `HTDVCellContent`, `HTDVLayoutEngine`,
`FormSpec`, `FormValue`, `FormState`, `FormValidator`) import only
`Foundation` and hold no view-framework dependency beyond the opaque
`PlatformViewController` type, but the ninth, `MarkdownEditing.swift`,
bundles the `MarkdownEditing` protocol together with a concrete
AppKit/UIKit default implementation in the same file - see Design
Decisions. unit-test-coverage passes because every one of the nine sources
has a corresponding test file with meaningful assertions:
`HTDVControllerTests.swift` (29 tests, including stale-result protection),
`HTDVLayoutEngineTests.swift`, `HTDVModelTests.swift`, `FormStateTests.swift`,
`FormValidatorTests.swift`, and `PlainTextMarkdownEditingTests.swift`.
explicit-error-handling passes because every `throws` boundary in these
sources is caught and turned into explicit, observable state -
`HTDVController.fail(...)` sets `error`, `FormState.save()` sets
`saveError` - with the one narrower exception noted under Edge Cases'
**create-action-error-path**, where the action's own signature is
non-throwing rather than an error being caught and dropped.
error-recovery passes because `retry()` re-issues exactly the operation
that failed and `FormState.revert()`/a subsequent `save()` let a failed
save be corrected and retried. state-recovery passes because `reload`
reconciles a level whose selected item disappeared or whose parent stopped
being a `.level`, truncating rather than leaving stale, inconsistent state
in place. main-thread-freedom passes because `HTDVController` and
`FormState` are `@MainActor`-confined but their `dataSource`/action calls
are `await`ed, which suspends rather than blocks the main actor while a
data source or save action does its work. no-hardcoded-strings fails
because every user-facing string these sources produce - `FormValidator`'s
messages, `HTDVLevel.emptyMessage`'s default, `FormDeleteAction`'s
documented confirmation fallback - is a hardcoded English literal with no
localization key, per Localization above.

