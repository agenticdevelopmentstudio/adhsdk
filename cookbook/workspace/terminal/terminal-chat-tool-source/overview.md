
`TerminalChatToolSource` is a chat tool source: it advertises tool definitions to a persona's model and runs the calls the model makes. Its three tools let a persona work a terminal: `run_terminal_command` types a command and returns what the terminal printed until it went quiet, `wait_for_terminal_output` returns more output from a command that was still running, and `interrupt_terminal` sends Control-C and returns what the command printed.

The tools reach the terminal through a Terminal Chat session, never the terminal itself. Connected to a private terminal, the persona sees only that terminal's privacy words, never the real ones, because the session reads replies off the terminal's own screen. The Terminal Chat is looked up on every call, by a closure the host supplies, not held, so connecting one after the persona chat opened, or closing it, takes effect on the next tool call. The closure runs on the main actor, where panes live.

The tool names are this source's own. The settle, timeout and interrupt-timeout defaults the calls take are the session's, which reads them from [adhsdk.ingredient.foundation.terminal.terminal-chat-control](cookbook:b71b349b-5c60-41f4-b664-49085ac5d988); the reply text is the session's, and the session the tools call is the Terminal Chat session recipe in this folder.

