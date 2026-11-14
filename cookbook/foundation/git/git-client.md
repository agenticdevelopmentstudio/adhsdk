---
id: 779ac6ea-9ef5-4fb0-8ed9-dc6b9d617344
title: "Git Client"
type: ingredient
version: 1.2.0
status: review
language: en
created: 2026-09-24
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A git subprocess client: status/branch/worktree/global-config verbs through one bottleneck, with total error mapping, redacted logging and a timeout."
platforms:
  - swift
  - macos
tags:
  - git
  - version-control
  - subprocess
  - logging
  - redaction
  - settings
depends-on: []
related: []
references:
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitBranch.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitCaller.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitClient.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitClientConfiguration.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitClientError.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitCommandLog.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitConfigEntry.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitFileStatus.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitStatus.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitWorktree.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitPerson.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitCommit.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitRef.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitStash.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitSubmodule.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitLogQuery.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitOutputDecoding.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitDiff.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitFileDiff.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitDiffHunk.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitDiffLine.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitPatchParser.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitWordDiff.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitBlame.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitPathUnquoting.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitDiffTarget.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/SettingStorage/UserSettings+Git.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitClientTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitClientHistoryTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitTestRepository.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitCommandLogTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitStatusParserTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitBranchParserTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitWorktreeParserTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitConfigEntryParserTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitClientConfigurationTests.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Git Client

## Overview

The git client is the toolkit's single door to git: a component that spawns
every git process the toolkit or an agent driving it will ever run, through
one bottleneck. It exposes four read-only verbs (status, current branch,
branches, worktrees) and three global-configuration verbs (read global
config, set global config, unset global config), resolves its own
configuration from three persisted settings on every call, records every
attempt — success or failure — in a redacted command log, and maps every
failure onto a closed four-case error outcome. It has no visual surface of
its own; every UI element that shows git state (a status badge, a branch
picker) is a consumer of this contract, not part of it.

## Behavioral Requirements

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

### Read verbs (history, refs, diff, blame, contents)

- **accepted-exit-codes**: The private execution step MUST take the set of
  exit statuses that count as success (by default only 0) and MUST surface
  any other status as command-failed; it MUST also take `-c key=value`
  overrides, which go before the verb on the command line and at the front
  of the logged arguments.
- **top-level**: The top-level verb MUST invoke `git rev-parse
  --show-toplevel`, drop only the trailing newline (a top-level path may end
  in whitespace), and return it as a standardized file location.
- **log-command**: The log verb MUST invoke `git log` with exactly the log
  request's arguments and MUST parse the output with the commit parsing rule.
- **log-unborn-head**: When the log verb fails with exit status 128 and HEAD
  does not resolve to a commit, it MUST NOT throw: a follow-mode request
  returns no commits, and any other request is retried without the `HEAD`
  revision when other revisions remain, or returns no commits when none do.
- **file-history-command**: The file history verb MUST invoke `git log` with a
  log request that follows the path and asks for name-status, with
  `core.quotePath=false`, and MUST parse the output with the file history
  rule; on exit status 128 with an unresolvable HEAD it returns no entries.
- **refs-command**: The refs verb MUST invoke `git for-each-ref` with the
  ref format string against `refs/heads`, `refs/remotes` and `refs/tags`,
  and MUST parse the output with the ref parsing rule.
- **stashes-command**: The stashes verb MUST invoke `git stash list -z
  --no-show-signature` with the stash format string and MUST parse the
  output with the stash parsing rule.
- **submodules-command**: The submodules verb MUST invoke `git -c
  core.quotePath=false submodule status`, and MUST return no submodules for
  a repository without `.gitmodules`.
- **diff-flags**: Every diff MUST run as `git -c core.quotePath=false -c
  diff.suppressBlankEmpty=false diff` with `--no-color`, `--no-ext-diff`,
  `--no-textconv`, `--no-relative`, `--src-prefix=a/`, `--dst-prefix=b/`,
  `--find-renames` and `-U<context lines>`, plus `-w` when whitespace is
  ignored, so neither a user's configuration nor an external diff tool can
  reshape the patch the parser reads. It MUST NOT request combined output
  (`--cc`) for any target.
- **diff-paths**: A diff's paths MUST be relative to the working tree's top
  level and MUST follow `--` as `:(top,literal)<path>` pathspecs, so a path
  is never read as a glob, an option or relative to the calling directory.
- **diff-targets**: The unstaged target MUST compare the index with the
  working tree (no revision); the staged target MUST pass `--cached` (git
  itself treats an unborn HEAD as the empty tree); the range target MUST
  pass `--end-of-options <from> <to>`; the commit target MUST pass
  `--end-of-options <first parent> <commit>`, where the first parent is
  `<commit>^1` resolved to a commit — so a merge and a stash diff against
  their first parent — and a root commit uses the empty tree, computed with
  `git hash-object -t tree /dev/null` rather than spelled, so the repository's
  hash algorithm decides it.
- **diff-untracked**: The untracked target MUST run `git diff --no-index --
  /dev/null <path>` in the top level, accepting exit statuses 0 and 1
  (`--no-index` exits 1 when the files differ); an exit status of 1 with no
  output (git could not read the file) MUST surface as command-failed.
- **blame-command**: The blame verb MUST run `git -c core.quotePath=false
  blame --porcelain [<commit>] -- <path>` in the top level, omitting the
  commit to blame the working tree, and MUST parse the output with the
  blame parsing rule. `git blame` does not accept `--end-of-options`, so a
  revision MUST first be resolved to a commit hash (which can never read as
  an option); a revision naming no commit MUST surface as command-failed
  with exit status 128.
- **file-contents**: The file-contents verb MUST return raw bytes, never
  decoded text. With no revision it MUST read the working file at the top
  level joined with the path, returning nothing when it does not exist.
  With a revision it MUST NOT pass the path inside a `<revision>:<path>`
  argument: Foundation hands arguments to git decomposed (NFD) and that
  form matches the index's precomposed names byte for byte, so a
  non-ASCII path would read as absent. For an index stage (`:0`-`:3`) it
  MUST find the entry with `git ls-files --stage -z -- :(literal)<path>`;
  for any other revision it MUST resolve `<revision>^{tree}` with `git
  rev-parse --verify --quiet --end-of-options`, returning nothing when it
  is absent (exit status 1, including on an unborn HEAD), then list `git
  ls-tree -z <tree> -- :(literal)<path>`. It MUST return nothing unless an
  entry names exactly that path (a blob, or the requested stage), so a
  directory or a missing path gives nothing, and otherwise return the
  output of `git cat-file blob <object id>`.

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
  fail. The fallback MUST apply per segment, not to the whole capture: the
  capture is cut at the separator bytes NUL, newline, 0x1E and 0x1F, each
  segment is decoded on its own, and the segments are rejoined with their
  original separators, so one record with a stray non-UTF-8 byte does not
  turn every other record into Latin-1 mojibake.
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
- **status-staged-unstaged-columns**: Parsing status MUST also keep each
  column on its own, in the same pass over the same records: a staged map
  from the index column and an unstaged map from the work-tree column,
  each keyed by the new path. `M` and `T` MUST read as modified, `A` as
  added, `D` as deleted, `R` as renamed and `C` as copied; a space MUST
  leave the path out of that column's map. An unmerged pair MUST appear as
  conflicted in the unstaged map only, `??` as untracked in the unstaged
  map only, and `!!` in neither. A path changed in both columns MUST appear
  in both maps.
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
  follow `log`: `--no-color` and `--no-show-signature` (so a user's
  `color.ui=always` or `log.showSignature=true` cannot write escape codes or
  signature lines into the records), `--date-order`, `--format=` with the commit log format,
  `--max-count=<limit>` (default 500), `--skip=<skip>` (default 0), then
  `--author=<value>`, `--grep=<value>` with `--regexp-ignore-case`, and
  `-S<text>` for whichever of author, message search and pickaxe are set,
  then the revisions (default `--branches --tags --remotes HEAD`), then
  `--` and the path when a path is set. It MUST NOT pass `-z`.
- **log-query-follow**: A log request that follows renames MUST end with
  `--follow -- <path>` and MUST omit its revisions, because `git log
  --follow` takes exactly one path and walks from `HEAD`.
- **log-query-name-status**: A log request that asks for name-status MUST
  add `--name-status` ahead of its path part; one that does not MUST NOT.
- **file-history-parse**: Parsing a name-status follow log MUST read each
  commit's status lines from the text after its record terminator and
  before the next record, and MUST give each commit the file's path at
  that commit, carried from newest to oldest starting at the requested
  path: a rename or copy (`R`/`C` with two paths) has the new path and
  the old path, and hands the old path to older commits; any other status
  names the path; a commit with no status line (a merge) keeps the
  carried path. Quoted paths are unquoted.
- **history-output-decoding**: Captured history output MUST be decoded with
  the same ladder as the execution step — UTF-8, then ISO Latin-1, segment
  by segment (below) — and never yield nothing.

### Diff and blame

The diff and blame model is what a read-only diff viewer and a blame view
need: a parsed unified patch, the changed words inside a changed line, and
a parsed porcelain blame. Each parser takes text that is already decoded,
returns a plain value safe to share across concurrent callers, and skips
input it cannot read rather than failing.

- **diff-file-split**: Parsing a patch MUST start a new file at every line
  beginning with `diff --git `, and MUST read the old and new paths from
  that line, then let the `---`/`+++` lines and the `rename from`/`rename
  to` (or `copy from`/`copy to`) lines override them when present.
- **diff-dev-null**: A `--- /dev/null` side MUST give no old path, and a
  `+++ /dev/null` side no new path; a file's path MUST be its new path, or
  its old path when it has no new path.
- **diff-change-kind**: A file's change MUST be added for `new file mode`
  or an absent old path, deleted for `deleted file mode` or an absent new
  path, renamed with its similarity for `rename from`/`similarity index
  N%`, copied with its similarity for `copy from`, and modified otherwise —
  including a change of mode alone, which has no hunks. git writes a change
  of object type (a file becoming a symlink or a submodule) as a deleted
  section immediately followed by an added section of the same path; those
  two MUST become one type-changed file with that path on both sides, the
  deletion's hunks then the addition's, binary when either half is (the
  text half keeps its hunks — the one case where a binary file has any),
  so the file list holds one entry per path.
- **diff-binary**: A `Binary files … differ` line or a `GIT binary patch`
  line MUST mark the file binary, and a binary file MUST have no hunks.
- **diff-quoted-paths**: A path git writes in C quotes (because it holds a
  tab, newline, quote, backslash or, without `core.quotePath=false`, a
  non-ASCII byte) MUST be unquoted: the escapes `\t`, `\n`, `\r`, `\"`,
  `\\`, `\a`, `\b`, `\f`, `\v` and three-digit octal byte escapes, the
  octal bytes collected and decoded together as UTF-8 (`\303\274` is `ü`).
  The `a/` and `b/` prefixes MUST be removed after unquoting.
- **diff-hunk-header**: A hunk MUST begin at a line of the form `@@ -o[,c]
  +n[,c] @@ section`, a count omitted meaning 1, and MUST keep the text after
  the second `@@` (trimmed) as its section heading.
- **diff-line-numbers**: Within a hunk a context line MUST carry both an
  old and a new line number, a removed line only an old one and an added
  line only a new one, numbered from the hunk's starts; a `\ No newline at
  end of file` line MUST be kept as its own kind with no numbers. A line's
  text MUST exclude its one-character prefix.
- **word-diff-tokens**: The changed words between a removed and an added
  line MUST be found by a longest-common-subsequence over word tokens —
  runs of letters, digits and underscores; runs of whitespace; and every
  other character as a token of its own — and MUST be reported as UTF-16
  ranges into each line, adjacent changed tokens merged into one range;
  identical lines MUST report no ranges.
- **word-diff-pairing**: Within a hunk, each block of consecutive removed
  and added lines MUST pair its i-th removed line with its i-th added line;
  lines beyond the shorter side are left unpaired, and a context line ends
  the block.
- **blame-porcelain**: Parsing `blame --porcelain` MUST read each header
  line `<sha> <original line> <final line>[ <group size>]`, collect the
  commit's `author`, `author-mail` (angle brackets removed), `author-time`,
  `summary` and `previous <sha> <path>` metadata the first time that commit
  appears (a repeated header carries none), skip `boundary` and every other
  metadata line, and take the tab-prefixed line that follows as the line's
  text.
- **blame-runs**: A blame's runs MUST be the maximal sequences of
  consecutive final lines that belong to one commit, in final-line order.

## Appearance

Not applicable — this is a headless git subprocess client, not a visual
component.

## States

Not applicable — this is a headless git subprocess client, not a visual
component.

## Accessibility

Not applicable — this is a headless git subprocess client, not a visual
component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-client-001 | status-porcelain-record-shape | Parse an empty status output. | Returns an empty status result. |
| git-client-002 | status-porcelain-record-shape | Parse status output ` M foo.txt` (NUL-terminated). | `foo.txt` has status modified. |
| git-client-003 | status-porcelain-record-shape, status-directory-rollup | Parse status output `?? untracked/new.txt`. | `untracked/new.txt` is untracked; the `untracked` directory rolls up to untracked. |
| git-client-004 | status-directory-rollup | Parse status output ` M a/b/c.txt`. | Directories `a` and `a/b` both roll up to modified. |
| git-client-005 | status-porcelain-record-shape | Parse status output `R  new.txt` followed by NUL-terminated origin path `old.txt`. | `new.txt` is renamed; `old.txt` has no separate entry. |
| git-client-006 | status-porcelain-record-shape | Parse status output `RM new.txt` followed by origin path `old.txt`. | `new.txt` is renamed; no entry is recorded for the combined `old.txt -> new.txt` label. |
| git-client-007 | status-porcelain-record-shape | Parse status output ` R App/Sources/Foo.swift` (origin `App/Sources/Bar.swift`) followed by ` M README.md`. | `Foo.swift` is renamed, `Bar.swift` has no separate entry, `README.md` is modified, and exactly two entries total are recorded. |
| git-client-008 | status-porcelain-record-shape | Parse status output `C  copy.txt` (origin `original.txt`) followed by ` M kept.txt`. | `copy.txt` is recorded as copied under the new path, `original.txt` has no separate entry, `kept.txt` is modified. |
| git-client-009 | status-conflict-pair-detection | Parse status output `AA a/both-added.txt` and `DD b/both-deleted.txt`. | Both are conflicted; directories `a` and `b` both roll up to conflicted. |
| git-client-010 | status-conflict-pair-detection | Parse status output `A  added.txt` and `D  deleted.txt`. | `added.txt` is added; `deleted.txt` is deleted — the conflict rule does not apply to ordinary add/delete pairs. |
| git-client-011 | status-byte-accurate-path-decode | Parse status output ` M café.txt` (non-ASCII, no shell quoting). | `café.txt` is keyed exactly, byte for byte. |
| git-client-012 | status-byte-accurate-path-decode | Parse status output for a path beginning with a standalone combining accent mark. | The path keeps its leading combining mark rather than being truncated; no empty-path entry is recorded. |
| git-client-013 | status-byte-accurate-path-decode | Parse status output with an empty path record (` M ` followed immediately by NUL) followed by ` M kept.txt`. | `kept.txt` is modified; no entry is recorded for the empty path. |
| git-client-014 | status-directory-rollup | Parse status output for a path consisting only of separators (` M ///`). | No directory rollup entries are produced. |
| git-client-015 | worktree-main-is-first, worktree-branch-shortening | Parse a 4-record worktree listing. | The first record is marked as the main worktree, at the repository's own root path, on branch `main`. |
| git-client-016 | worktree-branch-shortening | The same 4-record listing. | The second record's branch is shortened to `tabs`. |
| git-client-017 | worktree-parse-flush-on-new-record | The same 4-record listing. | The third record is detached with no branch; the fourth record is bare. |
| git-client-018 | worktree-parse-flush-on-new-record | Parse an empty worktree listing. | Returns an empty list. |
| git-client-019 | worktree-parse-flush-on-new-record | Parse a worktree listing with one record and no trailing blank line (`worktree /solo`, `HEAD abc`, `branch refs/heads/solo`). | One entry is recorded, marked main, with branch `solo`. |
| git-client-020 | branch-parse-tab-separated | Parse branch listing `main<TAB>*<TAB>origin/main`, `feature<TAB><TAB>`, `tabs<TAB><TAB>origin/tabs`. | Three branch entries: `main` (current, tracking `origin/main`), `feature` (not current, no upstream), `tabs` (not current, tracking `origin/tabs`). |
| git-client-021 | branch-parse-tab-separated | Parse a branch listing consisting only of blank lines. | Returns an empty list. |
| git-client-022 | branch-parse-tab-separated | Parse branch listing `main<TAB> <TAB>origin/main`, `feature<TAB> <TAB>` (a single-space HEAD field, as a real listing produces for a non-current branch). | `main` is recorded as not current. |
| git-client-023 | config-entry-parse-split-rule | Parse a NUL-separated config listing: `user.name`/`Mike`, `user.email`/`mike@example.com`, and `core.editor`/`vim -f` followed by a literal `extra` with no value. | Three entries are recorded; the `core.editor` entry's value includes the embedded newline verbatim. |
| git-client-024 | config-entry-parse-split-rule | Parse a NUL-separated config listing consisting of the single key `alias.st` with no value. | One entry, `alias.st`, with an empty value. |
| git-client-025 | config-entry-parse-split-rule | Parse an empty NUL-separated config listing. | Returns an empty list. |
| git-client-026 | redaction-scope-and-positional-rule | Redact arguments for verb `status` with args `["status", "--porcelain=v1", "-uall", "--ignore-submodules"]`. | Unchanged. |
| git-client-027 | redaction-scope-and-positional-rule | Redact arguments for verb `config` with args `["--global", "--list", "--null"]` and separately `["--global", "--unset", "user.email"]`. | Both unchanged — nothing follows the key position in either case. |
| git-client-028 | redaction-scope-and-positional-rule | Redact arguments for verb `config` with args `["--global", "user.email", "someone@example.com"]`. | `["--global", "user.email", "<redacted:19>"]`. |
| git-client-029 | redaction-scope-and-positional-rule | Redact arguments for verb `config` with args `["--global", "core.pager", "--dash-leading-value", "trailing"]`. | `["--global", "core.pager", "<redacted:20>", "<redacted:8>"]`. |
| git-client-030 | redaction-scope-and-positional-rule | Redact arguments for verb `config` with args `["--global", "-x.token", "s3cr3t"]`. | `["--global", "-x.token", "<redacted:6>"]` — the dash-leading key never leaks its value. |
| git-client-031 | redaction-scope-and-positional-rule | Redact arguments for verb `config` with args `["--global", "email", "someone@example.com"]`. | `["--global", "<redacted:5>", "<redacted:19>"]` — a non-key-shaped word is redacted too. |
| git-client-032 | redaction-scope-and-positional-rule | Redact an empty argument list for verb `config`. | Returns an empty list. |
| git-client-033 | config-default | Read the default configuration. | Executable path `/usr/bin/git`; timeout `5`; submodule handling set to ignore. |
| git-client-034 | config-from-settings-timeout-clamp | Derive configuration from settings: path `/opt/homebrew/bin/git`, timeout `12`, submodules `true`. | The derived configuration reflects all three exactly. |
| git-client-035 | config-from-settings-timeout-clamp | Derive configuration from settings with a timeout setting of `0`. | The derived timeout is `1`. |
| git-client-036 | config-from-settings-timeout-clamp | Derive configuration from settings with a timeout setting of `-5`. | The derived timeout is `1`. |
| git-client-037 | executable-preflight | Configure the executable path as `/nonexistent/git` and call the current-branch verb. | Throws an executable-not-found outcome naming `/nonexistent/git`, before any process is spawned. |
| git-client-038 | non-zero-exit-mapping | Call the status verb against a nonexistent directory. | Throws a command-failed outcome. |
| git-client-039 | total-failure-mapping | Configure a timeout of `0.001` seconds and call the status verb against a real repository. | Throws a timed-out outcome naming the `status` verb. |
| git-client-040 | global-config-directory, set-global-config | Call set-global-config with key `atkgitclienttest.added`, value `added-value`, against a redirected global-config location. | The redirected file, not the real user-wide config, gains the entry. |
| git-client-041 | unset-global-config-exit-5, global-config-directory | Call unset-global-config on a previously seeded key, then read global config. | The key is gone; the listing is empty; the real user-wide config is untouched. |
| git-client-042 | status-command-construction | Call the status verb against a real one-commit fixture repository with one modified file. | `a.txt` has status modified. |
| git-client-043 | current-branch-detached-head | Call the current-branch verb against a fixture's root checkout and its `feature` worktree. | Returns `"main"` and `"feature"` respectively. |
| git-client-044 | branches-format-string | Call the branches verb against a fixture with `main` and `feature` branches. | Both names are present; `main` is marked current. |
| git-client-045 | worktree-main-is-first | Call the worktrees verb against a fixture's root plus one added worktree. | Two entries; the first is main on branch `main`, the second is on branch `feature`. |
| git-client-046 | error-description-vs-log-description | Produce the log-facing description of a command-failed outcome carrying verb `status`, exit status `128`, and standard-error text `"fatal: ... '/Users/secret/repo'"`. | Excludes `"secret"`; includes `"status"` and `"128"`. |
| git-client-047 | error-description-vs-log-description | Produce the log-facing description of a launch-failed outcome carrying reason `"secret-path-in-the-reason"`. | Excludes `"secret"`. |
| git-client-048 | error-description-vs-log-description | Produce the log-facing description of an executable-not-found outcome carrying path `"/Users/secret/bin/git"`. | Excludes `"secret"`. |
| git-client-049 | status-staged-unstaged-columns | Parse status output `MM both.txt`, `A  new.txt`, ` D gone.txt`, `?? loose.txt`. | Staged: `both.txt` modified, `new.txt` added. Unstaged: `both.txt` modified, `gone.txt` deleted, `loose.txt` untracked. |
| git-client-050 | status-staged-unstaged-columns | Parse status output `UU fight.txt`, `RM new.txt` (origin `old.txt`), `!! ignored.txt`. | Staged: `new.txt` renamed. Unstaged: `fight.txt` conflicted, `new.txt` modified. `ignored.txt` is in neither; `old.txt` is in neither. |
| git-client-051 | file-history-parse | Records `c4` (`M new name.txt`), `c3` (no status), `c2` (`R087 mid.txt new name.txt`), `c1` (`C100 old.txt mid.txt`), `c0` (`A old.txt`), requested `new name.txt` | Paths `new name.txt`, `new name.txt`, `new name.txt`, `mid.txt`, `old.txt`; old paths none, none, `mid.txt`, `old.txt`, none. |
| git-client-052 | file-history-command | A repository where `a b.txt` was renamed to `c d.txt`, then edited; file history of `c d.txt` | Edit at `c d.txt`; rename at `c d.txt` from `a b.txt`; initial at `a b.txt`. |
| git-client-053 | log-query-name-status | A follow request for `a b.txt` with name-status | Ends `--name-status --follow -- a b.txt`. |
| git-client-054 | file-contents | A repository with `dir é/naïve file.swift` committed as `let a = 1`, then `let a = 2`, and `let a = 3` staged | Contents at `second^1`, `second` and `:0` are the three versions; `dir é` at `second` and `dir é/missing` at `:0` are nothing. |
## Edge Cases

- **Null/empty input**: Parsing an empty status output MUST return an
  empty status result (git-client-001). Parsing a branch listing of only
  blank lines MUST return an empty list (git-client-021). Parsing an empty
  NUL-separated config listing MUST return an empty list (git-client-025).
  Parsing an empty worktree listing MUST return an empty list
  (git-client-018). The current-branch verb on a detached HEAD MUST return
  nothing, never the literal string `"HEAD"`.
- **Boundary/malformed values**: A porcelain record with no path at all
  (`" M \0"`) or a path that is only separators (`" M ///\0"`) MUST cost
  only that one record, never trap the parser (git-client-013,
  git-client-014). A path beginning with a Unicode combining mark MUST keep
  every byte rather than being truncated by a character-based slice
  (git-client-012). A `git config` argument list whose key position holds
  a dash-leading flag-shaped string (`-x.token`) MUST redact the value that
  follows it rather than mistaking the flag for the key and logging the
  secret in clear text (git-client-030). A `git config` argument list whose
  key position holds a bare, non-key-shaped word (`"email"`) MUST redact
  both it and the value that follows (git-client-031).
- **Concurrent access**: The git client's verbs each suspend for the whole
  lifetime of the child process, so ten concurrent callers run ten
  concurrent git processes rather than being queued behind one another — a
  deliberate accounting-only bottleneck, not a serialization guarantee. A
  call cancelled while a verb is in flight MUST see the cancellation
  signal propagate unchanged, never wrapped in the git client's own error
  outcome, so cooperative cancellation and any cleanup tied to it keep
  working for the caller.
- **Error states**: A configured executable path with nothing executable
  there MUST throw an executable-not-found outcome before any process is
  spawned, and the attempt MUST still be recorded (git-client-037). A
  command that runs to completion and exits non-zero MUST throw a
  command-failed outcome carrying the real exit status and standard-error
  text, with that standard-error text never reaching the command log
  (git-client-038, git-client-046). The unset-global-config verb on a key
  that was never set MUST surface git's exit status 5 as an ordinary
  command-failed outcome, with no dedicated outcome for it.
- **Timeout (this component's offline-equivalent state)**: This component
  has no network path of its own; its analog of an unreachable server is a
  git process that exceeds the configured timeout. That MUST throw a
  timed-out outcome, with the child terminated before the throw, and the
  attempt recorded with no exit status (git-client-039). A launch failure
  (for example, a working directory that does not exist) and any other
  failure from the underlying process-launch mechanism are collapsed by
  the execution step's total mapping into a launch-failed outcome — no
  error type outside the git client's own error outcome, aside from a
  cancellation signal, can escape it.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| executable path | string (file path) | `/usr/bin/git` | Path to the git binary the client spawns. |
| timeout | number (seconds) | `5` | Wall-clock budget for one invocation. |
| submodule handling | enumeration (ignore / include) | ignore | When set to ignore, the status verb appends `--ignore-submodules`. |
| extra environment | key-value map of strings | empty | Merged over the `GIT_TERMINAL_PROMPT=0` default in the spawned child's environment; lets a caller (a test, in particular) redirect something like `GIT_CONFIG_GLOBAL` without mutating process-wide state. |
| caller attribution | captured at the call site | captured automatically | Identifies the calling file and function that invoked a verb, with no effort required from the caller. |
| git executable path setting | string | `"/usr/bin/git"` | Read when deriving configuration from settings, into the executable path. |
| git status timeout setting | integer (seconds) | `5` | Read when deriving configuration from settings, into the timeout, clamped to a minimum of `1`. |
| git status includes submodules setting | boolean | `false` | Read when deriving configuration from settings; `true` maps to include, `false` to ignore. |

## Deep Linking

Not applicable: the git client is a subprocess-spawning component with no
app URL scheme, intent filter, or platform deep-link registration of its
own; nothing in it references a URL scheme or system activity-handoff
mechanism.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| command-failed detail | `"git \(verb) exited with status \(exitStatus)."` (or with git's own detail appended) | The command-failed outcome's user-facing description |
| timed-out | `"git \(verb) did not finish within the configured timeout."` | The timed-out outcome |
| launch-failed | `"git \(verb) could not be run: \(reason)"` | The launch-failed outcome |
| executable-not-found | `"No git executable at \(path). Change it in Settings > Git."` | The executable-not-found outcome |

Every string above is hardcoded English with no lookup table, ICU message,
or locale parameter anywhere in this component — there is no localization
mechanism here. This is a plain fact about the design, not a gap: a port to
a platform with an internationalization layer MUST decide, as a design
choice outside this contract, whether and how to route these four strings
through it.

## Accessibility Options

Not applicable: the git client renders no UI and defines no reduced-motion,
increased-contrast, or color-differentiation behavior of its own; nothing
in it references any such display option.

## Feature Flags

Not applicable: no part of this component defines or reads a feature-flag
key. Submodule handling is caller-configured state, not a flag, and every
conditional path (the executable check, the submodule setting, an exit
status) is derived from configuration or from git's own output, never from
a flag this component owns.

## Analytics

Not applicable: no part of this component emits a client-side analytics or
telemetry event. The command log (see Logging) records operational call
metadata for debugging and audit, not product-analytics events.

## Privacy

- **Data collected**: This component persists no user content of its own;
  the client configuration and the three settings it reads hold only an
  executable path, a timeout integer, and a boolean. The one
  privacy-relevant surface is the *value* argument of the
  set-global-config verb, which may carry an email address, a signing key,
  or a URL containing a token.
- **Redaction lives at the funnel, not at call sites**: The command log's
  argument redaction is scoped to the config verb and redacts every
  argument at and after the first non-flag position, so a caller-supplied
  value never reaches log output in clear text; standard-error text —
  which may itself echo a repository path — MUST NEVER reach the log at
  all.
- **Nothing leaves the device through this component**: every verb spawns
  a local git subprocess; nothing in this component performs network I/O
  itself, though the git binary it spawns may contact a remote if a future
  verb passes arguments that do (none of the seven given verbs do).

## Logging

Subsystem/category are whatever this component's own logging
configuration assigns.

| Event | Level | Message shape |
|-------|-------|---------------|
| Every invocation attempt, regardless of outcome | info | `` `git <verb> <redacted-arguments> cwd=<path> from=<file>:<function> <ms>ms status=<exitStatus-or-"unfinished">` `` |

The command log MUST NOT log the process's standard output or standard
error — only that a call happened and where it came from, so git usage can
be counted, attributed, and audited without the log becoming a copy of the
repository. Arguments are logged at public visibility after passing through
the redaction rule (see Behavioral Requirements and Privacy above), never
collapsed as a whole, because that would hide the entire interpolation for
every verb rather than redacting the one argument position that needs it.
The redaction rule today covers only the config verb; a future addition is
expected to add coverage for a commit-message argument and any remote URL,
once those verbs exist.

## Platform Notes

- **SwiftUI**: The git client is Foundation-only and framework-agnostic,
  but its own documentation calls out a SwiftUI caller by name: a `.task`
  that drives the status verb and is torn down mid-flight is the reason
  the execution step rethrows a cancellation signal unchanged rather than
  wrapping it. A SwiftUI port keeps that contract by driving every verb
  from a cancellable task and never catching a cancellation signal as if
  it were one of the git client's own error outcomes.
- **AppKit / UIKit**: The nine source files (`GitBranch.swift`,
  `GitCaller.swift`, `GitClient.swift`, `GitClientConfiguration.swift`,
  `GitClientError.swift`, `GitCommandLog.swift`, `GitConfigEntry.swift`,
  `GitFileStatus.swift`, `GitStatus.swift`, `GitWorktree.swift`) live in
  the shared `AgenticDeveloperHubSDKCore` framework (`Core/Git/`) and import only
  `Foundation` and `OSLog` — no `AppKit`/`UIKit` dependency at all.
  `GitClient` is declared as a Swift `actor`, whose verbs each suspend at
  the `await SubprocessChannel.run` point, releasing the actor for the
  whole lifetime of the child process (**concurrent-calls-not-serialized**);
  its private `execute` method is the sole call site of
  `SubprocessChannel.run` in this component (**single-spawn-point**).
  `GitBranch`, `GitCaller`, `GitClientConfiguration`, `GitConfigEntry`,
  `GitFileStatus`, `GitStatus`, and `GitWorktree` each declare `Sendable`
  conformance to satisfy **value-types-thread-safe** across the actor's
  async boundary. `execute` checks
  `FileManager.default.isExecutableFile(atPath:)` before spawning
  (**executable-preflight**); its total catch chain maps
  `WallClockBudgetExceeded` to `GitClientError.timedOut` and every other
  error to `.launchFailed`, with a `CancellationError`-specific catch ahead
  of both that rethrows unchanged (**total-failure-mapping**,
  **cancellation-error-passthrough**). `GitCaller`'s `file` and `function`
  properties are captured via `#fileID`/`#function` default arguments
  evaluated in the calling context (**caller-capture-at-call-site**).
  `execute` decodes captured standard output as UTF-8 first, falling back
  to ISO Latin-1, never to `String(decoding:as:)`'s lossy-replacement
  decoding (**output-decode-fallback**).
  `GitClientConfiguration.fromSettings()` reads `UserSettings
  .gitExecutablePath`, `.gitStatusTimeoutSeconds`, and
  `.gitStatusIncludesSubmodules` (`UserSettings+Git.swift`).
  `GitCommandLog`'s subsystem/category come from its `Loggable`
  conformance's `makeLogger()`; arguments are logged at `.public` `OSLog`
  privacy after redaction, never through `OSLogPrivacy.private`, because
  that would collapse the whole interpolation for every verb rather than
  redacting the one argument position that needs it. An AppKit or UIKit
  caller consumes the same actor and the same four-case error outcome
  through ordinary `async`/`await`, with no framework-specific adaptation
  needed.
- **Compose (Kotlin/Android)**: The actor's bottleneck-for-accounting model
  maps to a Kotlin object exposing `suspend fun`s backed by
  `ProcessBuilder`/`Process`, run on `Dispatchers.IO`; `withTimeout` stands
  in for the wall-clock budget, a sealed class with the same four variants
  stands in for the git client's error outcome, and
  `kotlinx.coroutines.CancellationException` is the analog that MUST
  likewise be left to propagate unchanged rather than wrapped.
- **React/Web**: There is no browser-side equivalent of spawning a native
  git process; a web port MUST run the equivalent of this component in a
  Node.js backend (`child_process.spawn`/`execa`) behind an API the page
  calls, with an `AbortController`/`AbortSignal.timeout` standing in for
  the configured timeout and a discriminated union mirroring the four
  error-outcome cases returned as the API's error shape.
- **WinUI 3**: This is a process-spawning wrapper, not an HTTP client, so
  `HttpClient`/`System.Text.Json` do not apply. The port is
  `System.Diagnostics.Process` (`ProcessStartInfo` with
  `RedirectStandardOutput`/`RedirectStandardError` and an environment
  dictionary carrying `GIT_TERMINAL_PROMPT=0`) driven by `Task`/`async`-
  `await` in place of the actor — a single static class or service, never
  a `SemaphoreSlim(1)`, since serialized execution would contradict the
  concurrent-processes contract above. `CancellationTokenSource` with a
  `TimeSpan` timeout replaces the wall-clock budget and
  `OperationCanceledException` replaces the cancellation signal as the one
  type that MUST propagate unchanged. `Windows.Storage
  .ApplicationDataContainer` is the analog of the three settings
  `fromSettings()` reads. `ObservableCollection`/`INotifyPropertyChanged`
  have no direct analog here — this component has no bindable, mutable
  collection of its own — but would back a WinUI view model that exposes a
  status snapshot to XAML.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Git/` | confirmed (1.2.0) |
| macos | `packages/apple/AgenticDeveloperHubSDK/Core/Git/GitFileHistoryEntry.swift` | confirmed (1.2.0) |

## Design Decisions

**Decision**: The git client is a Swift `actor` whose bottleneck is for
accounting (one identifiable door, one command log, one place to add a
future limit), not for serializing execution — every verb suspends at
`SubprocessChannel.run`, so concurrent callers get concurrent child
processes.
**Rationale**: (Swift actor implementation) A `status` on one repository
has no reason to wait behind a `worktree list` on another; a struct with a
shared queue would have serialized them for no benefit.
**Approved**: pending

**Decision**: The execution step records and then rethrows a cancellation
signal unchanged instead of wrapping it in the git client's own error
outcome.
**Rationale**: (Swift implementation) Wrapping it would break cooperative
cancellation propagation and structured-concurrency cleanup for every
caller, starting with a SwiftUI `.task` torn down while a `status` call is
in flight.
**Approved**: pending

**Decision**: The command log's argument redaction redacts by argument
*position* (everything at and after the first non-flag position, once that
position is spent) rather than by the *shape* of what is found there.
**Rationale**: The earlier, shape-based scan took the first argument not
beginning with `-` to be the key; a key beginning with `-` (`-x.token`) is
not a well-formed key, so that scan walked past it and logged the *secret*
that followed in clear text. Spending the position exactly once means a
shape this rule does not model costs a redacted argument, never a leaked
one.
**Approved**: pending

**Decision**: The execution step decodes captured standard output as UTF-8
first and falls back to ISO Latin-1, never to a lossy-replacement decoding.
**Rationale**: (Swift implementation) Swift's lossy `String(decoding:)`
would substitute U+FFFD for any byte git could not express in UTF-8 and
hand the parser a path matching nothing on disk, while a Latin-1 fallback
re-reads the whole capture losslessly, at the cost of mojibake only on the
rare capture that is not valid UTF-8.
**Approved**: pending

**Decision**: Parsing status slices and counts each porcelain record in
UTF-8 bytes, never by character.
**Rationale**: (Swift implementation) A path beginning with a combining
mark merges with the preceding separator into one grapheme cluster under
Swift's `Character`-based counting, which previously consumed a byte of
the path along with the separator and yielded an empty path that trapped
the directory roll-up.
**Approved**: pending

**Decision**: The execution step sets `GIT_TERMINAL_PROMPT=0`
unconditionally in the child's environment, merged under any
caller-supplied extra environment.
**Rationale**: Without it, a credential prompt would hang the child behind
a terminal nobody is watching, turning a network-auth failure into an
indefinite hang instead of a command-failed/timed-out outcome the caller
can act on.
**Approved**: pending

**Decision**: The `max(1, ...)` timeout clamp lives only in the
settings-derived configuration path, not in the plain constructor.
**Rationale**: (Swift implementation) The settings-derived path
(`fromSettings()`) is where a user-editable settings value reaches, where
zero or a negative number is a user-entry mistake that must not produce an
instantly-expiring budget; a directly-constructed configuration (as tests
build) is a programmatic value the caller is responsible for, so the plain
constructor imposes no clamp of its own.
**Approved**: pending

**Decision**: The three global-configuration verbs run with the user's
home directory as the child's working directory, never a repository
directory.
**Rationale**: `git config --global` neither discovers nor reads a
repository, so home is used only as somewhere legible for the child to
stand — never a location this client actually reads from or writes to as a
repository.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | passed | Best Practices |
| [adc.check.reliability.timeout-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f4d73297-4002-5b4d-91c2-74a20866ab61) | passed | Reliability |
| [adc.check.reliability.fault-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/bf974abf-71df-5370-9d43-fa7e563fc353) | passed | Reliability |
| [adc.check.security.secure-log-output](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/b258657f-bb73-5491-9c70-0d14afdfa6ce) | passed | Security |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy and Data |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |

`separation-of-concerns` **passed**: process-spawning and accounting
(`GitClient.execute`) is separate from parsing (`GitStatus`, `GitBranch`,
`GitWorktree`, `GitConfigEntry`, each its own type), from configuration
(`GitClientConfiguration`), and from logging (`GitCommandLog`) — no layer
does another layer's job. `unit-test-coverage` **passed**: seven test files
cover every parser, the redaction rule, the configuration clamp, and the
client's real-process error paths with meaningful assertions, not
placeholders. `explicit-error-handling` **passed**: `execute`'s catch chain
is total by construction — every error becomes a `GitClientError` case
except the one documented, deliberate exception (`CancellationError`
rethrown unchanged); nothing is silently swallowed. `timeout-handling`
**passed**: a `WallClockBudgetExceeded` is mapped to `timedOut`, and the
child is terminated before the error is thrown, per `GitClientError`'s own
doc comment, leaving no orphaned process behind. `fault-tolerance`
**passed**: `GitStatus.parse` and `GitWorktree.parse` are written to cost a
malformed record exactly one dropped entry rather than trapping the process
— demonstrated directly by `recordWithNoPathIsSkipped` and
`pathOfSeparatorsOnlyIsSkipped`. `secure-log-output` **passed**:
`GitCommandLog` never logs standard output or standard error, and
`redactedArguments` keeps a `config` value out of the `.public` log line
entirely. `input-sanitization` **partial**: `GitConfigEntry.isWellFormedKey`
classifies a key shape for *redaction* purposes, but neither
`setGlobalConfig` nor `unsetGlobalConfig` validates `key` or `value` before
handing them to git — an invalid key is left for git itself to reject with a
non-zero exit, which `execute` then surfaces as `commandFailed` rather than
as a pre-flight validation error. `no-pii-in-logs` **passed**: the only
argument position capable of carrying personal data (a `config` value) is
redacted before it reaches the log, and `GitClientError.logDescription`
withholds `standardError`, the launch `reason`, and the configured
executable `path` from ever reaching `OSLog`. `no-hardcoded-strings`
**failed**: all four `GitClientError.errorDescription` strings are hardcoded
English with no lookup table or locale parameter anywhere in this component
(see Localization) — an honestly-reported gap in the source, not a hidden
one.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial creation |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: removed source line-number citations; recipes cite files and symbols, not lines. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.1.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to foundation/git/. |
| 1.2.0 | 2026-11-13 | Mike Fullerton | History model: commit, ref, stash and submodule value types with their format strings and parsers, and the log request; output decoding falls back to Latin-1 per segment; diff, word-diff and blame models with their parsers and C-quoted path unquoting; read verbs (top level, log, refs, stashes, submodules, diff targets and options, blame, file contents) and accepted exit codes in the execution step. |