
| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-24 | Mike Fullerton | Initial creation |
| 1.0.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: removed source line-number citations; recipes cite files and symbols, not lines. |
| 1.0.2 | 2026-09-25 | Mike Fullerton | Moved into the library cookbook; added Reference Implementations. |
| 1.1.0 | 2026-09-27 | Mike Fullerton | Platform-neutral description; platform specifics in Platform Notes; moved to foundation/git/. |
| 1.2.0 | 2026-11-14 | Mike Fullerton | History model: commit, ref, stash and submodule value types with their format strings and parsers, and the log request; output decoding falls back to Latin-1 per segment; diff, word-diff and blame models with their parsers and C-quoted path unquoting; read verbs (top level, log, refs, stashes, submodules, diff targets and options, blame, file contents) and accepted exit codes in the execution step. Final review: changed files without the patch, literal author and message search, precomposed paths, capped file contents, a named file-history limit. |
| 2.0.0 | 2026-11-14 | Mike Fullerton | Write verbs: the action list and its exact command lines, one perform verb through the execution step with its own budgets (60 s, 600 s for remote verbs and commit) and core.editor=true, the remotes verb and the last commit message. An empty or dash-led ref, remote or commit is refused before anything runs, with a fifth error outcome, invalid-argument (the closed error taxonomy grows, hence major). Push to upstream (remote, branch, upstream branch) without `--set-upstream`; every child runs with `LC_MESSAGES=C`; the push-destination verb (`<branch>@{push}`). |
