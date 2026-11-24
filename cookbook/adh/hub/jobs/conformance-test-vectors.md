
These vectors come from the phase 9 design and are the tests the package's `__tests__/` and the data
client's `jobs/__tests__/` MUST carry. The data client and its tests are written; the package is not yet.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| jobs-001 | jobs-topics, topic-ids-unique | `jobsTopics` | Three entries in order: Jobs `jobs`, Templates `jobs/templates`, Environments `jobs/environments`; the ids are unique. |
| jobs-002 | jobs-product-admin-topics, topic-ids-unique | `jobsProductAdminTopics` | Two entries in order: Status `/jobs`, Templates `/jobs/templates`; the ids are unique. |
| jobs-003 | topics-subpath-plain-data | Import `@adh-sdk/jobs/topics` in a module with no React | Both topic sets load; the module imports nothing from React. |
| jobs-004 | jobs-customer-catalog-only | Render `JobsPane side="customer"` with a catalog of one template | Creation is offered from the catalog entry only; no inline-steps or template authoring action is shown. |
| jobs-005 | jobs-side-prop, jobs-catalog | Render `JobsPane side="account"` with a catalog of one template; create a job from it | The create call names that template's latest version. |
| jobs-006 | run-model-unavailable | A run whose failed step has `error_code` `model_unavailable` and a provider message | The step reads "The model was switched off"; the provider message is not the step's headline. |
| jobs-007 | run-retry, run-cancel | A `failed` run; a `running` run | The failed run offers Retry and not Cancel; the running run offers Cancel and not Retry. |
| jobs-008 | run-live | A `running` run whose stream sends a step's success, then the run's success | The step's status changes, then the stream is closed. |
| jobs-009 | status-no-content | Render `JobStatusPane` | The only read is the status route; no run read, and no inputs, outputs or logs, are requested or shown. |
| jobs-010 | mappers-own-the-wire | Map a wire run with `errorCode`, `createdAt` and step runs | The domain run carries `errorCode`, `createdAt` and camelCase step runs. |
| jobs-011 | once-shown-secrets, inbound-secret-once | Create an inbound trigger whose result carries a secret; close the reveal without copying | The secret is shown once; closing asks for confirmation; a later trigger read carries no secret. |
| jobs-012 | job-environment-choice | Save a job with an environment while the backend answers 422 `step_needs_hub` for step `summarize` | The refusal names the step `summarize` and says it needs the hub. |
| jobs-013 | jobs-reserved-handle-word | `reservedWorkspaceSlugs()` from `@adh-sdk/adh` | Contains `jobs` |

