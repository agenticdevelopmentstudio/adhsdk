
No test in the repository exercises this controller directly; the vectors below are derived from the source's code paths.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-chat-001 | chat-surface, initial-size, interrupt-enabled | Create the controller and load its view | A 360 by 500 container holds one chat view pinned to all four edges, with the interrupt control enabled. |
| terminal-chat-002 | composer-gated, composer-prompt, status-not-connected | Load the view with no remembered pane | Composer disabled, no prompt, status "Not connected — click the link to choose a terminal". |
| terminal-chat-003 | connect-running-terminal, composer-gated, composer-prompt, status-cleared-when-connected, connection-remembered | Connect to a pane whose connectable terminal is running | Session connected at once; composer enabled with "$"; status cleared; "connectedPane" holds that pane's UUID string. |
| terminal-chat-004 | connect-starts-terminal, status-starting | Connect to a pane with no terminal yet | Status "Starting the terminal…" until the start finishes, then the session connects to the started terminal. |
| terminal-chat-005 | status-start-failed | The pane's start throws an error | Status "The terminal could not start: " plus the error's description; composer stays disabled. |
| terminal-chat-006 | single-start | Connect to the same unstarted pane twice while its start is in flight | Only one start is requested. |
| terminal-chat-007 | start-superseded | Start pane A, choose pane B before A finishes, then A finishes | The session does not connect to A's result; the connection is re-made to B. |
| terminal-chat-008 | start-nil-result, status-remembered-unavailable | A start returns no terminal | Session unconnected; status "Its terminal isn't available yet — or click the link to choose another". |
| terminal-chat-009 | reconnect-on-appear, reconnect-needs-pane | View appears with a remembered node identifier that matches no pane in the tab | Connection state refreshed; nothing started; remembered-unavailable status. |
| terminal-chat-010 | reconnect-on-change | Unconnected, in a window, and a connectable-terminal-changed notification arrives | The remembered connection is re-made. |
| terminal-chat-011 | reconnect-on-change | Already connected, or no window, and the notification arrives | Nothing happens. |
| terminal-chat-012 | link-title-connected, link-title-reuse, link-accessibility-value | Connected to a pane titled "Server" | Link title and label "Connected to Server — click to disconnect", value "connected", identifier "terminalChat.link". |
| terminal-chat-013 | link-title-disconnected, link-action, picker-dismisses-options, picker-single | Press the link while unconnected, twice quickly | Settings sheet closed and one picker started; the second press puts up no second picker. |
| terminal-chat-014 | link-action, disconnect-confirmation, disconnect-effect, connection-forgotten | Press the link while connected and click Disconnect | Sheet "Disconnect from <pane title>?" appears; afterwards the session is unconnected, the remembered identifier is removed, and the chat history remains. |
| terminal-chat-015 | disconnect-confirmation | Press the link while connected and click Cancel | Nothing changes. |
| terminal-chat-016 | disconnect-no-window | Press the link while connected with the view outside any window | No sheet is presented. |
| terminal-chat-017 | picker-pick-connects, picker-released, picker-deferred-start | The picker reports a pick, then finishes | The controller connects to the picked pane and then drops the picker. |
| terminal-chat-018 | terminal-exit-refresh | The terminal's process exits | The controller updates to the unconnected state with the remembered-unavailable status. |
| terminal-chat-019 | options-row | Ask for the pane options rows | One rounded button "Connect to Terminal…" with identifier "terminalChat.options.connect". |
| terminal-chat-020 | directory-listing, teardown | Create with a directory and listing, then discard the pane content | The session is added at creation, then removed, the picker cancelled, the observer removed and the session closed. |

