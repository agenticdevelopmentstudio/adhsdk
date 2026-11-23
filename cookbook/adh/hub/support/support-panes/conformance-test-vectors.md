
Vectors are asserted in `src/__tests__/SupportAccessPane.test.tsx` and `SupportGrantsPane.test.tsx` under `features/support-access`, and in `breakGlassPane.test.tsx`, `supportAccessLogPane.test.tsx` and `supportGrantsAdminPane.test.tsx` under `features/adh-admin/src/__tests__/`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| support-panes-001 | pane-grants | One pending, one live and one ended grant | Pending first; approve and deny on the first, revoke on the second, no action on the third |
| support-panes-002 | pane-actions | Approve pressed on `side="account"` | The decision is called with the grant's id and `approve`; the client POSTs `/v1/account/support/grants/{id}/approve` |
| support-panes-003 | pane-log | Three reads of notes on one day | One sentence naming the table and "3 times" ("Ben from Support viewed your notes, 3 times today") |
| support-panes-004 | pane-hidden-when-off | The grants read answered 404 | The pane renders nothing |
| support-panes-005 | request-form | A reason of nine characters; a length of 192 hours (eight days) | No request is sent; the form shows the message |
| support-panes-006 | step-up-redirect | The request refused as `step_up_required` | `stepUp('/support')` is called and no error is shown (also when read from the refusal's body; `onStepUp` overrides it) |
| support-panes-007 | viewer-read-only | A live grant opened to a table | The rows are shown and no edit, create or delete control exists (only Open, Previous and Next) |
| support-panes-008 | operator-grants | A revoked break-glass grant | The row is red |
| support-panes-009 | break-glass-form | An attestation of 39 characters | No request is sent |
| support-panes-010 | product-admin-topic, route-share | The topic list and the route share | A `support` entry with `/support`; the `/support` line in each share |
| support-panes-011 | settings-tab | The hub settings registry | A `support-access` topic with its endpoint `/v1/account/support/grants`, hidden on a 404 |
| support-panes-012 | grant-list | A product with one live and one ended grant | Both listed with their states, live first; open and revoke only on the live one |
| support-panes-013 | viewer-open | A live grant opened | The tables of `SUPPORT_CONTENT_TABLES` are offered; one table pages its rows (Next, Previous) and one row opens |
| support-panes-014 | log-pane, pane-ids | The log pane with a grant id applied, and with none; the registries | Only that grant's reads, newest first, and nothing read before an id is applied; the three ids present in `adminPanes.ts` and `adminTopics.ts` and exported |
| support-panes-015 | break-glass-form | The form open | It says a second factor is required, and refuses a missing reference |
