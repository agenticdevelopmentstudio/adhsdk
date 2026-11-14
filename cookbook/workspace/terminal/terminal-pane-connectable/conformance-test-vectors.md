
No test in the repository targets this contract directly; the vectors below are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-connectable-001 | terminal-content-selected-session, connectable-terminal | Terminal pane content whose session manager has a running selected session | The property returns that session. |
| terminal-connectable-002 | terminal-content-running-only | Selected session exists but is not running | The property returns nothing. |
| terminal-connectable-003 | terminal-content-selected-session | Session manager has no selected session | The property returns nothing. |
| terminal-connectable-004 | default-start, terminal-content-default-start | Call the start on terminal pane content with a stopped selected session | It returns nothing and starts no session. |
| terminal-connectable-005 | default-start | Call the start on a conforming type that does not implement it, whose property returns a session S | The start returns S. |
| terminal-connectable-006 | start-connectable-terminal | A conforming type whose terminal is not started; call the start | It starts the terminal and returns its session. |
| terminal-connectable-007 | start-may-throw | A conforming type whose start throws | The caller receives the error. |
| terminal-connectable-008 | notification-name, change-notification | Observe notifications named "TerminalPaneConnectableDidChange" while a pane's terminal starts | The notification arrives with the pane content as its object. |
| terminal-connectable-009 | session-only | A connecting pane connects to private terminal content | It receives only a terminal session and uses no private-specific API. |
| terminal-connectable-010 | private-terminal-posts-change | Private terminal content whose session starts for the first time after its privacy words load | One notification named "TerminalPaneConnectableDidChange" is posted with that content as its object; a later privacy-words update on an already-started session posts none. The same single notification is posted when a connection's start call loads the words and starts the session. |

