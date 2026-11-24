---
id: 779ac6ea-9ef5-4fb0-8ed9-dc6b9d617344
title: "Git Client"
type: ingredient
version: 2.2.2
status: review
language: en
created: 2026-09-24
modified: 2026-11-16
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
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitAction.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitActionTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitClientWriteTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitPatchBuilder.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitOperationState.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/RPC/SubprocessChannel+Run.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitPatchBuilderTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitClientPatchTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitConflict.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Core/Git/GitRebasePlan.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitClientConflictTests.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/Tests/AgenticDeveloperHubSDKCoreTests/Git/GitRebasePlanTests.swift (adhsdk)
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
failure onto a closed five-case error outcome. It has no visual surface of
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
  --porcelain -z` and MUST return every worktree of the repository containing
  the given directory, main worktree first. A git too old for `-z` exits 129
  with its usage, and the verb MUST then read the list again without `-z`.
  The parser MUST split records on NUL when the output holds one and on
  newlines otherwise, so a path holding a newline stays one record.
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
  `core.quotePath=false` and `core.precomposeUnicode=true`, and MUST parse the output with the file history
  rule; on exit status 128 with an unresolvable HEAD it returns no entries.
  It reads at most the log request's default limit (500 commits) and MUST
  expose that limit as a constant, so a caller can tell a capped history
  from a complete one.
- **path-precompose**: A verb handed one path to find (blame, file history)
  MUST run with `-c core.precomposeUnicode=true`. Foundation hands arguments
  over decomposed (NFD) and git stores names precomposed (NFC); without the
  override a repository whose own configuration lacks the setting (made on
  another system, or with it cleared) finds no non-ASCII path at all.
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
- **changed-files-command**: The changed-files verb MUST list the files a
  commit changed without their patch: `git -c core.quotePath=false -c
  diff.suppressBlankEmpty=false diff --name-status -z --no-color
  --no-ext-diff --no-relative --find-renames --end-of-options <base>
  <commit>`, against the same base the commit diff target uses (first
  parent, or the empty tree), parsed with the name-status rule. A commit
  view lists these and asks for one file's patch at a time, so a huge
  commit costs one name per file rather than every line of its patch.
- **name-status-parse**: Parsing `--name-status -z` output MUST read each
  record as a status token and one path, or for a rename or copy (`R<n>`,
  `C<n>`) a token, the old path and the new path, all NUL-terminated and
  never quoted. `A`, `D`, `R`, `C` and `U` map to added, deleted, renamed,
  copied and conflicted; anything else (including a type change) is
  modified; a truncated last record MUST be dropped.
- **diff-untracked**: The untracked target MUST run `git diff --no-index --
  /dev/null <path>` in the top level, accepting exit statuses 0 and 1
  (`--no-index` exits 1 when the files differ); an exit status of 1 with no
  output (git could not read the file) MUST surface as command-failed.
- **diff-conflicted**: The conflicted target MUST run the diff with `--base`
  (the working file against the merge base, stage 1), so a conflict whose
  plain diff is only `* Unmerged path` (a delete on either side) still shows
  a patch; when that yields no file (there is no base stage, as in
  both-added) it MUST run `--end-of-options HEAD` instead; when that is
  empty too and the working file exists (added by us, the working file being
  ours), it MUST show the working file as all added, as an untracked file's
  diff does. Both diffs take the path as the one `:(top,literal)` pathspec.
  Each file's `oldRevision` MUST name the old side used: `:1` for the base,
  `HEAD` for the fallback, nil when there is no old side.
- **blame-command**: The blame verb MUST run `git -c core.quotePath=false
  -c core.precomposeUnicode=true blame --porcelain [<commit>] -- <path>` in the top level, omitting the
  commit to blame the working tree, and MUST parse the output with the
  blame parsing rule. `git blame` does not accept `--end-of-options`, so a
  revision MUST first be resolved to a commit hash (which can never read as
  an option); a revision naming no commit MUST surface as command-failed
  with exit status 128.
- **file-contents**: The file-contents verb MUST return raw bytes, never
  decoded text. With no revision it MUST read the working file at the top
  level joined with the path, returning nothing when it does not exist; a
  path that is empty, or that leads outside the top level (through `../` or
  a linked folder, compared with the folder's symbolic links resolved, or
  through a symbolic link as the path's last component, compared with that
  link resolved), MUST surface as invalid-argument before anything is read;
  a link to a file inside the top level reads that file.
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
- **file-contents-cap**: Given a maximum byte count, the file-contents verb
  MUST check the size before reading anything and return nothing when the
  file is larger: the working file's size attribute, or `git cat-file -s
  <object id>` before `cat-file blob`. A file of exactly the maximum is read.

### Write verbs

- **write-actions**: Every write to a repository MUST be expressed as one
  action value and run by the single perform verb; a caller names an intent
  and never assembles flags. The actions are: stage paths, stage all,
  unstage paths, unstage all, discard (tracked files' working-tree changes),
  remove untracked, commit (message, amend), fetch (one remote or all),
  pull, push, push setting upstream (remote, branch), push to upstream
  (remote, branch, upstream branch), create branch (name,
  optional start point, optional checkout), checkout branch, checkout
  tracking (a remote branch), checkout detached (commit), rename branch,
  delete branch (optional force), delete remote branch, create tag (name,
  commit, optional message), delete tag, push tag, stash save (optional
  message), stash apply, stash pop and stash drop (each by index),
  cherry-pick and revert (commit, optional mainline), reset (commit,
  soft, mixed or hard), apply a patch to the index or to the work
  tree (patch text, reverse), merge (ref, fast-forward allowed, never or
  only), rebase (onto a ref), an in-progress operation's step
  (merge, rebase, cherry-pick or revert; continue, abort or skip), resolve
  (paths, ours or theirs), remove paths, interactive rebase (a plan), add
  worktree (path, branch, create the branch or not, optional start point),
  remove worktree (path, force) and update submodules (paths, initialize).
- **write-action-mapping**: Each action MUST map to exactly this verb and
  these arguments, every path list preceded by `--` and every path in it
  written as the literal, top-relative pathspec `:(top,literal)<path>`, so a
  path holding pathspec magic (`[ab].txt`, `*.log`, `app/[slug]/page.tsx`)
  names only that file and is resolved from the repository root, as status
  reports it: stage → `add -- <paths>`;
  stage all → `add -A`; unstage → `reset -q -- <paths>`; unstage all →
  `reset -q`; discard → `restore --worktree -- <paths>`; remove untracked →
  `clean -f -d -- <paths>`; commit → `commit --cleanup=whitespace -m <message>`
  (trailing whitespace and blank lines trimmed, a line starting with `#` kept),
  plus `--amend` when amending; fetch all → `fetch --all --prune`, fetch one
  → `fetch --prune <remote>`; pull → `pull --no-edit`; push → `push`; push
  setting upstream → `push --set-upstream <remote> <branch>`; push to
  upstream → `push <remote> refs/heads/<branch>:refs/heads/<upstream
  branch>`, which leaves the branch's tracking as it is; create branch
  → `branch <name> [<start>]`, or with checkout `switch -c <name> [<start>]`;
  checkout → `switch <branch>`; checkout tracking → `switch --track
  <remote>/<branch>`; checkout detached → `switch --detach <commit>`; rename
  → `branch -m <from> <to>`; delete branch → `branch -d <name>`, or `-D`
  forced; delete remote branch → `push <remote> --delete <name>`; create tag
  → `tag <name> <commit>`, or with a message `tag -a <name> -m <message>
  <commit>`; delete tag → `tag -d <name>`; push tag → `push <remote>
  refs/tags/<name>`; stash save → `stash push --include-untracked`, plus `-m
  <message>` only when the message is present and non-empty; stash apply,
  pop and drop → `stash apply|pop|drop stash@{<index>}`; cherry-pick →
  `cherry-pick [-m <mainline>] <commit>`; revert → `revert --no-edit [-m
  <mainline>] <commit>`; reset → `reset --soft|--mixed|--hard <commit> --`, the
  `--` keeping a commit that shares a file's name a commit; apply to the index → `apply
  --cached --whitespace=nowarn [--reverse] -`; apply to the work tree →
  `apply --whitespace=nowarn [--reverse] -`, the patch on standard input;
  merge → `merge --no-edit --ff|--no-ff|--ff-only <ref>` (fast-forward
  allowed, never, only); rebase → `rebase <ref>`; an operation's step →
  `merge|rebase|cherry-pick|revert --continue|--abort|--skip`; resolve →
  `checkout --ours|--theirs -- <paths>`; remove paths → `rm -q -- <paths>`;
  interactive rebase → `rebase -i <onto>`, the todo supplied by the perform
  verb (`interactive-rebase-run`); add worktree → `worktree add -b <branch>
  <path> [<start>]` when creating the branch, else `worktree add <path>
  <branch>`; remove worktree → `worktree remove [--force] <path>`; update
  submodules → `submodule update [--init] --recursive [-- <paths>]`, every
  submodule when no paths are named.
- **write-operand-guard**: None of those mappings puts a ref, branch, tag,
  remote or commit after `--`, so git would read one that begins with `-`
  as an option (`branch --delete main` from a branch named `--delete`
  started at `main`; `tag -d v2` from a tag named `-d` on `v2`). The
  perform verb MUST therefore refuse, before resolving its configuration or
  spawning anything, any action whose positional operands — branch name,
  start point, checkout target, remote branch, commit, tag name, remote,
  a push's upstream branch, a rename's old and new names, an interactive
  rebase's onto commit, and an added worktree's branch and, when the branch
  is created, its start point — include one that is empty or begins
  with `-`, with a distinct invalid-argument outcome carrying the verb and
  the offending value (its log description carries only the verb). Paths,
  which follow `--`, and messages, which follow `-m`, are exempt. It MUST
  likewise refuse a stage, unstage, discard or remove-untracked action whose
  path list is empty, and a resolve or remove-paths action likewise, as
  invalid-argument with an empty value (an update-submodules action with no
  paths is not refused: it means every submodule): git reads an
  empty pathspec list as the whole tree, so `clean -f -d --` with no paths
  would delete every untracked file. A merge's ref and a rebase's onto ref
  are operands like any other. A merge has no skip step (`git merge` takes
  no `--skip`), so the merge-skip action MUST be refused the same way,
  carrying the verb `merge` and the value `--skip`. The outcome's
  description MUST say a name or commit is empty for an empty value, that
  the value begins with `-` for a dash-led one, and otherwise show the value
  itself, which is then a sentence giving the reason (an invalid rebase
  plan, a relative worktree path).
- **write-budgets**: The perform verb MUST run through the same private
  execution step as every read — logged, attributed and mapped onto the
  same error outcomes — with its own wall-clock budget: the larger of the
  configured timeout and 60 seconds for a local write, or 600 seconds for a
  long-running one. The long-running actions are the ones that talk to a
  remote (fetch, pull, push, push setting upstream, push to upstream,
  delete remote branch,
  push tag) and the ones that make commits, which run the repository's
  hooks: commit, merge, rebase, interactive rebase, and an operation's
  continue and skip steps (an abort makes no commit and is local); adding a
  worktree (it checks out a whole tree and runs the post-checkout hook) and
  updating submodules (each may be cloned) are long-running too, and so are
  an LFS fetch and an LFS pull, which download objects. Both budgets
  MUST be exposed as constants. A read's budget is unchanged.
- **write-editor-override**: The perform verb MUST run with `-c
  core.editor=true`, so no write can stop to wait on an editor nobody is
  watching; together with `GIT_TERMINAL_PROMPT=0` a write either finishes
  or fails, and a write that cannot reach a remote (none configured)
  surfaces as command-failed, not as a timeout. It MUST also set
  `GIT_EDITOR=true` in the child's environment, over anything the parent
  or the configuration's extra environment set: `GIT_EDITOR` outranks
  `core.editor`, and a continue step MUST never wait on an editor, so the
  message git prepared (`MERGE_MSG`, the picked commit's) is kept as it is.
- **remotes-command**: The remotes verb MUST invoke `git remote -v` and
  return, once each and sorted, the names of the remotes that have a
  non-empty URL. A name that exists only through a setting
  (`remote.<name>.prune` with no `url`) is not a remote: `git remote` alone
  would list it, and pushing or fetching it fails.
- **last-commit-message**: The last-commit-message verb MUST return HEAD's
  full message (`git log -1 --no-color --no-show-signature --format=%B
  <HEAD>`) with trailing whitespace and newlines trimmed, and MUST return
  nothing on an unborn HEAD, detected by HEAD failing to resolve to a
  commit before `log` runs, so it never throws for that case.
- **push-destination**: The push-destination verb MUST return where `git push`
  would send a local branch as git itself resolves it, `git rev-parse
  --abbrev-ref --symbolic-full-name <branch>@{push}` through the execution
  step (so `push.default`, `branch.<name>.pushRemote` and
  `remote.pushDefault` apply), trimmed, such as `origin/feature`. When git
  names no single destination (no upstream, `simple` with a name unlike the
  upstream's, a local `.` upstream, or a destination whose remote-tracking
  branch does not exist yet) it MUST fail as command-failed with git's
  message. An empty or dash-led branch MUST be refused as invalid-argument
  before anything is spawned.

### Patches from diff lines

- **patch-selection**: A selection MUST name one file's parsed diff and, per
  hunk index, the set of line indices chosen in that hunk. Only added and
  removed lines count as chosen; a context line, a marker or an index out of
  range is ignored. The hunk selection of hunk `n` MUST be every added and
  removed line of that hunk, and empty for an index that is not a hunk.
- **patch-buildable**: A patch MUST be built only for a text file (not
  binary) with at least one hunk whose change is modified or renamed, whose
  old and new paths are both present and non-empty and contain no newline,
  tab or carriage return. Added, deleted, copied and type-changed files (an
  untracked file reads as added) are refused, and building returns nothing.
- **patch-forward-lines**: Forward (staging, applying), each hunk MUST keep
  a chosen added line, drop an unchosen added line, keep a chosen removed
  line and write an unchosen removed line as context.
- **patch-reverse-lines**: Reversed (unstaging, discarding), each hunk MUST
  keep chosen lines, write an unchosen added line as context and drop an
  unchosen removed line, because a reversed patch is applied to the new
  side.
- **patch-no-newline**: A no-newline-at-end marker MUST follow the last line
  of each side of the written hunk that git marked as ending without a
  newline, and no other line. When a dropped change moves one side's end, a
  context line can end one side without a newline but not the other; that
  line MUST be written as a removed line and an added line of the same text,
  each followed by a marker only for its own side, which keeps both counts.
  Appending `b` after an old side `x`, `a` with no final newline stages
  `-a`, marker, `+a`, `+b`, marker, and the index reads `x\na\nb` byte for
  byte.
- **patch-carriage-returns**: A line's text MUST keep a carriage return git
  wrote before its newline, so a patch built from a CRLF file's lines writes
  each line back with its `\r` and applies cleanly; only display drops it.
- **patch-hunk-headers**: A hunk with no chosen line MUST be left out. Each
  written hunk MUST count its lines anew (old = context + removed, new =
  context + added). Forward keeps the hunk's old start and sets the new start
  to the old start plus the net change (new count − old count) of the hunks
  already written; reversed keeps the new start and sets the old start to the
  new start minus that net change. A side whose count is 0 names the line
  before it, as git writes it. A selection that writes no hunk MUST build no
  patch.
- **patch-file-header**: The patch MUST open `diff --git a/<path> b/<path>`,
  `--- a/<path>`, `+++ b/<path>` naming one path on both sides: the old path
  forward, the new path reversed. Naming both paths of a rename would make
  `apply` rename the file too, so unstaging a line of a staged rename would
  move the file back. The patch MUST end with a newline.
- **patch-apply**: Applying MUST go through the perform verb as the apply to
  the index or apply to the work tree action, the patch written to the
  child's standard input while its output is read (so neither pipe can stall
  the other) and the input then closed. The command log MUST record the
  verb and arguments only, never the patch. An empty patch MUST be refused
  as invalid-argument with an empty value before anything is spawned. A patch
  that no longer applies MUST fail as command-failed carrying git's message.

### Operations

- **operation-kinds**: An in-progress operation MUST be one of four kinds,
  merge, rebase, cherry-pick and revert, each run by the git verb of the
  same name, and its steps MUST be continue, abort and skip, written
  `--continue`, `--abort` and `--skip`.
- **operation-state**: The operation-state verb MUST report which operation
  the working tree is in, read from the files git keeps for it in the
  working tree's own git directory, each located through the git-path verb
  (`rev-parse --git-path <name>`), never by joining `.git/` by hand: a
  linked worktree keeps them under the common directory's
  `worktrees/<name>/`. They are tried in this order, the first present
  winning: `rebase-merge/` → rebasing, with the branch from `head-name`
  (`refs/heads/` stripped), the onto commit from `onto`, the step from
  `msgnum`, the total from `end`, and interactive when `interactive`
  exists and `drop_redundant_commits` does not (since git 2.26 every
  merge-backend rebase writes `interactive`; under default options only a
  plain rebase, whose `--empty` is drop, writes `drop_redundant_commits`); `rebase-apply/` → rebasing, with `head-name`, `onto`, the step
  from `next` and the total from `last`, never interactive; `MERGE_HEAD` →
  merging, with the first commit it names; `CHERRY_PICK_HEAD` →
  cherry-picking that commit; `REVERT_HEAD` → reverting that commit;
  otherwise none. Each value is the file's text trimmed of whitespace; a
  missing, empty or unreadable file, or a count that is not a number, MUST
  give no value for that field, never a failure. The git-path lookups MAY
  be one `rev-parse` naming every file, falling back to one call each when
  its output cannot be split into exactly one line per file.
- **operation-state-properties**: The state MUST expose its kind (none for
  no operation) and whether it allows skip: rebasing, cherry-picking and
  reverting do; merging and none do not.
- **operation-editor**: A continue step MUST finish without an editor
  (`write-editor-override`), keeping the message git prepared.

### Conflicts

- **conflict-kinds**: A conflicted path MUST carry one of seven kinds, named
  by its status pair, the first letter our side (stage 2) and the second
  theirs (stage 3): both modified `UU`, both added `AA`, deleted by us `DU`,
  deleted by them `UD`, added by us `AU`, added by them `UA`, both deleted
  `DD`. Our side exists for `UU`, `AA`, `UD` and `AU`; theirs for `UU`, `AA`,
  `DU` and `UA`; only `UU` and `AA` leave conflict markers in the working
  file.
- **conflict-resolve-by-side**: Taking one side of a conflict MUST be the
  resolve action (`checkout --ours|--theirs`), after which staging the path
  marks it resolved. A side that deleted the file MUST be taken with the
  remove-paths action (`rm -q`), which resolves the path at once. Reading
  and resolving the markers inside a file is the conflict document's
  (`git-conflict-document`).

### Interactive rebase

- **rebase-plan-command**: The rebase-plan verb MUST resolve its onto
  commit to a full sha, then list `log --reverse --first-parent <onto>..HEAD`
  (no colour, no signatures, the commit format of `commit-format`), oldest
  first, as plan entries all picked, each with its commit and subject. It
  MUST refuse, as invalid-argument naming `rebase`, an onto that is empty,
  begins with `-` or names no commit, an empty range, and a range holding a
  merge commit (a plan replays a straight line; `rebase -i` without
  `--rebase-merges` would flatten the merge).
- **rebase-plan-messages**: The commit-messages verb MUST list
  `log --first-parent <onto>..HEAD` (no colour, no signatures) with each
  commit's full sha and its raw message (`%B`), records split by the record
  separator and sha from message by the unit separator, in one call, and
  answer a map from sha to message with its trailing whitespace trimmed, so a
  rebase editor can show every reword's message without a call per commit. It
  MUST refuse, as invalid-argument naming `log`, an onto that is empty or
  begins with `-`; a record with no separator or no sha is dropped.
- **rebase-plan-actions**: An entry's action MUST be one of pick, reword,
  edit, squash, fixup and drop; a reword carries its new message.
- **rebase-plan-validation**: A plan MUST report why git would refuse it,
  checked in this order: every entry dropped (an empty plan included); the
  first entry that is kept being a squash or fixup (there is no earlier
  commit to fold it into); a kept reword whose message is empty or only
  whitespace. The perform verb MUST refuse such a plan as invalid-argument
  carrying that reason, and a plan holding a commit that is not 4 to 64
  ASCII hex digits, and a plan run while any operation is in progress, all
  before writing or spawning anything.
- **interactive-rebase-todo**: The todo MUST hold one line per entry,
  `<action> <sha> <subject>`, the subject's line breaks turned into spaces,
  and end with a newline. A reword MUST be written as three lines, so the
  rebase never needs an editor: `exec git rev-parse HEAD > '<helper>/head-<n>'`,
  then `pick <sha> <subject>`, then `exec test "$(git rev-parse HEAD)" =
  "$(cat '<helper>/head-<n>')" || git commit --amend --no-edit --allow-empty
  -F '<helper>/message-<n>'`, `n` counting rewords from 0 in todo order and
  each path single-quoted for `sh` (each `'` written `'\''`). `git` there is
  the configured executable's path, single-quoted the same way, so the amend
  runs the same git as the rebase; a bare `git` is written unquoted.
- **reword-amends-only-its-pick**: A reword's amend MUST run only when its
  pick moved HEAD. A pick that stops (a conflict, a commit that became empty)
  and is then skipped leaves HEAD where it was, and git still runs the next
  todo line; an unconditional amend would rewrite the previous commit, or
  `onto` itself when the reword is the first kept entry. A pick that applied,
  fast-forwarded, or was resolved and continued always moves HEAD, so its
  amend runs.
- **interactive-rebase-run**: The perform verb MUST write the todo and each
  reword's message into the helper folder, `rev-parse --git-path
  adk-rebase` (inside the working tree's own git directory, beside
  `rebase-merge/`), replacing any folder already there; MUST set
  `GIT_SEQUENCE_EDITOR` to `cp '<helper>/todo'`, which git calls with its own
  todo's path; and MUST run `rebase -i <onto>` under `GIT_EDITOR=true`
  (`write-editor-override`), so a squash keeps git's combined message.
- **interactive-rebase-cleanup**: After every action it runs, whether git
  succeeded or failed, the perform verb MUST remove the helper folder when it
  exists and the operation state is none, so a rebase finished or aborted
  outside the app does not leave it behind; an interactive rebase also
  replaces any folder already there before writing its own. A rebase that
  stopped (an edit, a conflict) keeps it, since its `exec` lines still read
  the messages. An action refused before spawning does not clean up.

### Worktrees and submodules

- **worktree-absolute-paths**: An add-worktree or remove-worktree action
  MUST name an absolute path; the perform verb MUST refuse a relative one,
  before spawning, as invalid-argument carrying the verb `worktree` and a
  sentence naming the path. A relative path would resolve against wherever
  git runs, and an absolute one can never be read as an option.
- **worktree-remove-dirty**: Removing a worktree with changes or untracked
  files MUST fail as command-failed unless forced; forced, it MUST succeed.
- **submodule-update**: Updating submodules MUST run `submodule update
  [--init] --recursive`, limited to the named paths after `--` when there
  are any, so an initialized superproject whose submodules were never
  cloned ends with each checked out at its recorded commit.

### LFS

- **lfs-pointer**: A Git LFS pointer MUST parse only from text of at most
  1024 bytes whose first non-blank line is exactly `version
  https://git-lfs.github.com/spec/v1` and which holds an `oid sha256:<64
  hex digits>` line and a `size <non-negative integer>` line; lines may end
  in CRLF and blank lines are ignored. Anything else is not a pointer. The
  oid is kept as lowercase hex without its `sha256:` prefix, and its short
  form is its first seven characters.
- **lfs-state**: The LFS state verb MUST run `lfs version`; a failure of it
  (git answers "'lfs' is not a git command" when git-lfs is not installed)
  MUST return a not-installed state with no patterns and no files, never
  an error. Otherwise it MUST run `lfs track` and `lfs ls-files` through
  the same bottleneck as every other verb. Every git child's `PATH` MUST
  be the inherited `PATH` followed by `/opt/homebrew/bin`, `/usr/local/bin`,
  `/usr/bin` and `/bin` (each once), so git finds a Homebrew `git-lfs` in
  an app launched from Finder; a configuration's own `PATH` outranks it. An
  `ls-files` failure (a repository with no commit)
  lists no files. The state is in use only when installed and it has a
  tracked pattern or an LFS file.
- **lfs-track-parse**: The tracked patterns MUST be the non-blank lines
  between `Listing tracked patterns` and `Listing excluded patterns` (or
  the end), trimmed, each without its trailing ` (<attributes file>)`.
- **lfs-ls-files-parse**: Each `lfs ls-files` line `<oid> <*|-> <path>`
  MUST map the path to downloaded (`*`) or pointer only (`-`); a line of
  any other shape is skipped.
- **lfs-tracked-path**: A path MUST count as stored in LFS when the state
  is in use and `ls-files` lists it or a tracked pattern matches it by
  `fnmatch`: a pattern with no slash against the file name, one with a
  slash (a leading one dropped) against the whole path.
- **lfs-diff-summary**: A file diff MUST summarise as an LFS diff when it
  is not binary and both its sides parse as pointers, or one does and the
  other side is missing (no lines); the old side is its context and removed
  lines, the new side its context and added lines. The summary reads `LFS
  object <short oid> · <size>`, sizes in `ByteCountFormatter`'s file style,
  with `<old> → <new>` when both sides exist. A side may lack the
  `version` line, which a diff's context leaves out when it did not
  change, so long as every line it has is a pointer's own (`oid`, `size`
  or `ext-…`); ordinary text never reads as a pointer.
- **lfs-actions**: The LFS fetch and LFS pull actions MUST run `lfs fetch`
  and `lfs pull`, with no operands, as long-running writes.

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
- **environment-messages-in-english**: The execution step MUST set
  `LC_MESSAGES=C` in the spawned child's environment, so git's messages
  are English in any locale and a caller that reads one (a branch that is
  `not fully merged`) works everywhere. It MUST NOT set `LC_ALL`, `LC_CTYPE`
  or `LANG`, so the character set, and with it path encoding, stays the
  user's; a parent `LC_ALL` therefore still outranks it. Caller-supplied
  extra environment wins over it like over the prompt default.
- **environment-optional-locks-off**: The execution step MUST set
  `GIT_OPTIONAL_LOCKS=0` in the spawned child's environment, so a
  background `git status` never takes `index.lock` and never makes a
  concurrent `git commit` in the user's terminal fail; writes still take
  the locks they need. Caller-supplied extra environment wins over it.
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

- **error-taxonomy**: The git client's error outcome MUST be exactly five
  cases — command-failed, timed-out, launch-failed, executable-not-found,
  and invalid-argument (a write refused before anything ran) — and MUST NOT include a cancellation signal as one of its cases.
- **error-description-vs-log-description**: The error outcome's
  user-facing description MAY interpolate git's own standard-error text
  into a message for the command-failed case. The error outcome's
  log-facing description MUST NOT include the standard-error text, the
  launch failure's reason, or the configured executable path in any case,
  returning only the case name plus non-sensitive structured fields (verb,
  exit status).
- **user-message**: The error outcome MUST offer one user-message mapping
  for any error a git call ends with: git's standard-error text, trimmed of
  whitespace and newlines, for a command-failed error that has any; the
  error's user-facing description otherwise. It is for display only and
  MUST NOT be logged.
- **command-log-fields**: The command log MUST record the verb, its
  redacted arguments, the working directory, the calling file and
  function, the duration in milliseconds, and the exit status (or the
  literal string `"unfinished"` when no exit status is available), and
  MUST NOT log the process's standard output or standard error to OSLog.
  The in-memory ring (command-log-ring) keeps a call's standard error only
  when its exit status is present and non-zero, passed through the URL
  user-info rule first and then cut to its first 2048 UTF-8 bytes on a
  character boundary, so a credential the cut would split is already gone;
  standard output is never kept anywhere. An exit status the verb accepts
  (exit 1 of `symbolic-ref -q` on a detached HEAD, of `diff --exit-code`
  with differences) is still the status recorded, so its entry keeps its
  standard error and the Command Log shows it as failed.
- **command-log-ring**: Besides OSLog, every recorded call MUST be appended
  to one shared in-memory ring, `GitCommandLog.book`, holding the newest
  500 entries, oldest first. An entry carries an increasing id, its date,
  the tool (`git` by default; `record(tool:)` names another, such as `gh`),
  the arguments as spawned after the tool — `-c <key=value>` for each
  config override, then the verb, then its redacted arguments (the
  positional rule applies to the verb's arguments; the URL rule to all of
  them) — the working directory's path
  (empty when there is none), the caller as `<file>:<function>`, the
  duration rounded to milliseconds, the exit status (nil when unfinished)
  and the kept standard error. Its command line is the tool and the
  arguments joined by spaces, so it is the command that ran. `record`'s
  `tool:`, `configOverrides:` and `standardError:` parameters default to
  `git`, none and nil, so every existing caller is unchanged. Nothing in the ring is persisted.
- **command-log-updates**: `GitCommandLogBook.updates()` MUST yield every
  entry appended after the call, in order, to each subscriber, buffering at
  most the ring's capacity of the newest; a subscriber whose stream ends is
  removed. Subscribers are told outside the ring's lock.
- **redaction-scope-and-positional-rule**: The command log's argument
  redaction MUST return arguments unchanged for every verb except config,
  commit, tag and stash. For commit, tag and stash it MUST replace the
  argument after each `-m` (the user's message) with `<redacted:<length>>`
  and keep the rest; cherry-pick's and revert's `-m` is a mainline number
  and is kept. For config, it MUST redact every argument at and after the
  first non-flag (non-`-`-prefixed) argument position — replacing each with
  `<redacted:<length>>`, the length in characters — regardless of whether that argument is
  shaped like a well-formed key; the config-entry key validator (below) is
  used only to decide whether to *keep* the argument found at that
  position, never to relocate the position itself. After the positional
  rule, for every verb, any URL's user information (the part of its
  authority before the last `@`, the authority ending at `/`, `?`, `#`,
  whitespace or a quote) MUST be replaced with `***`, so
  `https://user:token@host/r.git` is logged as `https://***@host/r.git`.
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
  modified/added/deleted ladder, and MUST keep that pair as the path's
  conflict kind in a conflicts map (`conflict-kinds`).
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
- **worktree-locked**: Parsing worktrees MUST mark a record locked when it
  has a `locked` line, with or without a reason after it, and MUST reset the
  flag for each record.
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
  plus `--fixed-strings` whenever author or message search is set (what a
  person types is text, not a pattern: `(x)` finds itself and a stray `[` is
  no error; `-S` is already literal and adds nothing), then the revisions (default `--branches --tags --remotes HEAD`), then
  `--` and the path as the pathspec `:(top,literal)<path>` when a path is set,
  so `[ab].txt` follows only itself. It MUST NOT pass `-z`.
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
  text MUST exclude its one-character prefix and MUST keep everything else
  git wrote, a carriage return before the newline included: lines are split
  on the newline scalar alone. A line's display text drops one trailing
  carriage return.
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

### Reflog

- **reflog-read**: `reflog(ref:limit:in:caller:)` MUST run
  `reflog show --no-show-signature -z --format=%gd%x1f%H%x1f%gs%x1f%ct -n <limit> <ref>`
  (`ref` defaulting to `HEAD`, a limit below 1 read as 1) and return its
  entries newest first; a ref beginning with `-` MUST be refused as an
  invalid argument before git runs.
- **reflog-unborn**: A ref with no reflog that names no commit (an unborn
  `HEAD`) MUST read as no entries rather than an error; any other failure
  MUST be thrown.
- **reflog-parse**: Each NUL-terminated record MUST be read as selector, sha,
  subject and committer epoch separated by the unit separator, the subject
  being every field between the sha and the epoch; a record with fewer than
  four fields, an empty selector or sha, or an unreadable epoch MUST be
  dropped.
- **reflog-subject-split**: The subject MUST split at its first `": "` into
  the action (`commit (amend)`, `checkout`, `rebase (finish)`) and the
  message, so a message holding `": "` keeps it; a subject without one is all
  action and an empty message.
- **reflog-previous**: Each entry's previous sha MUST be the next (older)
  record's sha, and the oldest entry read has none.
- **undo-state**: `undoState(limit:in:caller:)` (limit 20) MUST read the
  checked-out branch with `symbolic-ref -q HEAD` (exit 1, a detached HEAD,
  reads as the ref `HEAD`), its tip with `resolveCommit`, and that ref's
  reflog, so a branch's Undo never reads HEAD's reflog. Its `target` MUST be
  the first entry whose sha differs from the tip (skipping a step that left
  the tip in place, such as `reset: moving to HEAD`), nil with no tip or no
  such entry; `last` is the newest entry. `undoneEntry` MUST be the step
  Undo takes back, the entry just before `target`; nil with no target, or
  when the newest entry is already not the tip (the reflog lags the ref).
- **undo-preflight**: `undoPreflight(in:caller:)` MUST return the undo state,
  the operation in progress and whether any file is staged or unstaged
  (untracked included), and whether anything is staged
  (`hasStagedChanges`); `isDirty` is true when anything is staged too.
  `resetMode` MUST be `.soft` when anything is staged and `.mixed`
  otherwise. Its `target` is nil while an operation is in progress or any path is
  unmerged (`hasConflicts`, from the status's conflicts).

### Signatures

- **signatures-read**: `signatures(for:in:caller:)` MUST run
  `log --no-show-signature --no-walk=unsorted --ignore-missing --format=%H%x1f%G?%x1f%GS%x1f%GK%x1e <shas…> --`
  in one call bounded by a 15 s budget (`signatureBudget`), and return each
  commit's signature keyed by full sha. A sha the repository does not have
  MUST be absent from the answer without failing the others. No shas MUST answer empty without
  running git; a sha that is empty or not all hex digits MUST be refused as an
  invalid argument before git runs, so nothing can be read as an option.
- **signature-status**: The status MUST come from git's `%G?` letter: `G`
  good, `B` bad, `U` unknown validity, `X` expired, `Y` expired key, `R`
  revoked key, `E` cannot check, `N` unsigned; any other letter MUST read as
  cannot check.
- **signature-parse**: Records MUST be split on the record separator and
  fields on the unit separator, each trimmed of whitespace; a record with no
  sha or no status field MUST be dropped, and an empty signer (`%GS`) or key
  (`%GK`) MUST be absent rather than empty.
- **signature-summary**: A signature's summary MUST be its status's title
  (`Good signature`, `Bad signature`, `Signature of unknown validity`,
  `Expired signature`, `Signed with an expired key`, `Signed with a revoked
  key`, `Signature cannot be checked`, `Not signed`) followed by ` by
  <signer>` when git named a signer.
- **signature-verification-config**: Verification MUST use only the
  repository's and the user's own git configuration (`gpg.format`,
  `gpg.ssh.allowedSignersFile`, the keyring); the client adds no signing
  settings of its own.

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
| git-client-055 | user-message | Command-failed with standard error `  fatal: nope` plus a newline; command-failed with only a newline; timed-out | `fatal: nope`; each error's user-facing description. |
| git-client-056 | environment-messages-in-english | A script standing in for git that prints `$LC_MESSAGES|$LC_CTYPE` | `C|` followed by the parent's `LC_CTYPE`; the defaults set neither `LC_ALL` nor `LC_CTYPE`. |
| git-client-057 | invalid-argument | `.pushToUpstream` with a remote `-q`, a branch `-f`, or an empty upstream branch | Refused before spawning, naming that operand. |
| git-client-058 | push-destination | `main` tracking `origin/main`; `feat` tracking `origin/feature`, under `simple`, then under `push.default=upstream` | `origin/main`; `feat` fails, then `origin/feature`. |
| git-client-059 | push-destination | A branch with no upstream; then the branches `-q`, `--all` and an empty name | Command-failed naming `rev-parse`, its message saying no upstream; each name refused as invalid-argument before spawning. |
| git-client-060 | remotes-command | `remoteWithoutAURLIsNotListed`: `remote.ghost.prune` set with no URL, and `real` added with a URL; separately the verbose output `b\t/x (fetch)`, `b\t/x (push)`, `a\t`, `c\t/y (fetch)` | `["real"]`; `["b", "c"]`. |
| git-client-061 | write-action-mapping | Discard `[ab].txt` beside a modified `a.txt`; remove untracked `*.log` beside an untracked `keep.log`; stage `app/[slug]/page.tsx` beside `app/s/page.tsx` | Only the named file changes each time; the arguments are `:(top,literal)<path>` after `--`. |
| git-client-062 | write-operand-guard | Stage, unstage, discard and remove untracked with an empty path list | Each refused as invalid-argument before spawning; nothing in the tree changes. |
| git-client-063 | redaction-scope-and-positional-rule | `commit` `["--cleanup=whitespace", "-m", "secret token", "--amend"]`; `tag` `["-a", "v1", "-m", "notes", "abc123"]`; `stash` `["push", "--include-untracked", "-m", "wip"]`; `cherry-pick` `["-m", "1", "abc123"]` | `<redacted:12>`, `<redacted:5>` and `<redacted:3>` in the message positions, everything else kept; cherry-pick unchanged. |
| git-client-064 | patch-forward-lines, patch-hunk-headers | Hunk `@@ -1,2 +1,4 @@` `a`, `+x`, `+y`, `b`; choose `x` forward, then reversed | `@@ -1,2 +1,3 @@` ` a`, `+x`, ` b`; reversed `@@ -1,3 +1,4 @@` ` a`, `+x`, ` y`, ` b`. |
| git-client-065 | patch-forward-lines, patch-reverse-lines | Hunk `a`, `-b`, `+c`, `d`; choose `c` | Forward `@@ -1,3 +1,4 @@` with ` b` as context; reversed `@@ -1,2 +1,3 @@` with `b` dropped. |
| git-client-066 | patch-hunk-headers | Hunks `@@ -1,2 +1,4 @@` (choose `x` of `+x`, `+y`) and `@@ -10,3 +12,3 @@` (choose both changes) | Second hunk forward `@@ -10,3 +11,3 @@`, reversed `@@ -11,3 +12,3 @@`; with the first hunk unchosen, forward `@@ -10,3 +10,3 @@`. |
| git-client-067 | patch-no-newline | `+x`, ` a`, ` b`, `+c`, no-newline marker; choose `c`, then `x` forward, then `x` reversed | Marker kept after `+c`; dropped with `c`; kept after ` c` as context. |
| git-client-068 | patch-file-header, patch-buildable | A rename `old name.txt` → `dir/new.txt`; then added, deleted, binary, copied, type-changed, hunkless and tab- or newline-bearing paths | Forward names `old name.txt` on both sides, reversed `dir/new.txt`; every other file builds nothing. |
| git-client-069 | patch-apply, write-action-mapping | A fixture with two hunks; stage one line, unstage it; stage a hunk; discard a line; stage a last line without a newline; unstage a line of a staged rename | Each leaves exactly the chosen change moved; the rename stays a rename; the index blob returns to HEAD's. |
| git-client-070 | patch-apply | A patch made stale by a later edit; an empty patch; the log of one apply | Command-failed naming `apply` with `patch does not apply`; empty refused as invalid-argument; the log line carries `--cached --whitespace=nowarn -` and none of the patch. |
| git-client-071 | write-action-mapping, operation-kinds | Merge `topic` with fast-forward allowed, never and only; rebase onto `main`; every kind with every step | `merge --no-edit --ff topic`, `--no-ff`, `--ff-only`; `rebase main`; `merge --abort`, `rebase --continue`, `cherry-pick --skip`, `revert --abort` and the rest. |
| git-client-072 | write-operand-guard | Merge `-f`; rebase onto an empty ref; the merge-skip step | Each refused as invalid-argument before spawning: `-f`, an empty value, `--skip` naming `merge`. |
| git-client-073 | operation-state, operation-state-properties | A clean repository; then `main` and `topic` both changing `a.txt`, merge `topic` into `main` | None; the merge throws command-failed and the state is merging with `topic`'s commit; it does not allow skip. |
| git-client-074 | operation-state | The merge of 073 aborted | None, and the work tree clean. |
| git-client-075 | operation-state, operation-editor | `feature` with three commits, the first conflicting with `main`, rebased onto `main`; resolve, stage, continue; a second fixture skips instead | Rebasing `feature` onto `main`'s commit, step 1 of 3, not interactive; continue finishes with no editor and three commits on `main`; skip drops the stopped commit, leaving two. |
| git-client-076 | operation-state | A cherry-pick and a revert that each stop on a conflict | Cherry-picking that commit; reverting that commit; both allow skip. |
| git-client-077 | operation-state | A linked worktree (`worktree add`) on `feature`, rebasing onto `main` and stopped; the main worktree read beside it | The linked worktree reports its own rebase; the main worktree reports none. |
| git-client-078 | operation-state | A git directory with `rebase-merge/` holding only `msgnum` `x` and an empty `onto` | Rebasing with no branch, no onto, no step, no total; nothing throws. |
| git-client-079 | write-action-mapping | Merge with fast-forward never into a branch it could fast-forward; with fast-forward only on diverged branches | A merge commit with two parents; command-failed, HEAD unmoved. |
| git-client-080 | operation-state | `rebase -i` (sequence editor `true`) of 075's `feature`, stopped on the conflict; a `rebase-merge/` with `interactive` and `drop_redundant_commits` | Rebasing, step 1 of 3, interactive; the second not interactive. |
| git-client-081 | conflict-kinds, status-conflict-pair-detection | Status output with each of `UU`, `AA`, `DU`, `UD`, `AU`, `UA`, `DD` for `dir/file.txt` beside ` M other.txt` | The conflicts map holds only `dir/file.txt` with that kind; it is conflicted in the unstaged map and the files map. |
| git-client-082 | conflict-kinds | Every kind's sides and markers | Ours for `UU`, `AA`, `UD`, `AU`; theirs for `UU`, `AA`, `DU`, `UA`; markers for `UU` and `AA` only. |
| git-client-083 | write-action-mapping, write-operand-guard | Resolve `a.txt` and `-b` to ours, `a.txt` to theirs; remove paths `gone.txt`; each with an empty path list | `checkout --ours -- :(top,literal)a.txt :(top,literal)-b`, `checkout --theirs -- …`, `rm -q -- :(top,literal)gone.txt`; the empty lists refused as invalid-argument. |
| git-client-084 | conflict-resolve-by-side | `main` and `topic` both change `a.txt`; merge stops; resolve ours, stage | The conflicts map is empty and `a.txt` holds `main`'s text. |
| git-client-085 | conflict-resolve-by-side | `main` deletes `a.txt`, `topic` changes it; merge stops (`DU`); remove paths `a.txt` | The conflicts map is empty and `a.txt` is gone. |
| git-client-086 | rebase-plan-command | `feature` with `add one`, `add two`, `add three` after `main`; plan onto `main` | Onto is `main`'s full sha; entries `add one`, `add two`, `add three`, all pick, the first `HEAD~2`. |
| git-client-087 | rebase-plan-command | Plan onto `HEAD`; onto `nowhere`; onto `main` after merging a side branch into `feature` with `--no-ff` | Each refused as invalid-argument naming `rebase`: an empty range, `“nowhere” names no commit.`, a reason naming the merge commit. |
| git-client-088 | rebase-plan-validation | Plans: all dropped; empty; squash first; drop then fixup; reword with no message or only whitespace; commit `abcg123` | The three reasons in order, none for drop-then-pick; the non-hex commit reported invalid. |
| git-client-089 | interactive-rebase-todo | Pick (subject on two lines), reword, squash, fixup, edit, drop, reword; message files under a path holding `'` | `pick <sha> two lines`; each reword `exec git rev-parse HEAD > '/tmp/it'\''s/head-<n>'`, its pick, and `exec test "$(git rev-parse HEAD)" = "$(cat '/tmp/it'\''s/head-<n>')" || git commit --amend --no-edit --allow-empty -F '/tmp/it'\''s/message-<n>'`, n 0 then 1; the rest as `<action> <sha> <subject>`; a final newline. |
| git-client-090 | interactive-rebase-run, interactive-rebase-cleanup | 086's branch: swap the first two; squash the second; fixup the second; drop the second | `add three`, `add one`, `add two`; squash leaves two commits, the first's body naming `add two`, with the client's `GIT_EDITOR=false`; fixup the same without it; drop removes `two.txt`. No operation and no helper folder after each. |
| git-client-091 | interactive-rebase-todo, interactive-rebase-cleanup | 086's branch with the second entry reworded to `renamed two` with a body holding `'` | Subjects `add three`, `renamed two`, `add one`; the first commit's sha unchanged; no helper folder. |
| git-client-092 | interactive-rebase-cleanup, operation-state | 086's branch with the second entry edit; then the rebase continue step | Stops rebasing, interactive, the helper folder present; continue ends with no operation, three commits and no helper folder. |
| git-client-093 | rebase-plan-validation, interactive-rebase-cleanup | 086's plan with its first entry squash; separately a stale helper folder holding `message-7`, then 086's plan with the second entry edit, the continue step, a second stale folder and a stage of a new file; separately an edit that stops, a stage, then the abort step | Refused before anything runs, HEAD unmoved, no helper folder; the edit stops with `todo` in the folder and no `message-7`, continue removes it, the stage removes the second stale folder; the stage during the stopped rebase keeps the folder and the abort removes it. |
| git-client-094 | write-action-mapping, write-operand-guard, worktree-absolute-paths | Add worktree `/tmp/wt` creating `topic`, with and without start `main`; checking out `topic`; remove with and without force; branch `-x`; start `-s`; path `wt` | `worktree add -b topic /tmp/wt [main]`, `worktree add /tmp/wt topic`, `worktree remove [--force] /tmp/wt`; `-x` and `-s` (when creating) invalid operands; `wt` relative. |
| git-client-095 | worktree-absolute-paths, worktree-remove-dirty | Add a worktree creating `fresh`; add one on the existing `existing`; add `relative/wt`; remove `fresh`; dirty `existing`, remove, then force | Worktrees `main`, `fresh`, `existing`; the relative path refused as invalid-argument; `fresh` gone; the dirty removal command-failed and `existing` kept; forced, only `main` left. |
| git-client-096 | worktree-locked | Porcelain records `locked`, `locked on a removable disk`, and none | Locked, locked, not locked. |
| git-client-097 | write-action-mapping, submodule-update | Update submodules with no paths, with `--init`, and for `lib/a` | `submodule update --recursive`, `submodule update --init --recursive`, `… -- :(top,literal)lib/a`; no paths is not an empty path list. |
| git-client-098 | submodule-update | A superproject with submodule `lib`, cloned without `--recurse-submodules`; update submodules initializing | `lib` uninitialized, then current, `lib/lib.txt` present. |
| git-client-099 | reword-amends-only-its-pick, interactive-rebase-cleanup | `main` with `base`; `feature` adds `x.txt` (`add x`) then changes it (`change x`); plan onto `main` dropping `add x` and rewording `change x` to `reworded x`, which stops on a conflict; then the skip step; separately, `x.txt` resolved, staged and the continue step | Skip: no operation, HEAD and `main` both `main`'s sha, HEAD's subject still `base`, no helper folder. Continue: no operation, one commit `reworded x` whose parent is `main`, no helper folder. |
| git-client-100 | rebase-plan-messages | 086's branch with a fourth commit `add four` whose body is two lines; messages after `main`; then after `-x` | The keys are the plan's commits; HEAD's message is `add four`, a blank line, then the two body lines; `HEAD~3`'s is `add one`; `-x` refused as invalid-argument naming `log`. |
| git-client-101 | rebase-plan-messages | The log text `aaa␟one\n\n␞\nbbb␟two\n\nbody ␟ kept\n␞\nbroken␞\n` (␟ the unit separator, ␞ the record separator) | `aaa` → `one`; `bbb` → `two`, a blank line, `body ␟ kept`; nothing for `broken`. |
| git-client-102 | patch-no-newline | `f.txt` committed as `x\na` (no final newline), working `x\na\nb`; stage the hunk, then unstage `+b` alone | The index reads `x\na\nb`; after unstaging it reads `x\na\n`, byte for byte. |
| git-client-103 | patch-no-newline | Forward: `-a`, marker, `+a`, `+b`, marker with `+b` chosen and `+a` alone dropped; reverse: ` x`, `-a`, marker, `+a`, `+b`, marker with `+b` chosen | Forward writes `-a`, marker, `+a`, `+b`, marker; reverse writes ` x`, ` a`, `+b`, marker. |
| git-client-104 | patch-carriage-returns, diff-line-numbers | A CRLF file `one\r\ntwo\r\nthree\r\nfour\r\n` with `four` changed; stage the one added line | The line's text is `four\r` and its display text `four`; the index is the working file byte for byte. |
| git-client-105 | file-contents | Working-file reads of `../<other>/s.txt`, `link/s.txt` (`link` a symbolic link out of the repository), `file-link` (a link to `<other>/s.txt`), `relative-link` (a link to `link/s.txt`) and `""`, then `in.txt` and `in-link` (a link to `in.txt`) | invalid-argument five times; `in.txt` and `in-link` read `inside\n`. |
| git-client-106 | worktrees-listing | `worktree /repo␀HEAD abc␀branch refs/heads/main␀␀worktree /wt/two\nlines␀HEAD def␀detached␀␀` (␀ a NUL) | Two worktrees, `/repo` on `main` and `/wt/two\nlines` detached. |
| git-client-107 | write-action-mapping | Commit the message `#42 fix\n\n# not a comment  \n` | HEAD's message is `#42 fix\n\n# not a comment`. |
| git-client-108 | submodule-update | Submodules `lib` and `other lib`, cloned without them; update `other lib` initializing | `other lib` current with `lib.txt` present; `lib` uninitialized. |
| git-client-109 | environment-optional-locks-off | A script standing in for git that prints `$GIT_OPTIONAL_LOCKS` | `0`. |
| git-client-110 | diff-conflicted | A rename/rename: `a.txt` renamed to `b.txt` here and to `c.txt` on `side`, `side` merged; diff `.conflicted(b.txt)` (AU, working file equal to HEAD); also a UD and an AA conflict | `b.txt` all added, `oldRevision` nil; the UD diff's `oldRevision` `:1`; the AA one's `HEAD`. |
| git-client-111 | command-log-ring | Record 520 calls `status <i>` into a ring of 500 | 500 entries, the first `status 20`; a `gh` call `pr list` reads `gh pr list`, 250 ms. |
| git-client-112 | command-log-fields | Record status 0, nil and 128 with standard error `boom`; then 128 with `é`×3000 | Only the 128 entry keeps `boom`; the long one keeps 2048 bytes. |
| git-client-113 | redaction-scope-and-positional-rule | `push` `["https://user:tok@github.com/o/r.git", "main"]` | `["push", "https://***@github.com/o/r.git", "main"]`. |
| git-client-114 | command-log-ring | `perform(.commit(message: "secret"))` through a script standing in for git that records its argv | the entry's arguments start `-c core.editor=true commit`; its command line is `git ` plus the spawned argv with `secret` read as `<redacted:6>`. |
| git-client-115 | command-log-fields | Standard error of filler then `https://user:ghp_secrettoken@example.com/…` whose user info straddles byte 2048, status 128 | at most 2048 bytes kept, starting with the filler and `https://`, and no `user:` or `ghp_`. |
| git-client-116 | reflog-parse, reflog-subject-split | Records for `rebase (finish): returning to refs/heads/feature`, `checkout: moving from main to feature`, `commit (amend): fix: the typo`, `commit: two` | Actions `rebase (finish)`, `checkout`, `commit (amend)`, `commit`; the amend's message `fix: the typo`. |
| git-client-117 | reflog-subject-split | The subjects `commit: fix: a: b` and `reset` | (`commit`, `fix: a: b`); (`reset`, empty). |
| git-client-118 | reflog-read, reflog-previous | Three commits, then the third amended; read `HEAD` with limit 10, then 2 | Four entries, `commit (amend)` first, its previous sha the pre-amend commit; limit 2 gives the amend and the pre-amend commit. |
| git-client-119 | reflog-unborn, reflog-read | A repository with no commits; then the ref `--all` | No entries; then invalid-argument. |
| git-client-120 | undo-state | entries `main@{0}` and `main@{1}` at sha `e`×40, `main@{2}` at `d`×40, tip `e`×40; then no tip; then only the first two | target `main@{2}`; nil; nil. |
| git-client-121 | undo-state, undo-preflight | two commits, then `switch -c feature`; then `switch --detach HEAD~1` | ref `refs/heads/feature`, one entry, no target; ref `HEAD`, target the second commit; no operation, clean. |
| git-client-122 | undo-state | a repository with no commits | no tip, no entries, no target. |
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
  text, with that standard-error text never reaching OSLog and kept, cut
  and URL-redacted, only in the in-memory ring (git-client-038,
  git-client-046, git-client-112). The unset-global-config verb on a key
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
| extra environment | key-value map of strings | empty | Merged over the `GIT_TERMINAL_PROMPT=0`, `LC_MESSAGES=C` and `GIT_OPTIONAL_LOCKS=0` defaults in the spawned child's environment; lets a caller (a test, in particular) redirect something like `GIT_CONFIG_GLOBAL` without mutating process-wide state. |
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
| invalid-argument | `"git \(verb) was not run: “\(argument)” begins with “-”, so git would read it as an option."` (or `"git \(verb) was not run: a name or commit is empty."`, or `"git \(verb) was not run: \(reason)"` when the reason is a sentence of its own) | The invalid-argument outcome |

Every string above is hardcoded English with no lookup table, ICU message,
or locale parameter anywhere in this component — there is no localization
mechanism here. This is a plain fact about the design, not a gap: a port to
a platform with an internationalization layer MUST decide, as a design
choice outside this contract, whether and how to route these five strings
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
  argument redaction redacts every config argument at and after the first
  non-flag position, and the message after `-m` for commit, tag and stash,
  so a caller-supplied value or message never reaches log output in clear
  text, and replaces any URL's user information with `***`; standard-error
  text — which may itself echo a repository path — MUST NEVER reach OSLog.
  The in-memory command-log ring keeps it for a failed call only, URL-redacted
  before it is cut to 2048 bytes, and never persists it.
- **Nothing leaves the device through this component**: every verb spawns
  a local git subprocess; nothing in this component performs network I/O
  itself, though the git binary it spawns may contact a remote if a future
  verb passes arguments that do (none of the seven given verbs do).

## Logging

Subsystem/category are whatever this component's own logging
configuration assigns.

| Event | Level | Message shape |
|-------|-------|---------------|
| Every invocation attempt, regardless of outcome | info | `` `git [-c <key=value>]… <verb> <redacted-arguments> cwd=<path> from=<file>:<function> <ms>ms status=<exitStatus-or-"unfinished">` `` |

The command log MUST NOT log the process's standard output or standard
error to OSLog — only that a call happened and where it came from, so git
usage can be counted, attributed, and audited without the log becoming a
copy of the repository. The in-memory ring (`GitCommandLog.book`, see
command-log-ring) keeps a failed call's standard error, URL-redacted and
then truncated to 2048 bytes, for the Git window's Command Log; it is never
persisted and never written to OSLog. Arguments are logged at public visibility after passing through
the redaction rule (see Behavioral Requirements and Privacy above), never
collapsed as a whole, because that would hide the entire interpolation for
every verb rather than redacting the one argument position that needs it.
The redaction rule covers config values, the commit, tag and stash
messages, and any URL's user information (a token in a push URL logs as
`***`). Paths, branch, tag and remote names are logged as they are.

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
  caller consumes the same actor and the same five-case error outcome
  through ordinary `async`/`await`, with no framework-specific adaptation
  needed.
- **Compose (Kotlin/Android)**: The actor's bottleneck-for-accounting model
  maps to a Kotlin object exposing `suspend fun`s backed by
  `ProcessBuilder`/`Process`, run on `Dispatchers.IO`; `withTimeout` stands
  in for the wall-clock budget, a sealed class with the same five variants
  stands in for the git client's error outcome, and
  `kotlinx.coroutines.CancellationException` is the analog that MUST
  likewise be left to propagate unchanged rather than wrapped.
- **React/Web**: There is no browser-side equivalent of spawning a native
  git process; a web port MUST run the equivalent of this component in a
  Node.js backend (`child_process.spawn`/`execa`) behind an API the page
  calls, with an `AbortController`/`AbortSignal.timeout` standing in for
  the configured timeout and a discriminated union mirroring the five
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
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Git/` | confirmed (2.2.2) |
| macos | `packages/apple/AgenticDeveloperHubSDK/Core/Git/GitFileHistoryEntry.swift` | confirmed (2.2.2) |
| macos | `packages/apple/AgenticDeveloperHubSDK/Core/Git/GitAction.swift` | confirmed (2.2.2) |
| macos | `packages/apple/AgenticDeveloperHubSDK/Core/Git/GitPatchBuilder.swift` | confirmed (2.2.2) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Git/GitOperationState.swift` | confirmed (2.2.2) |
| apple | `packages/apple/AgenticDeveloperHubSDK/Core/Git/GitRebasePlan.swift` | confirmed (2.2.2) |

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

**Decision**: The execution step sets `LC_MESSAGES=C`, and only that
locale variable.
**Rationale**: Callers recognise some refusals by git's text (`not fully
merged`), which a translated git would change. `LC_MESSAGES` moves only the
messages; `LC_ALL` or `LC_CTYPE` would also change how git reads and prints
non-ASCII paths, which must stay the user's.
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
`GitCommandLog` never logs standard output or standard error to OSLog
(its in-memory ring keeps a failed call's standard error, cut and
URL-redacted), and
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
**failed**: all five `GitClientError.errorDescription` strings are hardcoded
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
| 1.2.0 | 2026-11-14 | Mike Fullerton | History model: commit, ref, stash and submodule value types with their format strings and parsers, and the log request; output decoding falls back to Latin-1 per segment; diff, word-diff and blame models with their parsers and C-quoted path unquoting; read verbs (top level, log, refs, stashes, submodules, diff targets and options, blame, file contents) and accepted exit codes in the execution step. Final review: changed files without the patch, literal author and message search, precomposed paths, capped file contents, a named file-history limit. |
| 2.0.0 | 2026-11-14 | Mike Fullerton | Write verbs: the action list and its exact command lines, one perform verb through the execution step with its own budgets (60 s, 600 s for remote verbs and commit) and core.editor=true, the remotes verb and the last commit message. An empty or dash-led ref, remote or commit is refused before anything runs, with a fifth error outcome, invalid-argument (the closed error taxonomy grows, hence major). Push to upstream (remote, branch, upstream branch) without `--set-upstream`; every child runs with `LC_MESSAGES=C`; the push-destination verb (`<branch>@{push}`). Patches from diff lines: a selection of one file's lines, forward and reversed line rules, recomputed hunk headers, the no-newline marker and a one-path file header; apply to the index or the work tree with the patch on standard input, never logged, an empty patch refused. Operations: the operation state (merge, rebase, cherry-pick, revert) read from the files at `rev-parse --git-path`, interactive only when `interactive` exists without `drop_redundant_commits`; merge with its fast-forward rule, rebase, and the continue, abort and skip steps, merge-skip refused before anything runs, every write under `GIT_EDITOR=true`. Conflicts: the seven conflict kinds kept per path, resolve by side and remove paths. Interactive rebase: the plan verb (first-parent, oldest first, merges and empty ranges refused), its validation, the todo with reword as pick plus an amending exec, run from an `adk-rebase` helper folder through `GIT_SEQUENCE_EDITOR` and removed once no operation is left. Worktrees and submodules: add and remove worktree (absolute paths only), locked worktrees, update submodules. Fix round 1: a reword amends only when its pick moved HEAD (reword-amends-only-its-pick, vector 099); every perform that runs removes an idle helper folder. The commit-messages verb: every commit's full message after onto in one `log` call (rebase-plan-messages, vectors 100-101). Residual review: `GIT_OPTIONAL_LOCKS=0` in the child's environment, the conflicted diff target (`--base`, HEAD when there is no base), and a symbolic link as the path's last component may not lead outside (vectors 105, 109). Residual round 2: an added-by-us conflict with nothing against HEAD shows the working file as added, and each conflicted file diff names its old side in `oldRevision` (vector 110). |
| 2.1.0 | 2026-11-16 | Mike Fullerton | Command log: the in-memory ring (500 entries, updates, tool), standard error kept only on failure and never in OSLog, URL user-info redaction. |
| 2.2.0 | 2026-11-16 | Mike Fullerton | Signatures: one `log --no-walk=unsorted` call for a list of shas (15 s budget), the eight `%G?` statuses, the parser and the summary; non-hex shas refused before git runs. |
| 2.2.1 | 2026-11-16 | Mike Fullerton | Signatures fix round 1: `--ignore-missing` and a closing `--`, so a sha the repository lacks is absent instead of failing the batch. |
| 2.2.2 | 2026-11-16 | Mike Fullerton | Phase 4 final review: LFS pointers without a version line in a diff side; an accepted non-zero exit is recorded as failed; `?` and `#` end a URL authority; `undoneEntry`; `hasStagedChanges` and `resetMode` in the undo preflight. |
