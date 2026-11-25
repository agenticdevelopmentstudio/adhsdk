
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.safe-defaults](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/dd43bec7-e292-559a-81e3-c0cf59156abe) | passed | Reliability |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy and Data |

`separation-of-concerns` passes: the contract (`workspaces-menu.tsx`) holds
no data logic, the feed holds only the mapping from rows to menu rows, and
reading, naming and de-duplicating rows stays in the data layer.
`unit-test-coverage` passes: `workspacesFeed.test.tsx` holds a test for
every vector above. `explicit-error-handling` passes: a failed read reaches
the menu as `error`, never as an empty list. `graceful-degradation` passes:
with nothing registered a route-mode pick still follows `/<slug>`, and an
unknown preference falls back to the personal workspace. `safe-defaults`
passes: the default mode navigates nowhere, and with no subject no request
fires. `data-minimization` passes: the menu receives only id, label, href
and current.

