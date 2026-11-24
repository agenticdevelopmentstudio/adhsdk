
- **Null / empty input**: A `nil` row draws nothing and has zero width.
- **Boundary values**: Lanes only grow, so `lane mod 12` keeps any lane in the palette; a negative lane is reduced into range too.
- **Concurrent access**: Main actor only.
- **Error states**: None: the cell draws whatever row it is given.
- **Offline / disconnected state**: Not applicable: no network.
- **Cancellation**: Not applicable: drawing is synchronous.

