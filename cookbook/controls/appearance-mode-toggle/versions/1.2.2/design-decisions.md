
**Three-mode cycle**

**Decision**: The component cycles through three appearance modes in the fixed order auto → dark → light → auto.
**Rationale**: Users may want to override the system preference (light or dark) or defer to it (auto). This order is fixed by the label generation logic (see **set-aria-label**) and by the event contract described in External appearance controller below — the external controller that owns mode state MUST advance through this same order when it receives the cycle event.
**Approved**: pending

**External appearance controller**

**Decision**: The component does not manage appearance state itself. It dispatches an `awt:appearance-cycle` `CustomEvent` on `window` (no `detail` payload) when clicked, and listens for an `awt:appearance-changed` `CustomEvent` on `window` (also no `detail` payload) to know when to re-read `document.documentElement`.
**Rationale**: This keeps the toggle decoupled from any specific state-storage mechanism, so any controller that writes `data-appearance-mode` and the `dark` class and honors this event contract can drive it — for example `ColorModeProvider`/`useColorMode` in `packages/web/packages/themes/src/colorMode.tsx`, which implements this exact contract for a different toggle in this toolkit.
**Approved**: pending

**Event-driven state updates**

**Decision**: State does not poll `document` for changes; it listens for the `awt:appearance-changed` event described in External appearance controller above.
**Rationale**: This decouples the component from the mechanism that changes appearance and allows multiple components and external systems to stay in sync without tight coupling.
**Approved**: pending

**Aria-label format**

**Decision**: Labels include both the current mode and the next expected action.
**Rationale**: Users in auto mode need to know what "currently" means (light or dark) to understand what will happen on click. The next-state hint (e.g., "click to switch to dark") helps predictability.
**Approved**: pending

**No built-in styling**

**Decision**: The component itself (`AppearanceModeToggle.tsx`) sets no inline styling and specifies no padding, corner radius, or colors in code; instead it ships an optional, separately-published stylesheet (`appearance-mode-toggle.css`) keyed to its class names, and accepts `className` to integrate with any CSS framework.
**Rationale**: A consumer can import the default stylesheet for padding, radius, colors, a hover transition, and a focus ring out of the box, or skip it and style the native button entirely from their own CSS — either way, button size and appearance are delegated to CSS, not hardcoded in the component.
**Approved**: pending

**Hydration safety**

**Decision**: Component defaults to `auto` mode and `light` resolved appearance during server-side rendering.
**Rationale**: The server has no access to `document`, so it cannot know the real mode or resolved appearance; `auto`/`light` is the fixed, deterministic fallback the source returns only in that no-`document` case, not a claim about which state is most common among users. This does not defer the real read until after the client mounts: the client's first (hydrating) render runs the same `useState` lazy initializer against the live `document`, so if a pre-hydration script has already changed the appearance, that render's output can differ from the server's `auto`/`light` markup — an attribute-only mismatch (icon path, `aria-label`, `title`) that React does not patch during hydration, and that persists until the next `awt:appearance-changed` event.
**Approved**: pending

