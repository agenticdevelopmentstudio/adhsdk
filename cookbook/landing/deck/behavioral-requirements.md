
- **render-children**: Deck MUST render its child content as direct descendants of its root container.
- **no-own-scroll**: Deck MUST NOT scroll itself or constrain its own height or overflow, leaving the document to handle scrolling.
- **merges-style-hook**: Deck MUST apply its own base style hook and merge it with any consumer-supplied style hook, ignoring absent or empty consumer values before combining them.
- **focusable-not-tabbable**: Deck MUST be focusable programmatically (e.g. by a click inside it) while being excluded from the default sequential tab order.
- **not-a-landmark**: Deck MUST NOT expose a semantic landmark role of its own, since it is designed to sit inside a host shell that already provides the page's main landmark.
- **document-gate**: The root container MUST carry its base style hook for as long as Deck is mounted, because the document-level layout rules depend on it: the stylesheet turns on the root type size, the horizontal clip, a stable scrollbar gutter and, once the host's script arms it, mandatory vertical scroll snapping, all keyed on that hook being present in the document. Renaming or dropping the hook silently turns those off. The script that arms snapping is the [adhsdk.ingredient.landing.deck.deck-script](cookbook:e16d896e-9318-48ac-bf1e-b48ef648d73c) ingredient.
