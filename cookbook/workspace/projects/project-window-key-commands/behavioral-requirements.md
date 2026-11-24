
- **section-title**: `section()` MUST return a section titled `Project Window`.
- **section-scope-app**: The section MUST have app scope.
- **section-window-specific**: The section MUST be marked window specific
  (`isWindowSpecific` true), because each command declines unless a project
  window is key.
- **section-two-commands-ordered**: The section MUST hold exactly two commands, in
  this order: the browser toggle, then the active-projects toggle.
- **browser-command-id**: The first command's id MUST be `projects.toggleBrowser`,
  exposed as `toggleBrowserID`.
- **browser-command-title**: The first command's title MUST be `Show Project Browser`.
- **browser-command-shortcut**: The first command's default shortcut MUST be
  Command plus the 0 key.
- **active-command-id**: The second command's id MUST be
  `projects.toggleActiveProjects`, exposed as `toggleActiveProjectsID`.
- **active-command-title**: The second command's title MUST be `Show Active Projects`.
- **active-command-shortcut**: The second command's default shortcut MUST be Command
  plus the 1 key.
- **browser-command-targets-browser-panel**: Running the first command MUST toggle
  the `browser` panel.
- **active-command-targets-active-panel**: Running the second command MUST toggle the
  `activeProjects` panel.
- **window-resolved-at-run**: The target window MUST be resolved each time a command
  runs, from the registry's command window (the window the keystroke was sent
  to, otherwise the key window; a child window answers with the window it is
  attached to), and not captured when the section is built.
- **section-needs-no-window**: `section()` MUST NOT require a project window to exist.
- **perform-on-project-window**: When the command window's controller is a project
  shelf window, the command MUST call that window's panel toggle with the
  command's panel and MUST return `true`.
- **decline-elsewhere**: When there is no command window, or its controller is not a
  project shelf window, the command MUST NOT toggle anything and MUST return
  `false`, so the chord may fall to another window's command.
- **decline-is-logged**: A declined command MUST write one debug log entry that names
  the panel raw value and the key window's title, or `none` when there is no
  command window.
- **toggle-semantics-owned-elsewhere**: Whether the toggle shows the shelf on the panel,
  moves the keyboard to the filter, or hides the shelf is performed by the
  window's panel toggle, not by this component; the contract stated for it in
  the source comment is: show the shelf on that panel with the keyboard in its
  filter, or hide it when that panel is already up.
- **main-actor-isolated**: The namespace and its command closures MUST run on the main
  actor.
- **chords-rebindable**: The shortcuts are defaults of bindable commands
  (`defaultShortcut`); this component MUST NOT hard-wire the keys beyond that
  default.

