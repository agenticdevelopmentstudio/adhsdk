
The source has no tests beside it, and the package's tests do not reference
`ProjectWindowKeyCommands`; the vectors are derived from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| keycmd-001 | section-title, section-scope-app, section-window-specific | Call `section()` | Title `Project Window`, app scope, window specific |
| keycmd-002 | section-two-commands-ordered, browser-command-id, browser-command-title, browser-command-shortcut | Read command 0 | id `projects.toggleBrowser`, title `Show Project Browser`, shortcut Command-0 |
| keycmd-003 | active-command-id, active-command-title, active-command-shortcut | Read command 1 | id `projects.toggleActiveProjects`, title `Show Active Projects`, shortcut Command-1 |
| keycmd-004 | perform-on-project-window, browser-command-targets-browser-panel | Key window's controller is a project shelf window; run command 0 | Window receives the `browser` panel toggle once; returns `true` |
| keycmd-005 | perform-on-project-window, active-command-targets-active-panel | Same window; run command 1 | Window receives the `activeProjects` toggle; returns `true` |
| keycmd-006 | decline-elsewhere, decline-is-logged | Key window is the Conversations window; run command 0 | Returns `false`; no toggle; debug entry says `browser toggle declined: key window is <title>` |
| keycmd-007 | decline-elsewhere, decline-is-logged | No command window; run command 1 | Returns `false`; debug entry says `activeProjects toggle declined: key window is none` |
| keycmd-008 | window-resolved-at-run, section-needs-no-window | Build the section with no windows; then make a project window key; run command 0 | Section builds without a window; the command then toggles that window |
| keycmd-009 | window-resolved-at-run | Run command 0 with window A key, then with window B key | Each run toggles the window that is key at that moment |
| keycmd-010 | main-actor-isolated | Call `section()` and run a command from a main-actor test | Compiles and runs on the main actor; a call from elsewhere requires a hop |

