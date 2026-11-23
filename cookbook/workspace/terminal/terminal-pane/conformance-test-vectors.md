
The derived tests live in the macOS test bundle as `TerminalPaneFamilyTests`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-pane-001 | family-registers-terminal, allowance-order | Test `testTheBareFamilyIsTerminalsAndTerminalChats`: family with only a vertical axis | Allowance view identifiers are terminal, terminal chat. |
| terminal-pane-002 | family-private-needs-vault, family-persona-needs-plugins, allowance-order, allowances-match-registrations | Test `testTheWholeFamilyAddsPrivateTerminalsAndPersonaChats`: family with plugin manager and privacy vault, vertical axis | Allowance identifiers are terminal, private terminal, terminal chat, persona terminal chat, each with the vertical axis. |
| terminal-pane-003 | allowances-match-registrations, terminal-only-layout | Test `testEveryAllowanceIsRegistered`: register the whole family, then validate a horizontal split with one terminal pane, the allowances and a placeholder against the registry | Validation does not throw. |
| terminal-pane-004 | terminal-view-id, view-id-values | Read the four identifiers' raw values | "terminal", "terminal-chat", "persona-terminal-chat", "private-terminal". |
| terminal-pane-005 | pane-environment-variables, pane-environment-wins | Host environment has ADHD_PANE_ID set to X; pane node is N | The shell gets ADHD_PANE_ID equal to N's string and ADKITCHEN_PROJECT equal to the project display name. |
| terminal-pane-006 | environment-late-read | Register with a closure, then change what it returns and open a new terminal pane | The new pane's shell sees the changed value; a shell in a pane opened before the change does not. |
| terminal-pane-007 | terminal-opens-live, terminal-working-directory, terminal-no-session-list | Create a terminal pane for a context with a working directory | One live shell session is already open in that directory and no session list is shown. |
| terminal-pane-008 | terminal-descriptor, private-terminal-descriptor, terminal-chat-descriptor, persona-chat-descriptor | Read each registered descriptor | Names, symbols, axes and minimum thicknesses as listed in the requirements. |
| terminal-pane-009 | terminal-chat-listing, terminal-chat-state-store, terminal-chat-directory-optional | Create a terminal chat pane with no directory | The chat is created with prefix "terminalChat" state and a listing with the node-derived identifier, project name, directory and pane number; it is not listed anywhere. |
| terminal-pane-010 | persona-chat-creation, private-terminal-vault | Create a persona chat and a private terminal | Persona chat receives plugin manager, browser tools and node identifier; private terminal receives vault and working directory. |
| terminal-pane-011 | terminal-only-layout, terminal-only-axis, terminal-only-throws | Build the terminal-only layout | A horizontal split with one terminal pane and the family's allowances plus a placeholder; a construction failure propagates. |

