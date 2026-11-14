
- **Null mode or missing prop**: Not applicable. Component interface requires `mode` to be one of three specific values; type safety enforces this in TypeScript.
- **Null onChange or missing prop**: Not applicable. Component interface requires `onChange` to be a callback function; the component must be used with both props provided.
- **System preference changes during auto mode**: When mode is "auto", component MUST subscribe to the `change` event on the matchMedia query and update the resolved effective mode. No prop change from parent is required; the update happens internally via `useSyncExternalStore`.
- **matchMedia not available (SSR/server context)**: Component MUST treat system dark mode as `false` and must not throw. The `getServerSystemDark()` function returns false on server.
- **matchMedia available but event support missing (legacy Safari < 14)**: Component MUST proactively check for `addEventListener` support on the MediaQueryList object. If unavailable, the component MUST return an empty unsubscribe function and continue rendering.
- **Rapid successive clicks**: Each click calls `onChange` with the next mode in the cycle. The parent is responsible for debouncing or managing state; the component imposes no rate limits.
- **Component unmounts while system preference listener is active**: The `useSyncExternalStore` subscription cleanup (returned unsubscribe function) MUST properly remove the event listener.
- **Hydration mismatch**: The component uses `mounted` state to prevent hydration mismatches. Server-side and on the client's first render, `aria-label` is set to the placeholder `"Theme"` and `title` is omitted (`undefined`). After the `mounted` effect runs, the real labels populate without re-rendering the HTML structure.

