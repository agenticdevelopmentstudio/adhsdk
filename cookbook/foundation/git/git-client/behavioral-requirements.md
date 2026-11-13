
### The bottleneck and its verbs

- **single-spawn-point**: The git client MUST be the only path by which the
  toolkit spawns a git process; every public verb routes through one
  private execution step, which is the sole place a git process is spawned
  in this component.
- **concurrent-calls-not-serialized**: The git client's verbs MUST each
  suspend for the whole lifetime of the child process without blocking
  other callers, so concurrent callers run concurrent git processes rather
  than being serialized behind one another — the bottleneck is for
  accounting, not for execution order.
- **status-command-construction**: The status verb MUST invoke `git status`
  with arguments `["--porcelain=v1", "-z", "-uall"]`, and MUST append
  `"--ignore-submodules"` when the submodule-handling configuration is set
  to ignore.
- **current-branch-detached-head**: The current-branch verb MUST invoke
  `git rev-parse --abbrev-ref HEAD` and MUST return nothing when the
  trimmed output is empty or equal to the literal string `"HEAD"`.
- **branches-format-string**: The branches verb MUST invoke `git
  for-each-ref` against `refs/heads` with a `--format=<value>` argument,
  where the value is exactly `%(refname:short)%09%(HEAD)%09%(upstream:short)`.
- **worktrees-listing**: The worktrees verb MUST invoke `git worktree list
  --porcelain` and MUST return every worktree of the repository containing
  the given directory, main worktree first.
- **global-config-directory**: The three global-configuration verbs (read,
  set, unset) MUST run with the current user's home directory as the child
  process's working directory, never a repository directory, because `git
  config --global` neither discovers nor reads a repository.
- **global-config-list**: The read-global-config verb MUST invoke `git
  config --global --list --null` and MUST parse the result using the
  config-entry parsing rule below.
- **set-global-config**: The set-global-config verb MUST invoke `git
  config --global <key> <value>` and MUST discard the process's captured
  output.
- **unset-global-config-exit-5**: The unset-global-config verb MUST invoke
  `git config --global --unset <key>` and MUST surface git's exit status 5
  (key was not set) as an ordinary command-failed outcome, not as a
  distinct outcome.

### Execution, configuration and attribution

- **executable-preflight**: The execution step MUST check that the
  configured executable path is actually executable before spawning, and
  MUST throw an executable-not-found outcome (carrying the path) without
  spawning a process when that check fails.
- **environment-terminal-prompt-disabled**: The execution step MUST set
  `GIT_TERMINAL_PROMPT=0` in the spawned child's environment (so a
  credential prompt cannot hang the child behind an unwatched terminal) and
  MUST merge a caller-supplied extra-environment configuration over that
  default, with the caller-supplied values winning on key collision.
- **total-failure-mapping**: The execution step MUST map every error the
  underlying process-launch mechanism throws onto exactly one of a
  timed-out outcome (for exceeding the configured wall-clock budget) or a
  launch-failed outcome (for every other error) — no error type outside
  the git client's own error outcome can leave the execution step, except
  the one deliberate exception below.
- **cancellation-error-passthrough**: The execution step MUST record the
  attempt and then propagate a cancellation signal unchanged rather than
  wrapping it in the git client's own error outcome, so cooperative
  cancellation and any cleanup tied to it keep working for the caller;
  this is the one way a verb can throw something that is not the git
  client's own error outcome.
- **non-zero-exit-mapping**: The execution step MUST throw a
  command-failed outcome, carrying the verb, exit status, and
  standard-error text, when the child's exit status is non-zero, carrying
  the raw standard-error capture for the caller to show.
- **output-decode-fallback**: The execution step MUST decode the child's
  captured standard output as UTF-8 first, MUST fall back to ISO Latin-1
  when UTF-8 decoding fails, and MUST return an empty string when both
  fail.
- **invocation-recorded-before-return**: The execution step MUST record the
  attempt in the command log on every exit path — executable-not-found,
  timed-out, cancelled, launch-failed, and completed (successfully or
  not) — before returning a value or throwing.
- **caller-capture-at-call-site**: The caller-attribution value's file and
  function fields MUST be captured from the calling context at the point a
  verb is invoked, not from inside the git client itself, so a verb records
  who invoked it with no extra effort from the caller.
- **config-default**: The default configuration MUST set the executable
  path to `/usr/bin/git`, the timeout to `5` seconds, and submodule
  handling to ignore.
- **config-from-settings-timeout-clamp**: Deriving configuration from
  persisted settings MUST read the git executable path, the status
  timeout, and the status-includes-submodules settings, and MUST clamp the
  timeout setting's value to a minimum of `1`. This clamp applies only
  when deriving configuration from settings; constructing a configuration
  directly accepts any timeout value, including zero or a negative value,
  with no clamp of its own.
- **config-provider-resolved-per-call**: The git client MUST resolve its
  configuration afresh on every verb call rather than capturing it once at
  construction, so a shared client instance follows a settings change on
  the very next invocation.
- **value-types-thread-safe**: Every value type this component returns — a
  branch entry, the caller-attribution value, the client configuration, a
  config entry, a file status, the status result, and a worktree entry —
  MUST be safe to share across concurrent callers with no additional
  synchronization, so every value that crosses the client's asynchronous
  boundary is safe to use from any calling context.

### Errors and security-relevant logging

- **error-taxonomy**: The git client's error outcome MUST be exactly four
  cases — command-failed, timed-out, launch-failed, executable-not-found —
  and MUST NOT include a cancellation signal as one of its cases.
- **error-description-vs-log-description**: The error outcome's
  user-facing description MAY interpolate git's own standard-error text
  into a message for the command-failed case. The error outcome's
  log-facing description MUST NOT include the standard-error text, the
  launch failure's reason, or the configured executable path in any case,
  returning only the case name plus non-sensitive structured fields (verb,
  exit status).
- **command-log-fields**: The command log MUST record the verb, its
  redacted arguments, the working directory, the calling file and
  function, the duration in milliseconds, and the exit status (or the
  literal string `"unfinished"` when no exit status is available), and
  MUST NOT log the process's standard output or standard error.
- **redaction-scope-and-positional-rule**: The command log's argument
  redaction MUST return arguments unchanged for every verb except config.
  For config, it MUST redact every argument at and after the first
  non-flag (non-`-`-prefixed) argument position — replacing each with
  `<redacted:<byte length>>` — regardless of whether that argument is
  shaped like a well-formed key; the config-entry key validator (below) is
  used only to decide whether to *keep* the argument found at that
  position, never to relocate the position itself.
- **config-entry-key-validator**: The config-entry key validator MUST
  return true only for a non-empty string that contains at least one `.`,
  does not begin with `-`, and contains no whitespace character.
- **config-entry-parse-split-rule**: Parsing a NUL-separated config listing
  MUST split records on NUL, and within each record MUST split the key
  from the value at the *first* newline only, yielding an empty value for
  a record with no newline at all.

### Parsing (file status, status, worktree, branch)

- **file-status-priority-merge**: Merging file statuses MUST return the
  status with the highest priority among the input — conflicted (7) down
  to ignored (0) — or nothing for empty input.
- **status-porcelain-record-shape**: Parsing status MUST split the
  `-z`-terminated porcelain output on NUL, MUST treat each record's first
  two bytes as the index and work-tree status columns, and MUST consume a
  second NUL-terminated field as the origin path whenever either status
  column is `R` or `C`, ahead of every other classification.
- **status-conflict-pair-detection**: Parsing status MUST classify a
  record as conflicted when its two-character status pair is exactly one
  of `DD`, `AU`, `UD`, `UA`, `DU`, `AA`, `UU`, ahead of the
  modified/added/deleted ladder.
- **status-byte-accurate-path-decode**: Parsing status MUST slice and
  count each record in UTF-8 bytes rather than by character, and MUST drop
  a record whose remaining bytes fail to decode as UTF-8 or decode to an
  empty string, costing only that one record.
- **status-directory-rollup**: Parsing status MUST derive directory
  statuses by assigning, to every ancestor path component of every file
  entry, the highest-priority file status among that ancestor's
  descendants.
- **worktree-parse-flush-on-new-record**: Parsing worktrees MUST flush the
  in-progress record whenever a new line beginning with `"worktree "`
  starts, not only on a blank line, and MUST flush once more after the
  input ends to capture a record with no trailing blank line.
- **worktree-branch-shortening**: Parsing worktrees MUST shorten a branch
  line's `refs/heads/<name>` value to `<name>`, and MUST leave a branch
  ref not beginning with `refs/heads/` unshortened.
- **worktree-main-is-first**: Parsing worktrees MUST mark the first flushed
  record as the main worktree and every subsequent record as not the main
  worktree, per the listing's own contract that the main worktree is
  always listed first.
- **branch-parse-tab-separated**: Parsing branches MUST split each line on
  tab, treat a second field of `"*"` as the current branch, and treat a
  third field that is empty as no upstream — the third field for a real
  listing is a single space, not an empty string, for every non-current
  branch.

### History model

The history model is the set of value types a read-only history browser
needs — commits, refs, stashes, submodules and a log request — each with
the exact format string it is parsed from. Every one is a plain value,
safe to share across concurrent callers, and every parser drops a record it
cannot read rather than failing the whole listing.

- **history-person**: A person value MUST carry a name, an email and a
  date; a commit MUST carry one for its author and one for its committer.
- **commit-log-format**: The commit parser MUST expect records produced by
  the format
  `%H%x1f%P%x1f%an%x1f%ae%x1f%at%x1f%cn%x1f%ce%x1f%ct%x1f%s%x1f%b%x1e` —
  ten fields separated by the unit separator (0x1F), each record terminated
  by the record separator (0x1E).
- **commit-record-split**: Parsing a log MUST split records on the record
  separator and MUST strip the newline git writes between records (the
  format is a terminator, so every record after the first begins with one);
  a record that is empty after that is skipped.
- **commit-field-split**: Within a record the parser MUST read the first
  eight fields (full sha, parents, author name, author email, author epoch,
  committer name, committer email, committer epoch) from the front, and
  MUST split what remains at its *last* unit separator into subject and
  body, so a unit separator inside a subject survives; a unit separator
  inside a body is the one input this cannot recover.
- **commit-parents-all**: A commit's parents MUST be every space-separated
  sha in the `%P` field, in order — three for an octopus merge — and an
  empty list for a root commit.
- **commit-body-trim**: A commit's body MUST keep its interior newlines and
  MUST have its trailing newlines removed.
- **commit-dates-epoch**: Author and committer dates MUST be read as
  seconds since the Unix epoch; a record whose sha is empty, whose field
  count is short, or whose epoch is not an integer MUST be dropped.
- **commit-short-id**: A commit's short id MUST be the first eight
  characters of its full sha.
- **ref-format**: The ref parser MUST expect `for-each-ref` lines produced
  by the format
  `%(refname)%1f%(refname:short)%1f%(objectname)%1f%(*objectname)%1f%(upstream:short)%1f%(upstream:track,nobracket)%1f%(HEAD)`,
  one ref per line, fields separated by the unit separator.
- **ref-kind-from-full-name**: A ref's kind MUST come from its full name:
  `refs/heads/` is a local branch, `refs/remotes/` a remote branch,
  `refs/tags/` a tag. Every other ref (`refs/stash`, notes, anything else)
  MUST be dropped, and so MUST a remote's `HEAD` symbolic ref
  (`refs/remotes/<remote>/HEAD`).
- **ref-name-from-full-name**: A ref's display name MUST be its full name
  with the kind's prefix removed (`origin/main` for a remote branch), not
  `%(refname:short)`, which prints `heads/<name>` when a branch shares its
  name with a tag.
- **ref-target-peeled**: A ref's target MUST be the peeled object
  (`%(*objectname)`) when that field is non-empty — an annotated tag — and
  the ref's own object (`%(objectname)`) otherwise.
- **ref-tracking**: A ref's ahead and behind counts MUST be read from the
  track field's `ahead N` and `behind N` parts, each defaulting to 0; a
  track of `gone` MUST yield 0 and 0 while the upstream is kept.
- **ref-head-and-remote**: A ref MUST be the checked-out one exactly when
  its `%(HEAD)` field is `*`; a remote branch's remote MUST be the first
  path component after `refs/remotes/`, and every other kind has none.
- **stash-list-format**: The stash parser MUST expect `stash list -z`
  output in the format `%gd%x1f%H%x1f%ct%x1f%gs`: NUL-separated records of
  selector, sha, epoch and message, the stash's index read from the digits
  between the selector's braces (`stash@{0}` is 0).
- **submodule-status-states**: The submodule parser MUST read `submodule
  status` lines whose first character gives the state — space for current,
  `+` for modified (checked out at a commit other than the recorded one),
  `-` for uninitialized, `U` for conflicted — followed by the sha, a space
  and the path, with a trailing ` (<describe>)` removed; the path may
  contain spaces.
- **log-query-arguments**: A log request MUST produce the arguments that
  follow `log`: `--date-order`, `--format=` with the commit log format,
  `--max-count=<limit>` (default 500), `--skip=<skip>` (default 0), then
  `--author=<value>`, `--grep=<value>` with `--regexp-ignore-case`, and
  `-S<text>` for whichever of author, message search and pickaxe are set,
  then the revisions (default `--branches --tags --remotes HEAD`), then
  `--` and the path when a path is set. It MUST NOT pass `-z`.
- **log-query-follow**: A log request that follows renames MUST end with
  `--follow -- <path>` and MUST omit its revisions, because `git log
  --follow` takes exactly one path and walks from `HEAD`.
- **history-output-decoding**: Captured history output MUST be decoded with
  the same ladder as the execution step — UTF-8, then ISO Latin-1 — and
  never yield nothing.

