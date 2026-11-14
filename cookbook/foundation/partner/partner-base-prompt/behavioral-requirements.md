
**Input types it reads**

- **job-fields**: The prompt builder MUST read from a `PartnerJob` its `id`, `name`, `isEnabled`, `guidelines` and `steps`; a `PartnerJob` also carries `scheduleSeconds` (optional Int) and `isBuiltIn`, which the builder ignores.
- **step-fields**: The prompt builder MUST read from a `PartnerJobStep` its `name`, `environment` (`terminal` or `claude`), `command` and `condition`.

**Base text**

- **base-text-constant**: `PartnerBasePrompt.text` MUST be a fixed string constant, identical on every read and independent of any job.
- **base-title**: The base text MUST open with the heading `# Coding Partner` and describe the partner as one long-lived Claude Code session that does several jobs with one memory.
- **base-sections**: The base text MUST contain, in order, the second-level headings `The window`, `What reaches you`, `Tools`, `Attention items`, `Sessions`, `Running a job's steps` and `Git`.
- **base-message-kinds**: The base text MUST list the message kinds that reach the partner: an owner message, a button message, an owner reply that carries an item id, a tick, a session went idle, a session exited and a lifecycle notice.
- **base-button-messages**: The base text MUST tell the partner that a button message reading `Resolved: <text>` or `Confirmed: <text>` means the owner handled the item, and that it closes the item with `partner_attention_update`.
- **base-item-reply**: The base text MUST tell the partner to act on an owner reply that carries an item id, then close the item with `partner_attention_update`.
- **base-no-polling**: The base text MUST tell the partner that it runs only when a message arrives and MUST NOT loop, sleep or poll to wait.
- **base-tool-table**: The base text MUST list every partner tool in a table: `partner_projects_list`, `partner_session_open`, `partner_session_list`, `partner_session_screen`, `partner_session_run`, `partner_session_wait`, `partner_session_interrupt`, `partner_session_close`, `partner_attention_create`, `partner_attention_update`, `partner_attention_list`, `partner_notify`, `partner_review_next`, `partner_review_start` and `partner_review_finish`.
- **base-attention-rules**: The base text MUST tell the partner to raise an attention item with `partner_attention_create` when it needs the owner, never to wait for an answer, to use one of the kinds question, blocked or notification, and to update an open item rather than create a duplicate.
- **base-sessions-rules**: The base text MUST tell the partner not to block on `partner_session_wait` for long work, to read a session's screen before deciding after an idle or exit message, and to close sessions it no longer needs.
- **base-steps-rules**: The base text MUST tell the partner to run a job's steps in order, never to skip or reorder them, and to judge each step's condition from the session's screen before typing its command.
- **base-git-rules**: The base text MUST limit git to reading (log, show, diff and status), MUST forbid passing `--output` to a git command, and MUST forbid changing the owner's branches, commits or working trees.
- **base-line-continuations**: Each paragraph of the base text MUST be a single logical line: the source wraps paragraphs with trailing backslash continuations, so the wrapping is not part of the text.

**System prompt**

- **system-prompt-prefix**: `systemPrompt(jobs:)` MUST begin with `text` exactly.
- **system-prompt-enabled-only**: `systemPrompt(jobs:)` MUST add a section for a job only when its `isEnabled` is true and MUST add nothing for a disabled job.
- **system-prompt-job-order**: `systemPrompt(jobs:)` MUST add the enabled jobs' sections in the order of the input array.
- **system-prompt-job-section**: Each enabled job's section MUST be a blank line, the heading `## Job: <name>`, a blank line and the job's `guidelines` verbatim, followed by the steps section.
- **system-prompt-no-jobs**: `systemPrompt(jobs:)` MUST return exactly `text` when no job is enabled, including for an empty array.
- **system-prompt-pure**: `systemPrompt(jobs:)` MUST be a pure function of its input; calling it twice with the same jobs MUST give the same string.

**Steps section**

- **steps-empty**: The steps section MUST be the empty string when the job has no steps.
- **steps-heading**: A job with steps MUST have its steps section begin with a blank line and the heading `### Steps` followed by a blank line.
- **steps-code-review-note**: A job whose `id` equals `PartnerJobDefaults.codeReviewsID` (`"code-reviews"`) MUST have the sentence "These steps arrive filled in from `partner_review_start`; run the filled copy it returns." placed after the heading, and no other job MUST have it.
- **steps-line-format**: Each step MUST be one numbered line, counted from 1, in the form `<n>. <name> (<place>): <command in backticks>`.
- **steps-place-label**: The `<place>` MUST be `Claude Code prompt` when the step's environment is `claude` and `terminal shell` otherwise.
- **steps-condition**: When a step's condition, trimmed of leading and trailing whitespace and newlines, is not empty, the step line MUST end with `, when <trimmed condition>`; otherwise the line MUST end after the command.
- **steps-no-trailing-newline**: The steps section MUST NOT end with a newline; the final line feed is removed.
- **steps-order-preserved**: The steps MUST be listed in the order of the job's `steps` array.
- **steps-no-escaping**: A step's name, command and condition MUST be inserted as written, without escaping.

**Skill file**

- **skill-frontmatter**: `skillMarkdown(for:)` MUST return a YAML frontmatter block opened and closed by `---` lines, a blank line, the job's `guidelines` verbatim and a final newline.
- **skill-name**: The frontmatter `name` MUST be `adkitchen-partner-<job.id>`, with the id inserted as written.
- **skill-description**: The frontmatter `description` MUST be a double-quoted string reading "The Agentic Developer Kitchen Coding Partner's guidelines for its <name> job. Only for the Coding Partner, which has the partner_* tools; not for ordinary requests."
- **skill-name-quoting**: The job name inside the description MUST have each backslash written as two backslashes, each double quote written as a backslash and a quote, and each newline written as a backslash followed by `n`, in that order, so the name cannot break the quoted YAML string.
- **skill-enabled-ignored**: `skillMarkdown(for:)` MUST produce the same output whether or not the job is enabled.

