
No test in the repository targets this coordinator; the vectors below are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| terminal-workspace-001 | installs-layout, layout-optional-parts | Create with no plugin manager and no vault | The installed layout offers the terminal and terminal chat panes (plus the placeholder); no private terminal and no persona terminal chat. |
| terminal-workspace-002 | installs-layout | Create when the layout cannot be built | The initializer throws that error. |
| terminal-workspace-003 | attach-database, share-registry | Create the coordinator | The window manager has the database attached and the command registry assigned. |
| terminal-workspace-004 | show-window-command, new-terminal-command | Read the registry after creation | Commands "terminalWorkspace.action.showWindow" ("Terminal Window") and "terminalWorkspace.action.newTerminal" ("New Terminal"), category "Terminal". |
| terminal-workspace-005 | file-menu-new-terminal, file-menu-show-window | Read the menu contributions | File items "New Terminal" (order 0, key t) and "Terminal Window" (order 10, key 1). |
| terminal-workspace-006 | default-directory | Create with no directory | The workspace path is the user's home directory. |
| terminal-workspace-007 | workspace-row-inserted-once | Show the window twice with an empty database | One row, with the supplied name and the directory path, is inserted; the second call reuses it. |
| terminal-workspace-008 | show-window | Show the window while it is open | The existing window is brought forward and no second window opens. |
| terminal-workspace-009 | show-window-failure | The database insert throws | "Cannot open the terminal workspace: " and the error are logged and no window opens. |
| terminal-workspace-010 | new-terminal-open-window | Window open; run New Terminal | A terminal pane is added beside the active pane. |
| terminal-workspace-011 | new-terminal-closed-window | Window closed; run New Terminal | The window opens on its starting terminal and no extra pane is added. |
| terminal-workspace-012 | new-terminal-refusal | Window open and adding the pane returns false | The refusal feedback is announced. |
| terminal-workspace-013 | is-window-open, is-window-open-error | Query with no row, with a row but no window, with both, and with a throwing lookup | False, false, true, false. |
| terminal-workspace-014 | command-weak-self | Release the coordinator, then run a command | Nothing happens. |
| terminal-workspace-015 | window-title | Create with name "Terminals" | The workspace row's name is "Terminals". |

