
The repository has no test that names `PrivateTerminalViewController`. The vectors are derived from the source. Unless stated, the vault is a test double whose `authenticate` succeeds and whose `load` returns true with a filter.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| private-terminal-view-controller-001 | session-private, screen-default-up | Create a controller; load its view | The session is private and named "Private Terminal"; the screen is visible, the terminal view hidden, `isRevealed` false. |
| private-terminal-view-controller-002 | reveal-authenticates, reveal-starts-shell, reveal-state-views | Call `reveal()` | The vault is asked with the reason "show the private terminal"; on success the session has the filter and has started; `isRevealed` is true, the screen hidden, the terminal view shown. |
| private-terminal-view-controller-003 | reveal-failure-message | `authenticate` throws "Canceled"; call `reveal()` | `isRevealed` stays false; the message reads "Canceled". |
| private-terminal-view-controller-004 | reveal-no-stack | Call `reveal()` twice before the first authentication ends | The vault is asked once. |
| private-terminal-view-controller-005 | hide-no-auth, reveal-every-time | Reveal, call `hide()`, call `reveal()` | `hide()` asks nothing; the second reveal asks the vault again. |
| private-terminal-view-controller-006 | hide-resigns-focus | Reveal, then hide with the terminal as first responder | The window's first responder becomes nil. |
| private-terminal-view-controller-007 | reveal-focus | Reveal | On the next main-queue turn the terminal view is the first responder. |
| private-terminal-view-controller-008 | screen-message | Shell not started, then started | "Click the eye to start this private terminal." then "Click the eye to show this terminal." |
| private-terminal-view-controller-009 | start-when-visible, started-announces | `viewDidAppear` with words available silently | The session starts with the filter; the screen stays up; the connectable-changed notification posts once. |
| private-terminal-view-controller-010 | start-silent-miss | `load` returns false; appear | The shell is not started; the screen is up. |
| private-terminal-view-controller-011 | start-load-error | `load` throws "Keychain locked"; appear | The message reads "Keychain locked". |
| private-terminal-view-controller-012 | start-once-per-appearance | Appear twice with `load` returning false the first time | `load` is called once. |
| private-terminal-view-controller-013 | words-wait-until-asked | Vault publishes a filter before the pane appears | The shell is not started. |
| private-terminal-view-controller-014 | words-follow-vault, no-notify-on-update | Started shell; the vault publishes a new filter | The session's filter is replaced; no second notification posts. |
| private-terminal-view-controller-015 | accessory-toggle, accessory-refresh | Reveal with the pane as parent | One accessory button titled "Hide the private terminal"; the parent was asked to refresh accessories. |
| private-terminal-view-controller-016 | options-edit-words, edit-words-authenticates | Press Edit Privacy Words | The options dialog is dismissed; the vault is asked with "edit the privacy words"; the editor is presented on the window. |
| private-terminal-view-controller-017 | edit-words-failure-alert | `authenticate` throws "Denied" while pressing Edit | A sheet reads "The privacy words could not be opened." with "Denied". |
| private-terminal-view-controller-018 | connectable-while-running | Session not started, then running, then exited | Nil, the session, nil. |
| private-terminal-view-controller-019 | connect-starts-shell, connect-error-propagates | `startConnectableTerminal()` with the upgrading load succeeding, then throwing | Success returns the running session with the screen still up; the throw propagates to the caller. |
| private-terminal-view-controller-020 | connect-already-started | Shell already started; `startConnectableTerminal()` | Returns the connectable terminal; the vault load is not called. |
| private-terminal-view-controller-021 | teardown-terminates, removal-confirmation | A running session; discard the pane content; read the message | The process is terminated; before that the message is "This pane has a running private terminal session. Removing the pane ends it."; with no running session it is nil. |
| private-terminal-view-controller-022 | conceal-container, eye-accessible | Walk the accessibility tree of the pane | The terminal view is not exposed; the eye is, with the label "Show the private terminal" and identifier `privateTerminal.reveal`. |
| private-terminal-view-controller-023 | appearance-apply, padding-from-theme, pane-spacing-ignored | Change a terminal appearance setting, then apply pane spacing | Padding constants equal the resolved padding; spacing is not read; appearance is applied again each time. |
| private-terminal-view-controller-024 | no-scripting-surface, no-coder-init | Search the pane for an AppleScript object and a URL route; call the coder initializer | None exists; the coder initializer is unavailable. |

