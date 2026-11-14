
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |
| [adc.check.privacy-and-data.data-retention-policy](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0c9cc813-244a-5dc1-8914-fd4710bb4943) | passed | Privacy and Data |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |

`explicit-error-handling` passes: every asynchronous write the container
performs itself — `onSave`, the repair write, and the repair pass's own
"still invalid after repair" case — is caught and surfaced, either as a
rendered `role="alert"` message or as a logged-and-shown repair failure;
nothing given in the sources swallows an error silently. `separation-of-
concerns` passes: the container owns draft state, validation, layout
coverage and the repair decision, but delegates persistence to the caller's
`onSave`/`onRepair`, control rendering to `@adh-sdk/ui`, and
the navigation guard/alert chrome to an injected `EditingHost`.
`unit-test-coverage` is partial: the package's own nine test files exercise
validation, sections, the repair plan, the container's save/cancel/re-
seeding/layout-fault paths, nesting/rollup, every control kind, the guard
integration and the full repair UX flow in detail, plus a dedicated
compile-time suite for the generic contract — but `useDirtyDraft`'s own
equality semantics are tested in the `ui` package rather than duplicated
here, and nothing in this package's tests exercises two containers editing
the *same* record concurrently. `graceful-degradation` passes: a layout
fault renders as a visible alert and the pane continues rendering rather
than throwing; an unlisted `select` value is shown rather than crashing or
silently substituting the first option. `fault-tolerance` passes: a
`repair()` that produces another invalid value is caught before any write
is attempted, and a rejected repair write leaves the pane in a working,
retryable state rather than a stuck one. `data-minimization` and
`data-retention-policy` pass: the container adds no storage or retention of
its own beyond the mounted component's lifetime, as detailed under Privacy
above. `string-externalization` fails: every user-facing string this
package produces — `"Required."`, the unlisted-choice and layout-fault
messages, the three repair-flow alert titles and their description — is a
hardcoded English literal with no localization key or i18n library
involved, as detailed under Localization above.

