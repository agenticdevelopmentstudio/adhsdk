
- **Null / empty input**: A missing or empty command is refused (MUST). Empty arguments on wait and interrupt are fine (MUST).
- **Boundary values**: A very long command is passed through to the session unchanged.
- **Concurrent access**: The closure is awaited on the main actor on each call; two tool calls at once each look up the chat and the session ends the earlier wait when a new one begins.
- **Error states**: Missing chat, malformed or empty command and unknown tool each return an error result rather than throwing (MUST).
- **Offline / disconnected state**: Not applicable: the channel is a local terminal, not a network. A session with no terminal answers with its own not-connected text, which is returned as a non-error (MUST).
- **Chat closed mid-turn**: A later call finds no chat and returns the missing-chat error (MUST).
- **Private terminal**: The persona sees privacy words in replies, and what it types is translated on the way in by the terminal, not by this source (MUST).

