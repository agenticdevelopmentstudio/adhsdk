
The source has no test that targets these two types directly; vectors 001 and 002 are asserted indirectly in `PartnerModelsTests` and `PartnerJobsEditorModelTests`, and the rest are derived from the type declarations.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-job-001 | job-fields, step-fields, job-steps-ordered | Build the default code-reviews job and read its steps (`defaultsHaveTheTwoBuiltInJobs` in `PartnerModelsTests`) | The step names are, in order, `open session`, `review`, `fix` |
| partner-job-002 | value-types | Compare a stored default job's steps to the freshly built default (`testResetToDefaultRestoresStepsAndDeletesGuidelinesFile` in `PartnerJobsEditorModelTests`) | The step arrays are equal, and there are 3 steps |
| partner-job-003 | job-initializer-defaults | `PartnerJob(id: "x", name: "X", isEnabled: true, guidelines: "g", steps: [])` | `scheduleSeconds` is nil and `isBuiltIn` is false |
| partner-job-004 | step-environment-set, codable-keys | Encode a step with environment `claude` | JSON object whose `environment` value is the string `claude`, with keys `name`, `environment`, `command`, `condition` |
| partner-job-005 | decode-requires-fields | Decode a step whose `environment` is `shell` | Decoding throws |
| partner-job-006 | decode-optional-schedule | Decode a job JSON that omits `scheduleSeconds` but has every other key | Decodes with `scheduleSeconds` nil |
| partner-job-007 | decode-requires-fields | Decode a job JSON that omits `isBuiltIn` | Decoding throws |
| partner-job-008 | codable-keys, value-types | Encode a job with two steps and decode the result | The decoded value equals the original |
| partner-job-009 | value-types, job-identity | Two jobs with the same id and every field equal except `guidelines` | Not equal; both report the same `id` |
| partner-job-010 | job-steps-ordered | Build a job with steps `b` then `a` and encode then decode | Decoded steps are still `b` then `a` |
| partner-job-011 | job-steps-may-be-empty, step-condition-free-text | Job with no steps; a step whose condition is `""` | Both construct and round-trip through JSON |
| partner-job-012 | no-validation | Job with id `""`, name `""` and `scheduleSeconds: -5` | Constructs without error and compares equal to an identical copy |
| partner-job-013 | job-schedule-consumers | Enabled job with `scheduleSeconds` of nil, 0 and -5 (consumer rule; see `PartnerController`) | No timer is armed for any of the three |
| partner-job-014 | job-schedule-consumers | Enabled job with `scheduleSeconds` of 1800 | A timer is armed with a 1800-second interval |
| partner-job-015 | no-side-effects | Encode the same job from two threads at once | Both succeed with identical output |

