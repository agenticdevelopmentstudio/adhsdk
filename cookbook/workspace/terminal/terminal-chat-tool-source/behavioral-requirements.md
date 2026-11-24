
- **tool-names**: The three tools MUST be named `run_terminal_command`, `wait_for_terminal_output` and `interrupt_terminal`.
- **definitions-all**: `toolDefinitions()` MUST return all three definitions on every call, in the order run, wait, interrupt, whether or not a Terminal Chat is connected.
- **run-definition**: The run tool's definition MUST describe typing a command into the user's terminal and pressing Return, returning what the terminal printed until it went quiet including the following shell prompt, and MUST tell the model that some names in the output are pseudonyms to be used as given because they are translated on the way in.
- **run-schema**: The run tool's schema MUST be an object with one required string property `command`, described as the command line to run.
- **wait-definition**: The wait tool's definition MUST describe waiting for more output from a command still running when the run tool returned, and its schema MUST be an object with no properties and none required.
- **interrupt-definition**: The interrupt tool's definition MUST describe sending Control-C to stop the running command and returning what it printed, and its schema MUST be an object with no properties and none required.
- **resolve-per-call**: `callTool` MUST look up the Terminal Chat through the supplied closure on every call, on the main actor, and MUST NOT keep the result.
- **no-chat**: When the closure answers nil, every tool call MUST return an error whose content asks the user to add a Terminal Chat pane to the tab and turn on Connect to Terminal Chat in the pane's Settings, and MUST do nothing else.
- **run-call**: A run call MUST pass the command to the session's `run` with its default settle and timeout and return the reply as a non-error.
- **run-needs-command**: A run call whose arguments do not decode as a JSON object, or whose `command` is missing, not a string or empty, MUST return the error `run_terminal_command needs a non-empty "command".` and MUST NOT type anything.
- **wait-call**: A wait call MUST return the session's `waitForOutput` result with its default settle and timeout as a non-error.
- **interrupt-call**: An interrupt call MUST return the session's `interruptAndWait` result with its default settle and interrupt timeout as a non-error.
- **unknown-tool**: A call naming any other tool MUST return the error "Unknown tool: <name>" after the Terminal Chat has been found.
- **no-chat-before-unknown**: The no-Terminal-Chat error MUST be returned before the tool name is checked, so an unknown name with no chat answers with the missing-chat error.
- **ignore-extra-arguments**: Arguments other than `command` on a run call, and any arguments on a wait or interrupt call, MUST be ignored.
- **session-text-passthrough**: The reply text, including a not-connected or still-running line the session produced, MUST be returned unchanged as a non-error; only this source's own failures are errors.
- **sendable**: The source MUST be callable from any task; it holds only the closure, and the closure's work happens on the main actor.
- **separate-concerns-tools**: The source MUST NOT type into a terminal, read a screen or conceal text itself; it only asks the Terminal Chat.

