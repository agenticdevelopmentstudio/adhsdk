
- **render-children**: Deck MUST render its child content as direct descendants of its root container.
- **no-own-scroll**: Deck MUST NOT scroll itself or constrain its own height or overflow, leaving the document to handle scrolling.
- **merges-style-hook**: Deck MUST apply its own base style hook and merge it with any consumer-supplied style hook, filtering out falsy values before combining them.
- **focusable-not-tabbable**: Deck MUST be focusable programmatically (e.g. by a click inside it) while being excluded from the default sequential tab order.
- **not-a-landmark**: Deck MUST NOT expose a semantic landmark role of its own, since it is designed to sit inside a host shell that already provides the page's main landmark.

