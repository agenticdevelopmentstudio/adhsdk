
- **Null and empty input**: No stored keys means no provider, Connect off and the
  default persona (MUST). A blank or default-equal persona removes the key
  (MUST). `None` removes `configurationID` (MUST). A missing base URL is treated
  as an empty string for the live fetch.
- **Boundary values**: The persona field is at least 360 points wide and 110
  points high; the container starts at 360 by 500 (MUST).
- **Stale references**: A stored provider id that no longer exists acts as no
  provider (MUST). A stored model override not in the list is added to the
  list so it stays selectable (MUST), and is cleared when the provider changes
  (MUST).
- **Concurrent access**: The controller is main-actor isolated, and its session
  closures hop to the main actor to read settings. A model fetch runs as a
  background task and applies its result on the main actor only if not
  cancelled; a newer refill cancels the older fetch, so a late result from a
  previous provider is dropped (MUST).
- **Error states**: A live-model fetch that fails or is empty keeps the template list
  (MUST) with no message. A plugin that fails to load yields no plugin and no log; the
  session then fails the turn with `No AI provider is configured.` (`plugin-load-failure-silent`). Edits to the
  persona are never validated.
- **Offline or disconnected state**: With no network the live fetch returns nothing
  and the template list stays (MUST); the chat turn's own failure handling
  belongs to the session. The "disconnected" status refers to the Terminal Chat
  link, which is covered under Status.
- **View not loaded**: Applying the status before `loadView` does nothing (MUST).

