
The Pool checkbox, the Dead jobs section and the two client calls are not written yet. These vectors
are the tests the package's `__tests__/` MUST carry for them.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| processing-admin-001 | worker-token-pool-checkbox | Open the create dialog | The Pool checkbox is present and unchecked. |
| processing-admin-002 | worker-token-pool-checkbox | Create a token named `edge-1` with Pool checked | The create call's body is `{ name: "edge-1", pool: true }`. |
| processing-admin-003 | worker-token-pool-checkbox, worker-token-name-required | Create a token named `  edge-2 ` with Pool unchecked | The create call's body is `{ name: "edge-2", pool: false }`. |
| processing-admin-004 | dead-jobs-section | Two dead rows, the newer second in the response | Both are listed with the newer first. |
| processing-admin-005 | dead-jobs-retry | Retry a dead row; the call succeeds | `retryDeadJob` is called with the row's id and the row leaves the list. |
| processing-admin-006 | dead-jobs-retry-failure-shown | Retry a dead row; the call answers 409 | The error is shown and the row stays. |
| processing-admin-007 | dead-jobs-empty | No dead rows | The section says "No dead jobs." |
| processing-admin-008 | admin-topics-unchanged | The operator admin topics | No topic is labelled "Jobs" or "Queue". |

