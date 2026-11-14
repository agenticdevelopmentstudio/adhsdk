
Identifiers

- **code-reviews-id**: `codeReviewsID` MUST be the string `code-reviews`.
- **retired-general-id**: `retiredGeneralID` MUST be the string `general`; it MUST NOT name a job in `all`, and exists only so `PartnerGuidelinesInstaller` can remove the retired job's store row, job file and skill.

The built-in list

- **all-contents**: `all` MUST contain exactly one job, the code-reviews job, and MUST NOT contain the retired general job.
- **all-fresh-values**: `all` and `codeReviews()` MUST build a new value on each call, so a caller that mutates the result does not change the defaults.
- **defaults-reproducible**: Two calls to `codeReviews()` MUST return equal values, so a stored job can be compared with, or reset to, its default.

The code-reviews job (`codeReviews()`)

- **job-identity**: The job MUST have id `code-reviews` and name `Code reviews`.
- **job-disabled-by-default**: The job MUST have `isEnabled` false, so a fresh install does nothing until the owner turns it on.
- **job-schedule**: The job MUST have `scheduleSeconds` 1800 (thirty minutes).
- **job-built-in**: The job MUST have `isBuiltIn` true.
- **job-guidelines**: The job's `guidelines` MUST be the text of `codeReviewsGuidelines`.
- **job-steps**: The job MUST have exactly three steps, in this order: `open session`, `review`, `fix`.

The steps

- **step-open-session**: The first step MUST have name `open session`, environment `terminal`, command `claude --model {model} --dangerously-skip-permissions`, and condition `A fresh tab in the review worktree.`
- **step-review**: The second step MUST have name `review`, environment `claude`, command `/code-review high {sha}`, and condition `Claude Code is at its prompt; no review already running in this repo.`
- **step-fix-name**: The third step MUST have name `fix`, environment `claude`, and condition `The review has finished.`
- **step-fix-skips-superseded**: The fix step's command MUST tell Claude to fix every finding that still applies at the tip, and to skip findings whose code the later commits (the `{superseded}` placeholder) already changed or removed, saying which.
- **step-fix-commit**: The fix step's command MUST tell Claude to commit on the `{fix_branch}` placeholder with the trailer `"Reviewed-Commit: {sha}"` (quotes included).
- **step-fix-no-push**: The fix step's command MUST say `Do not push` and that the fixes stay on the fix branch for the owner to merge.
- **step-fix-report**: The fix step's command MUST ask Claude to report what was fixed and what was skipped.
- **step-placeholders**: The commands MUST use these placeholders and no others: `{model}`, `{sha}`, `{fix_branch}` and `{superseded}`; they are filled by `PartnerStepTemplate` when a review is started, not here.
- **step-skip-permissions**: The terminal step MUST pass `--dangerously-skip-permissions` to `claude`, so the review session runs without permission prompts. This is a deliberate trust decision recorded here and in Design Decisions.

The guidelines text (`codeReviewsGuidelines`)

- **guidelines-tick**: The text MUST tell the partner that, on a tick, the message says how many reviews are queued and running, and to call `partner_review_next` and then start reviews with `partner_review_start`, oldest first, while `running` is below `concurrency`.
- **guidelines-one-per-repo**: The text MUST tell the partner never to start two reviews in one repo, and, when a start says the repo's review worktree needs the owner, to leave that review queued and start no other review of that repo and branch in that tick.
- **guidelines-skipped-start**: The text MUST tell the partner that a `partner_review_start` result that is skipped (no session, no steps) needs nothing more, because the app has already marked it.
- **guidelines-run-steps**: The text MUST tell the partner to run the listed steps in order in the named session, using `partner_session_run` for both terminal commands and Claude prompt text (typed at Claude Code's prompt), and to check each step's condition on the screen before typing it.
- **guidelines-range-fallback**: The text MUST tell the partner that, if the review step's `/code-review` rejects the bare sha as its target, it types the command again with the range `{sha}^..{sha}` in the sha's place.
- **guidelines-idle-event**: The text MUST tell the partner, on a session idle event for a review session, to read the screen with `partner_session_screen` and decide among four outcomes: still working (end the turn), step finished (type the next step), last step finished (call `partner_review_finish` with `done` and a one-paragraph summary of the findings fixed, the findings skipped and why), or stuck or waiting on something it cannot answer (raise an attention item).
- **guidelines-answer-prompts**: The text MUST tell the partner to answer what Claude Code asks along the way, the trust-this-folder prompt included.
- **guidelines-exit-event**: The text MUST tell the partner, on a session exited event for a review session that is not finished, to call `partner_review_finish` with `failed` and what the screen last showed.
- **guidelines-wait-limit**: The text MUST tell the partner never to wait on `partner_session_wait` longer than its maximum, but to end the turn and let the idle event wake it.
- **guidelines-no-push**: The text MUST say nothing is pushed and the fixes stay on the fix branch for the owner to merge.
- **guidelines-tool-names**: The text MUST name the tools `partner_review_next`, `partner_review_start`, `partner_review_finish`, `partner_session_run`, `partner_session_screen` and `partner_session_wait`; these names are the partner's tool contract with the app's MCP endpoint.

Concurrency and side effects

- **pure-constants**: Every member MUST be a pure, constant or freshly built value with no I/O, no clock read and no shared mutable state, so it is safe from any thread.

