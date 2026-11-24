
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | Best Practices |

`separation-of-concerns` passes because this file is a bare protocol: it declares the tree seam's shape and carries zero rendering, storage, or transport logic of its own — every side effect happens on the conformer's side (`MainThreadTreeViews.swift`) or the caller's side (`ExtensionTreeViewController.swift`), both out of this recipe's scope. `unit-test-coverage` is partial: a bare protocol has no body to unit-test directly, so its contract is exercised only indirectly, through `MainThreadTreeViewsTests.swift`'s tests of the one given conformer; those cover activation, chrome, selection, visibility, expand/collapse, and change-event semantics, but no test in the given sources isolates each of `children(of:)`'s four documented failure causes individually (see etds-010). `explicit-error-handling` is partial: no method here is declared `throws`, and `children(of:)`'s empty-array answer for every failure is a deliberate, documented choice rather than a silent swallow (see Design Decisions) — but it leaves conformers with no typed error channel, and the open question on **in-flight-request-during-replacement** is exactly the kind of ordering gap that absence leaves unresolved.

