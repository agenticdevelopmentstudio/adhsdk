
Vectors 001 to 004 are asserted in `PartnerModelsTests` (001), `CodeReviewsSchedulerTests` (002, 003) and `PartnerJobsEditorModelTests` (004); the rest are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| partner-job-defaults-001 | all-contents, job-steps | `PartnerJobDefaults.all.map(\.id)` and `codeReviews().steps.map(\.name)` (`defaultsHaveTheTwoBuiltInJobs`) | Ids are exactly `code-reviews`; step names are `open session`, `review`, `fix` |
| partner-job-defaults-002 | step-fix-commit, step-fix-no-push | Read `codeReviews().steps[2].command` (`testTheFixStepCommitsOnTheFixBranchAndNeverPushes`) | Contains `Commit on {fix_branch}`, `Do not push` and `"Reviewed-Commit: {sha}"` |
| partner-job-defaults-003 | guidelines-tool-names, guidelines-range-fallback, guidelines-wait-limit | Read `codeReviews().guidelines` (`testTheGuidelinesNameTheLoopAndTheRangeFallback`) | Contains `partner_review_next`, `partner_review_start`, `partner_review_finish`, `partner_session_run`, `partner_session_wait` and `{sha}^..{sha}` |
| partner-job-defaults-004 | job-guidelines, job-steps, defaults-reproducible | Edit a stored default job, reset it, compare to `codeReviews()` (`testResetToDefaultRestoresStepsAndDeletesGuidelinesFile`) | Reset steps equal the default steps (3 steps); reset guidelines equal the default guidelines |
| partner-job-defaults-005 | code-reviews-id, retired-general-id | Read `codeReviewsID` and `retiredGeneralID` | `code-reviews` and `general` |
| partner-job-defaults-006 | all-contents, retired-general-id | `all.contains { $0.id == "general" }` | false |
| partner-job-defaults-007 | job-identity, job-disabled-by-default, job-schedule, job-built-in | Read the fields of `codeReviews()` | Id `code-reviews`, name `Code reviews`, `isEnabled` false, `scheduleSeconds` 1800, `isBuiltIn` true |
| partner-job-defaults-008 | step-open-session | Read steps[0] | Environment `terminal`, command `claude --model {model} --dangerously-skip-permissions`, condition `A fresh tab in the review worktree.` |
| partner-job-defaults-009 | step-review | Read steps[1] | Environment `claude`, command `/code-review high {sha}`, condition `Claude Code is at its prompt; no review already running in this repo.` |
| partner-job-defaults-010 | step-fix-name, step-fix-skips-superseded, step-fix-report | Read steps[2] | Environment `claude`, condition `The review has finished.`; command contains `{superseded}` and `Report what was fixed and what was skipped.` |
| partner-job-defaults-011 | step-placeholders | Collect every brace-wrapped word across the three commands | The set is `model`, `sha`, `fix_branch`, `superseded` |
| partner-job-defaults-012 | job-guidelines | Compare `codeReviews().guidelines` with `codeReviewsGuidelines` | Equal |
| partner-job-defaults-013 | all-fresh-values, defaults-reproducible | Mutate the `isEnabled` of one `codeReviews()` result, then call it again | The second call has `isEnabled` false; two untouched calls are equal |
| partner-job-defaults-014 | guidelines-tick, guidelines-one-per-repo, guidelines-skipped-start | Read the guidelines | Contains `while \`running\` is below \`concurrency\``, `Never start two reviews in one repo` and `skipped (no session, no steps)` |
| partner-job-defaults-015 | guidelines-idle-event, guidelines-exit-event, guidelines-no-push | Read the guidelines | Contains "partner_review_finish" followed by "with `done`", the sentence beginning "On a session exited event for a review session that is not finished", and "Nothing is pushed" |
| partner-job-defaults-016 | guidelines-exact | Compare `codeReviewsGuidelines` with the exact guidelines text | Equal |
| partner-job-defaults-017 | step-fix-command-exact | Compare `codeReviews().steps[2].command` with the exact fix command | Equal |

