
**Decision**: The built-in code-reviews job ships disabled with a 1800-second timer.
**Rationale**: The job starts Claude sessions with permission prompts off in the owner's repositories, so it must be an explicit opt-in; the 30-minute interval bounds how often the app crawls and the partner starts reviews.
**Approved**: pending

**Decision**: The terminal step opens Claude with `--dangerously-skip-permissions`.
**Rationale**: A review session is driven unattended by the partner, which would otherwise stall on every permission prompt. The "commit only, never push" wording of the fix step is advisory prompt text, not a control: a session with prompts off could still push or write outside its worktree. What limits the damage is that the session starts in its own review worktree and the owner merges the fix branch. The residual risk is accepted, and an owner can edit the step.
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

**Decision**: The unattended review session reads untrusted repository content (commit text, code and files) with permission prompts off, and the risk of prompt injection from it is accepted.
**Rationale**: A review has to read the repository it reviews, and the session is driven without a person at the prompt. The mitigations are the review worktree, the fix branch the owner merges, and the job being disabled until the owner turns it on; nothing in the guidelines or steps screens the content Claude reads.
**Approved**: pending

