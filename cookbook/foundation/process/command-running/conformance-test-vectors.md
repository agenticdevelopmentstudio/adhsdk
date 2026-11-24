
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| command-running-001 | run-result-shape, run-merged-output-order, argv-split, exit-status-passthrough | `run(["/bin/echo", "hi"])` (test: echo returns its output and status 0) | status 0, output `hi\n` |
| command-running-002 | capture-result-shape, capture-streams-apart, capture-environment-inherited, exit-status-passthrough | `capture(["/bin/sh", "-c", "echo out; echo err 1>&2; exit 3"], environment: nil)` (test: capture keeps stdout and stderr apart) | status 3, stdout `out\n`, stderr `err\n` |
| command-running-003 | capture-environment-replacement | `capture(["/usr/bin/env"], environment: ["ONLY_THIS": "1"])` (test: capture replaces the environment) | status 0, stdout exactly `ONLY_THIS=1\n` |
| command-running-004 | path-lookup, run-inherits-environment | `run(["echo", "bare"])` (test: a name without a slash resolves through env) | status 0, output `bare\n` |
| command-running-005 | exit-status-passthrough | `run(["/usr/bin/false"])` (test: false returns a non-zero status) | status is non-zero |
| command-running-006 | stream-draining | `run(["/usr/bin/head", "-c", "200000", "/dev/zero"])` (test: large output is returned in full) | status 0, output holds exactly 200000 UTF-8 bytes |
| command-running-007 | launch-failure | `run(["/nonexistent/definitely-not-here"])` (test: a missing executable fails without crashing) | status -1 and the call returns |
| command-running-008 | backstop-timeout-report, timeout-never-success | `ProcessCommandRunner(backstop: 0.2).run(["/bin/sleep", "30"])` (test: a timed-out run reports failure) | status -1, output ends with `\ntimed out after 0.2s` |
| command-running-009 | capture-default-from-run, capture-overload-default | A double implementing only `run`, returning status 7 and output `a b` for the arguments `a` and `b`; call `capture(["a", "b"])` (test: the default capture is built on run) | status 7, stdout `a b`, stderr empty |
| command-running-010 | empty-command | `run([])` and `capture([], environment: nil)` | `run` gives status -1 and output `empty command`; `capture` gives status -1, empty stdout, stderr `empty command` |
| command-running-011 | path-miss | The lookup on name `nope` with search path `/usr/bin` | returns `nope` unchanged |
| command-running-012 | slash-verbatim | The lookup on name `/bin/echo` with search path `/nonexistent` | returns `/bin/echo` |
| command-running-013 | path-default, path-empty-entries | A temporary directory `D` holding an executable file `tool`; the lookup on name `tool` with search path `::D`; then the lookup on name `sh` with no search path | `D/tool`; then the path of `sh` in the first of `/usr/bin`, `/bin`, `/usr/sbin`, `/sbin` (in that order) that holds an executable `sh` |
| command-running-014 | backstop-timeout-report | `ProcessCommandRunner(backstop: 0.2).capture(["/bin/sh", "-c", "echo before; sleep 30"], environment: nil)` | status -1, stdout `before\n`, stderr ends with `\ntimed out after 0.2s` |
| command-running-015 | utf8-decoding | `run(["/usr/bin/printf", "\\377"])` (one byte that is not valid UTF-8) | status 0, output empty |
| command-running-016 | backstop-default | `ProcessCommandRunner().backstop` | 600 |

The requirements `sendable-seam`, `off-pool-execution`, `stdin-not-supplied` and `no-cancellation` have no vector: they are scheduling and stream-wiring facts that a unit test cannot observe without instrumenting the thread or the child's stdin, and the source has no test for them. A port copies the behavior from the requirement text.

