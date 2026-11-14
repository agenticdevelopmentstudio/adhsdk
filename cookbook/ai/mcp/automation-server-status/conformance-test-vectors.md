
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| automation-status-001 | initial-values, line-starting | `AutomationServerStatus()` | `port` nil, `token` nil, `isRegistered` false, `failureReason` nil, `line` is `Starting.`, `url` nil |
| automation-status-002 | line-listening-unregistered, line-port-unformatted | `port = 51477`, `isRegistered = false` | `line` is `Listening on port 51477. Not registered with Claude Code.` (`AutomationSettingsPanelTests.testStatusLineNamesThePortAndRegistration`) |
| automation-status-003 | line-listening-registered | Same instance, then `isRegistered = true` | `line` is `Listening on port 51477. Registered with Claude Code.` (same test) |
| automation-status-004 | line-failure-first | `failureReason = "could not write /x/mcp-token: Permission denied"` with `port` nil | `line` is `Not running: could not write /x/mcp-token: Permission denied` (`AutomationSettingsPanelTests.testFailureReasonIsTheStatusLine`) |
| automation-status-005 | line-failure-first | `port = 51477`, `isRegistered = true`, `failureReason = "x"` | `line` is `Not running: x` |
| automation-status-006 | url-format | `port = 51477` | `url` is `http://127.0.0.1:51477/mcp` |
| automation-status-007 | url-nil-without-port | `port = nil` | `url` is nil |
| automation-status-008 | line-static-for-publisher-values | `AutomationServerStatus.line(port: 8080, isRegistered: true, failureReason: nil)` | `Listening on port 8080. Registered with Claude Code.` |
| automation-status-009 | url-ignores-failure | `port = 51477`, `failureReason = "x"` | `url` is `http://127.0.0.1:51477/mcp` while `line` is `Not running: x` |
| automation-status-010 | no-validation, line-port-unformatted | `AutomationServerStatus.line(port: 0, isRegistered: false, failureReason: nil)` | `Listening on port 0. Not registered with Claude Code.` |
| automation-status-011 | observable-object | Subscribe to `objectWillChange`, then set `port = 1` | One change notification is received before the property reads back as 1 |

