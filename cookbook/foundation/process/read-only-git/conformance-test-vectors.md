
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| read-only-git-001 | raw-output, trimmed-output (test: testRawGitKeepsWhitespaceThatGitTrimsAway) | In a repo with one unstaged change to `README.md`, args `-C <repo> status --porcelain -unormal --no-renames` | `rawGit` returns ` M README.md\n` (leading space kept); `git` returns `M README.md` |
| read-only-git-002 | trimmed-output | `git(["rev-parse", "--abbrev-ref", "HEAD"])` in a repo on branch `fingerprint-branch` (test: testSampleReportsTheBranchAndACleanTree, through the caller) | `fingerprint-branch`, no newline |
| read-only-git-003 | failure-is-empty, no-throw (test: testSampleReturnsNilOutsideAGitRepository, through the caller) | `git(["rev-parse", "--abbrev-ref", "HEAD"])` in a directory that is not a repository | `""` |
| read-only-git-004 | failure-is-empty | `git(["no-such-subcommand"])` | `""` |
| read-only-git-005 | timeout-is-empty | A `git` that does not answer within 5 seconds (for example an alias or a hook running `sleep 30`) | `""` after about 5 seconds, and the child is stopped |
| read-only-git-006 | path-repaired-missing | `repairedPath(nil)` and `repairedPath("")` | `/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin` for both |
| read-only-git-007 | path-repaired, path-repaired-order | `repairedPath("/opt/homebrew/bin:/custom")` | `/opt/homebrew/bin:/custom:/usr/bin:/bin:/usr/local/bin` |
| read-only-git-008 | path-repaired | `repairedPath("/usr/bin:/bin:/usr/sbin:/sbin")` (a GUI-launched minimal path) | `/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin` |
| read-only-git-009 | optional-locks-off | A `git status` run while another process holds `index.lock` in the same repo | the status call returns output and does not create or fail on `index.lock` |
| read-only-git-010 | optional-locks-off, environment-inherited | The caller's environment has `GIT_OPTIONAL_LOCKS=1` and `GIT_DIR` set | the child sees `GIT_OPTIONAL_LOCKS=0` and the same `GIT_DIR` |
| read-only-git-011 | output-drained | A command printing more than 1 MB (a repo with many branches, `branch --list`) | the full listing is returned and the call does not hang |
| read-only-git-012 | stdout-only | A command that writes to standard error and exits 0 | the standard error text is absent from the result |
| read-only-git-013 | working-directory | `git(["-C", dir, "rev-parse", "--show-toplevel"])` for a repository other than the caller's directory | the top level of `dir` |

