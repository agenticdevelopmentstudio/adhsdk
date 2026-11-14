
- **Null and empty input**: An empty `profileUrl` renders an anchor with an empty `href`; the component has no guard, so it MUST NOT be relied on to hide itself. The host decides: `BitbagChat` renders the button only when `profileUrl` is truthy. An empty `label` renders an empty accessible name and tooltip, which the component does not prevent.
- **Boundary values**: `--pc-pi-size` scales the circle and the glyph together and the component does not clamp it. A `--pc-pi-inset` smaller than half the size pushes part of the circle past the frame's left edge, because nothing clamps it.
- **Concurrent access**: Not applicable: the component is a stateless render with no shared mutable state.
- **Error states**: The component makes no request. If the profile URL is unreachable, the failure appears in the new tab, not in this component.
- **Offline or disconnected state**: Not applicable: nothing is fetched while the component renders; only the newly opened tab needs a connection.
- **Overflow clipping**: If any ancestor within half of `--pc-pi-size` of the frame's top edge clips overflow, the overhanging half is cut off. The host MUST avoid this (see host-placement).
- **Streaming re-renders**: The host chat re-renders on every streamed token while this component's props stay static, so the component SHOULD stay memoized.
- **Unsafe URL schemes**: The component does not validate the URL scheme; it passes `profileUrl` to `href` unchanged, so the host MUST supply a trusted URL.
- **Theme tokens missing**: When the chat theme defines none of the `--pc-*` tokens, the stylesheet's dark-terminal fallbacks apply (see theme-tokens).

