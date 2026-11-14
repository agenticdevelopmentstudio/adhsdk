
- **connectable-terminal**: A conforming pane MUST report, through its connectable terminal property, the terminal session a connection would type into, or nothing when there is none to offer right now.
- **start-connectable-terminal**: A conforming pane MUST provide an asynchronous start that returns the terminal a connection types into, starting it first if it has not started, or nothing when it cannot be.
- **start-may-throw**: The start MAY fail with an error, which the caller handles.
- **default-start**: WHEN a conforming pane does not implement the start itself, the start MUST return its current connectable terminal, without starting anything.
- **change-notification**: A pane whose connectable terminal changes, such as a terminal that starts after its pane appeared, MUST post the connectable-terminal-changed notification with the pane content as the object.
- **notification-name**: The notification MUST be named "TerminalPaneConnectableDidChange".
- **session-only**: A conforming pane MUST expose only the terminal session to a connecting pane, and MUST NOT require the connecting pane to know whether the terminal is ordinary or private.
- **main-actor**: The contract and its members MUST be used on the main actor and the conforming type MUST be a class.
- **terminal-content-selected-session**: The terminal pane content MUST report as its connectable terminal the selected session of its session manager, and MUST report nothing when there is no selected session.
- **terminal-content-running-only**: The terminal pane content MUST report its selected session only while that session is running, and MUST report nothing when the selected session is not running.
- **terminal-content-default-start**: The terminal pane content MUST use the default start, so connecting to it does not start a stopped session.
- **private-terminal-posts-change**: The private terminal pane content MUST post the connectable-terminal-changed notification, with itself as the object, the first time its session starts, which happens once its privacy words are loaded, whether the pane appeared or a connection asked it to start. It MUST NOT post it when the words are updated on a session that has already started.

