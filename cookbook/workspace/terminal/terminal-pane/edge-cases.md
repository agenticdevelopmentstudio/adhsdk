
- **No vault (MUST)**: The private terminal is neither registered nor allowed; the layout offers no entry for it.
- **No plugin manager (MUST)**: The persona terminal chat is neither registered nor allowed.
- **No chat directory (MUST)**: Terminal chats are private to the window.
- **Null browser tools (MUST)**: Persona chats receive no browser tools.
- **Environment clash (MUST)**: The pane's identity variables replace host values of the same name.
- **Environment read late (MUST)**: A bound port or similar value that becomes known after registration reaches panes created afterwards, not panes already open or their running shells.
- **Concurrent access**: The registrations and the family are main-actor isolated and the environment closure is main-actor isolated, so no concurrent use is defined.
- **Offline or disconnected state**: Not applicable: registration does no network access.
- **Boundary values**: Minimum thickness is fixed at 300 and 260 points; no variable range is accepted.
- **Error states**: The only error path is the layout construction in the terminal-only layout, which throws to the caller.

