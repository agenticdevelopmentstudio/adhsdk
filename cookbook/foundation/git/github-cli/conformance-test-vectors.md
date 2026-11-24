
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| github-cli-001 | fixed-environment | `availability(in:)` with a stub runner | the runner sees `GH_PROMPT_DISABLED=1`, `NO_COLOR=1`, `GH_NO_UPDATE_NOTIFIER=1` and no `GH_TOKEN` (test: environmentHoldsTheThreeVariables). |
| github-cli-002 | availability-command, budgets | stdout `{"url":"https://github.com/o/r"}` | `.success(https://github.com/o/r)`; arguments `repo view --json url`; 10 s (test: availabilityArgumentsAndAnswer). |
| github-cli-003 | list-command, budgets | `pullRequests(in:)`, then `state: "all", limit: 5` | `pr list --state open --limit 50 --json <fields>`, then `--state all --limit 5`; 10 s (test: pullRequestsArguments). |
| github-cli-004 | view-command | `pullRequest(forBranch: "feature/login")` | `pr list --head feature/login --state all --limit 20 --json <fields>,headRepositoryOwner` (test: pullRequestForBranchArguments). |
| github-cli-005 | checkout-command, budgets | `checkout(42)` | `pr checkout 42`; 60 s (test: checkoutArguments). |
| github-cli-006 | create-command, budgets | `create` without base, then with base `develop` and draft; stdout ends in `https://github.com/o/r/pull/43` | `pr create --title … --body …`, then `… --base develop --draft`; the URL; 60 s (test: createArgumentsAndPrintedURL). |
| github-cli-007 | pull-request-model, check-rollup | a recorded two-pull-request list | #42 with checks 2 passing, 1 failing, 2 pending and `APPROVED`; #41 draft with no checks and no review decision (test: decodesARecordedTwoPullRequestList). |
| github-cli-008 | check-rollup | one `StatusContext` with state `ERROR` | 0 passing, 1 failing, 0 pending (test: pullRequestForBranchDecodesOne). |
| github-cli-009 | error-mapping | stdout `not json` | `failed` (test: unreadableOutputIsFailed). |
| github-cli-010 | error-mapping | stderr containing `gh auth login`, or `NOT LOGGED` | `notAuthenticated` (tests: notLoggedInIsNotAuthenticated, notLoggedIntoHostIsNotAuthenticated). |
| github-cli-011 | error-mapping | gh's whole `none of the git remotes … To tell gh about a new GitHub host, please use `gh auth login``, or `Not a GitHub repository` | `notGitHub`, not `notAuthenticated` (tests: noGitHubRemoteIsNotGitHub, notAGitHubRepositoryIsNotGitHub). |
| github-cli-012 | error-mapping | the runner throws a budget-exceeded error | `timedOut` (test: budgetExceededIsTimedOut). |
| github-cli-013 | error-mapping | stderr `HTTP 502: Bad Gateway (…)` with a trailing newline | `failed` with the trimmed text (test: anythingElseIsFailedWithStandardError). |
| github-cli-014 | view-command | `pr list --head` answers `[]` | nil (test: noPullRequestForBranchIsNil). |
| github-cli-015 | locate-before-spawn | no `gh` on any search directory | `notInstalled`, the runner never called, two entries with no exit status (test: missingBinaryIsNotInstalledWithoutSpawning). |
| github-cli-016 | logged-as-gh | a successful `pr list` | an entry with tool `gh`, arguments `pr list …`, the directory, status 0 and the explicit caller passed (test: entriesAreLoggedWithToolGh). |
| github-cli-017 | logged-as-gh | a failed `repo view`, status 4 | the entry keeps the standard error (test: failedEntryKeepsStandardError). |
| github-cli-018 | text-redacted | `create(title: "Secret title", body: "token abc", base: "main", draft: true)` | logged as `pr create --title <redacted:12> --body <redacted:9> --base main --draft` (test: createTitleAndBodyAreRedactedInTheLog). |
| github-cli-019 | text-redacted | gh `pr view -m`; git `commit --title x` | both unchanged (test: ghRedactionLeavesGitRulesAlone). |
| github-cli-020 | create-command | `create` with base `main`, head `parser` and draft | `pr create --title … --body … --base main --head parser --draft` (test: createPassesTheHeadBranch). |
| github-cli-021 | create-command, input-sanitization | `create` with head `` and with head `-x` | `failed("not a branch name: <head>")`; nothing runs (test: createRefusesAHeadThatIsNotABranchName). |
| github-cli-020 | view-command | `pullRequest(forBranch: \"4521\")` | `pr list --head 4521 --state all --limit 20 --json …`, never `pr view 4521` (test: numericBranchNameIsLookedUpAsAHead). |
| github-cli-021 | error-mapping | stderr `no git remotes found`; stderr `No default remote repository has been set. …` | `notGitHub` (tests: noRemotesIsNotGitHub, noDefaultRemoteIsNotGitHub). |
| github-cli-022 | view-command | branch `main`: a stranger's newest open fork PR #90, this repository's merged #80 and older open #70 | #70: the fork row dropped, open preferred over newer (test: forkPullRequestWithTheSameBranchNameIsSkipped). |
| github-cli-023 | view-command | only a fork PR with the branch's name | nil (test: onlyForkPullRequestsIsNil). |
| github-cli-024 | view-command | closed #5 (Nov 1) and merged #6 (Nov 10), none open | #6 (test: withNoOpenPullRequestTheNewestWins). |

