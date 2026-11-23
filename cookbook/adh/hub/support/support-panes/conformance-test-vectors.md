
Vectors are to be asserted in `src/__tests__/SupportAccessPane.test.tsx` and `SupportGrantsPane.test.tsx` under `features/support-access`, and beside each operator pane in `features/adh-admin`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| support-panes-001 | pane-grants | One pending, one live and one ended grant | Pending first; approve and deny on the first, revoke on the second, no action on the third |
| support-panes-002 | pane-actions | Approve pressed on `side="account"` | A `POST` of `/v1/account/support/grants/{id}/approve` |
| support-panes-003 | pane-log | Three reads of notes on one day | One sentence naming the table and "3 times" |
| support-panes-004 | pane-hidden-when-off | The grants read answered 404 | The pane renders nothing |
| support-panes-005 | request-form | A reason of nine characters; a length of eight days | No request is sent; each field shows its message |
| support-panes-006 | step-up-redirect | The request refused as `step_up_required` | `stepUp('/support')` is called and no error is shown |
| support-panes-007 | viewer-read-only | A live grant opened to a table | The rows are shown and no edit, create or delete control exists |
| support-panes-008 | operator-grants | A revoked break-glass grant | The row is red |
| support-panes-009 | break-glass-form | An attestation of 39 characters | No request is sent |
| support-panes-010 | product-admin-topic, route-share | The topic list and the route share | A `support` entry with `/support`; the `/support` line in each share |
| support-panes-011 | settings-tab | The hub settings registry | A `support-access` topic with its endpoint, hidden on a 404 |

