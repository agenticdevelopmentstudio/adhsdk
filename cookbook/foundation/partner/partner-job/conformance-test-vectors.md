
The source has no test that targets these two types directly; the vectors are derived from the type declarations and use literal values, so they do not depend on any seeded default job.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-job-001 | job-fields, step-fields, job-steps-ordered | `PartnerJob(id: "j", name: "J", isEnabled: true, guidelines: "g", steps: [s1, s2, s3])` with literal steps named `open`, `review`, `fix` | The step names read back, in order, `open`, `review`, `fix`; the job has 3 steps |
| partner-job-002 | value-types | Two jobs built from the same literal values, including the same three literal `PartnerJobStep` values | The jobs are equal, and their step arrays are equal |
| partner-job-003 | job-initializer-defaults | `PartnerJob(id: "x", name: "X", isEnabled: true, guidelines: "g", steps: [])` | `scheduleSeconds` is nil and `isBuiltIn` is false |
| partner-job-004 | step-environment-set, codable-keys | Encode a step with environment `claude` | JSON object whose `environment` value is the string `claude`, with keys `name`, `environment`, `command`, `condition` |
| partner-job-005 | decode-requires-fields | Decode a step whose `environment` is `shell` | Decoding throws |
| partner-job-006 | decode-optional-schedule | Decode a job JSON that omits `scheduleSeconds` but has every other key | Decodes with `scheduleSeconds` nil |
| partner-job-007 | decode-requires-fields | Decode a job JSON that omits `isBuiltIn` | Decoding throws |
| partner-job-008 | codable-keys, value-types | Encode a job with two steps and decode the result | The decoded value equals the original |
| partner-job-009 | value-types, job-identity | Two jobs with the same id and every field equal except `guidelines` | Not equal; both report the same `id` |
| partner-job-010 | job-steps-ordered | Build a job with steps `b` then `a` and encode then decode | Decoded steps are still `b` then `a` |
| partner-job-011 | job-steps-may-be-empty, step-condition-free-text | Job with no steps; a step whose condition is `""` | Both construct and round-trip through JSON |
| partner-job-012 | no-validation, job-schedule-any-integer | Job with id `""`, name `""` and `scheduleSeconds: -5` | Constructs without error, keeps `-5` as given, and compares equal to an identical copy |
| partner-job-013 | no-side-effects | Encode the same job from two threads at once | Both succeed, and both outputs decode to values equal to the job |

