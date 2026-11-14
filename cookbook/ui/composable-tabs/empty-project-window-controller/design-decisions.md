
- **Decision**: Make the empty window wear the same chrome as a project window: seamless title bar, shelf and toggle, and the pane backdrop color.
  **Rationale**: The doc comment states it is a project window in every way that shows, so choosing a project in its shelf swaps the project's window in without anything visibly moving.
  **Approved**: pending

- **Decision**: Read the placement template when the window loads, and size and cascade the window before it is shown.
  **Rationale**: The doc comment states a window shown at the default and then moved shrinks and regrows in front of the user.
  **Approved**: pending

- **Decision**: Send `cascadeTopLeft(from:)` to the new window twice, first with the template's top-left corner and then with the point the first call answers.
  **Rationale**: The source comment states the first call puts the window's top-left on the template's and answers the next cascade step, and the second moves it there; the call is sent to the window being placed because it is the one that moves, and it keeps the window on screen however many times New is chosen.
  **Approved**: pending

- **Decision**: Keep a strong reference to the toolbar delegate in a lazy property.
  **Rationale**: The source comment gives the reason: `NSToolbar.delegate` is weak.
  **Approved**: pending

- **Decision**: Land a shelf slide in flight before reading the shelf layout for a swap.
  **Rationale**: The protocol comment states that otherwise the layout handed over would carry a half-slid width and the slide would land later on a window already ordered out.
  **Approved**: pending

- **Decision**: Open the shelf on its browser panel with keyboard focus in the filter when choosing.
  **Rationale**: The doc comment states a new window has nothing in it but the question of which project to load.
  **Approved**: pending

