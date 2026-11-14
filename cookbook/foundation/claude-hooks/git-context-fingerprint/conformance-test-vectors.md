
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-context-fingerprint-001 | sample-nil-outside-repo | A plain directory; `testSampleReturnsNilOutsideAGitRepository` | `sample` returns nil |
| git-context-fingerprint-002 | sample-fields, sample-branch, sample-clean-tree | A fresh repository with one commit; `testSampleReportsTheBranchAndACleanTree` | The branch name, counts of 0 and the empty-string hash for status |
| git-context-fingerprint-003 | sample-config-pinned | An untracked file added; `testAnUntrackedFileMovesTheStatusHashButNotTheCommitHash` | The status hash changes and the commit hash does not |
| git-context-fingerprint-004 | sample-fields | A new commit; `testANewCommitMovesTheCommitHashButNotTheStatusHash` | The commit hash changes and the status hash does not |
| git-context-fingerprint-005 | sample-status-untrimmed | An unstaged-only change to the first path; `testTheStatusHashCountsPorcelainsLeadingStatusColumn` | The status text keeps its leading space and the hash is of the untrimmed text |
| git-context-fingerprint-006 | sample-status-untrimmed | The raw command helper on output with leading whitespace; `testRawGitKeepsWhitespaceThatGitTrimsAway` | Whitespace is kept by the raw form and trimmed by the plain form |
| git-context-fingerprint-007 | enrich-nesting | A payload with several keys, inside a repository; `testEnrichedNestsTheFingerprintAndKeepsEveryOriginalKey` | Every original key is present and `stenographer_git` holds the fingerprint |
| git-context-fingerprint-008 | enrich-directory | No `cwd`, a `workspace.current_dir`; `testEnrichedFallsBackToTheWorkspaceCurrentDir` | The repository at `current_dir` is sampled |
| git-context-fingerprint-009 | enrich-splice | A payload holding `"hit_ratio":1.0` beside `cwd`; `testEnrichedPreservesTheOriginalBytesOfEveryValue` | The output text still contains `"hit_ratio":1.0` and the output parses with the fingerprint key present |
| git-context-fingerprint-010 | enrich-nesting | `payloadKey`; `testEnrichedNamespacesTheFingerprintSoTheDaemonCanStripIt` | The key has the prefix `stenographer_` (it is `stenographer_git`) |
| git-context-fingerprint-011 | enrich-fallback | The text `not json at all`; `testEnrichedReturnsThePayloadUnchangedWhenItIsNotJSONObject` | Returned byte for byte unchanged |
| git-context-fingerprint-012 | enrich-fallback, sample-nil-outside-repo | A valid payload whose `cwd` is not a repository; `testEnrichedReturnsThePayloadUnchangedOutsideAGitRepository` | Returned byte for byte unchanged |
| git-context-fingerprint-013 | sample-entry-count | A repository with two untracked files | `status_entry_count` is 2, not 3 |
| git-context-fingerprint-014 | sample-sampled-at | Any sample | `sampled_at` matches `^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$` |
| git-context-fingerprint-015 | sample-recent-count | A repository with seven commits | `recent_commits_char_count` is the length of the five newest `--oneline` lines |
| git-context-fingerprint-016 | enrich-empty-object | The payload `{}` inside a repository | The output is `{"stenographer_git":{...}}` with no leading comma and parses |
| git-context-fingerprint-017 | sample-directory-scope | A directory argument other than the process's working directory | The sample describes the repository at that directory |
