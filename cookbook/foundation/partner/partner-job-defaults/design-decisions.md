
**Decision**: The built-in code-reviews job ships disabled with a 1800-second timer.
**Rationale**: The job starts Claude sessions with permission prompts off in the owner's repositories, so it must be an explicit opt-in; the 30-minute interval bounds how often the app crawls and the partner starts reviews.
**Approved**: pending

**Decision**: The terminal step opens Claude with `--dangerously-skip-permissions`.
**Rationale**: A review session is driven unattended by the partner, which would otherwise stall on every permission prompt. The risk is contained by the fix step, which commits only on the fix branch and never pushes. This is a deliberate trust trade and an owner can edit the step.
**Approved**: pending

**Decision**: The guidelines tell the partner to retry `/code-review` with the range `{sha}^..{sha}` when the bare sha is rejected.
**Rationale**: This is a workaround recorded in the source: the review command's target rules reject a bare sha in some cases, and the range form is accepted, so the partner is told the fallback instead of failing the review.
**Approved**: pending

**Decision**: The retired general job's id is kept as a constant while `all` lists only the code-reviews job.
**Rationale**: Installs made before the general job was retired still hold its row, file and skill; the installer needs the id to remove them. The doc comment on the constant says it is kept only for that.
**Approved**: pending

**Decision**: The fix step skips findings that later commits already changed or removed and requires the report to say which.
**Rationale**: A review runs against one commit but fixes land at the tip of the branch, so a finding may already be obsolete; saying which were skipped keeps the owner able to audit the result.
**Approved**: pending

**Decision**: The test named `defaultsHaveTheTwoBuiltInJobs` asserts one job.
**Rationale**: The test name is stale from before the general job was retired; its assertion (one id, `code-reviews`) is the current contract, and this recipe follows the assertion.
**Approved**: pending

