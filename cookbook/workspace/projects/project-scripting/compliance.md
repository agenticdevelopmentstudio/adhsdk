
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |

Notes: separation-of-concerns passes because
`ProjectWindowManager+Scripting.swift` and its three wrapper types own only
enumeration, lookup, and Cocoa Scripting addressing; they delegate every
piece of domain behavior to a collaborator — git branch resolution to
`ProjectController`/`BranchController`, pane mutation to `pane.host`, window
mutation to `ComposableTabsWindowController` — and, per `ScriptablePane.swift`'s
own doc comment, exist as wrappers specifically so that "KVC scripting keys"
never get "pinned onto the view controller" itself. unit-test-coverage
is partial: `ProjectScriptingTests.swift` (30 test methods) exercises window,
tab and pane enumeration and lookup including unknown-id misses, branch
resolution both matching and unmatched, the one-tab-two-panes multi-edge
case, pane property reporting (name, selection, project, tab, minimized,
zoomed), the unrecognized-edge-name restore path, and a host-declined
minimize — but no test deallocates a `ScriptableProjectWindow`'s `controller`
and reads its properties afterward (see **window-degrades-when-controller-is-gone**),
so that specific fallback path is verified only by reading the source, not by
a passing test. graceful-degradation passes because every optional chain in
these four files — a deallocated window controller, a missing project
controller, a missing branch controller, a detached-HEAD branch, an unknown
lookup id, a malformed edge name — resolves to a documented default
(`""`, `false`, `"no"`, or `nil`) rather than crashing or propagating an
error.

