
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | partial | Reliability |
| [adc.check.performance.main-thread-freedom](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/86dd71d6-1ab1-5d59-8c85-b9d469fbae0d) | passed | Performance |

Notes: separation-of-concerns passes because `BranchController` owns exactly
one checkout's status provider, branch, panes, and commands, delegates all
git work to the injected `GitClient`, delegates status broadcast entirely to
the injected `GitStatusProvider`, and — per its own doc comment — "never
touches the window"; command registration and unregistration with
`CommandRegistry` is `ProjectController`'s responsibility, not this file's.
unit-test-coverage is partial because `BranchControllerTests.swift` exercises
pane reuse and edge/tabID distinctness, a successful branch refresh reloading
panes, checkout-namespaced and cross-checkout-distinct command ids and
categories, and context-menu construction with target retention, but has no
test for `refresh()`'s failure path (see
**refresh-preserves-branch-on-failure**), for overlapping `refresh()` calls
(the pending decision on refresh-ordering), or for the
weak-pane-table eviction (**weak-pane-table**). explicit-error-handling is
partial because `refresh()`'s `catch` block does nothing beyond a comment
explaining why (the failure is recorded in `GitCommandLog` by `GitClient`,
not by this file) — the error is not silently lost system-wide, but this
file's own handling of it is a deliberate no-op rather than an explicit
mapping onto a result the caller can inspect. graceful-degradation passes
because a failed branch read leaves the last-known branch and still reloads
every pane, rather than crashing or blanking the display.
error-recovery is partial because `BranchController` performs no retry or
backoff of its own after a failed `refresh()` — recovery depends entirely on
some caller invoking `refresh()` again (a worktree rescan, another Refresh
Status command). main-thread-freedom passes because every git subprocess
call reaches this controller through `await gitClient.currentBranch(in:)`,
an async suspension point that does not block the main actor while the
subprocess runs.

