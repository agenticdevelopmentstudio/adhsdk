
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.state-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/6e64e2f2-28ad-55d5-a8ed-cee075366674) | partial | Reliability |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | passed | Performance |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | Security |

Notes: separation-of-concerns passes because `ProjectWindowManager` owns
exactly window/controller lifecycle bookkeeping — the `controllers`/
`openOrder`/`projectControllers`/`keyObservers`/`closeObservers` tables — and
delegates every git read and tab-reconciliation decision to
`ProjectController`, every persistence read/write to `ProjectDatabase` through
`ProjectWorkspace`, and every pane/tab render decision to
`ComposableTabsWindowController`; it never reads git output or a tab record
itself. unit-test-coverage is partial because
`ProjectWindowManagerControllerTests.swift` exercises opening, reopening,
activation, key-observer refresh, adoption/fallback teardown routing, closing
mid-open-task, the two-writer debounce race, and synchronous `markClosed()`
timing — but `restorePlan`, `restoreOpenProjects`, and
`shutdownAllLanguageServices` have no test anywhere in the repository
(vectors -011 and -012 above are synthesized to describe what such tests
would assert). explicit-error-handling is partial: the two
`ProjectDatabase`-setting paths and the missing-language-factory path all log
their failure, but `openProject(_:)`'s missing-database guard gives the
caller no signal beyond that log — see
**no-database-open-failure-signal**. graceful-degradation passes because a
missing database, a missing language-service factory, and a missing-on-disk
folder at restore each fall back to a documented, reduced behavior (no
window, no completions, no reopen) rather than crashing or reopening a broken
window. state-recovery is partial because `restoreOpenProjects()` correctly
separates "never opened" from "flagged open, folder gone," but
`isWindowOpen(repoID:)` maps a genuine database read failure to the identical
`false` result as "was never open," so a transient read error at launch
silently drops a window from the restore set with only a log line to show for
it. main-thread-freedom passes because every subprocess- or database-bound
wait this file starts (`ProjectController.open()`/`refreshCheckouts()`, each
service's `shutdown()` inside the task group, `PendingTeardowns.drain()`) is
reached through `await`, releasing the main actor for the suspension.
secure-log-output passes because every log call names only a repo's UUID,
name, or path — already visible to the user in the project browser and the
window's own title — and no credential, token, or other secret is logged
anywhere in this file.

