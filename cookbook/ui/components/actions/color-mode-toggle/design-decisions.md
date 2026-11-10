
**Decision**: The component is a controlled control — it receives the current `mode` via a prop and emits change requests via `onChange`; it owns no mode or storage state itself.
**Rationale**: This keeps the component independent of any specific state-management or storage layer, so it can be used in header chrome, sidebars, or settings panels and wired to local storage, a user account, Redux, Zustand, or any other store. The source's own comment explicitly warns against baking in a dependency on a specific theme context.
**Approved**: pending

**Decision**: The mode cycle order (auto → dark → light → auto) is fixed and not configurable.
**Rationale**: Users expect a single toggle button to walk a consistent sequence. The order is encoded in the `NEXT_MODE` map rather than an array walked with modular arithmetic, making every mode's successor total and explicit.
**Approved**: pending

**Decision**: `aria-label`/`title` render placeholder/omitted values until the component mounts on the client, then switch to their real text on the next render.
**Rationale**: Neither value the component needs to word the label correctly is available during server rendering: the `mode` a parent supplies during SSR is often a guess (the true preference commonly lives in a client-only store such as `localStorage`), and even when `mode` is known, resolving `"auto"` requires `window.matchMedia`, which does not exist on the server. Gating on a `mounted` state — `false` on both the server and the client's first render, then `true` after a `useEffect` — guarantees the server and client agree on the placeholder, avoiding a hydration mismatch; the real label then appears on the very next client render. `useSyncExternalStore` is a separate mechanism: it supplies the resolved system-dark value once mounted so that value itself doesn't render wrong then correct in an effect, but it does not control when the label text appears.
**Approved**: pending

**Decision**: The component reads `prefers-color-scheme: dark` through `useSyncExternalStore`, not `useState` + `useEffect`.
**Rationale**: `useSyncExternalStore` is React's designated pattern for subscribing to a store outside React's own state (here, `window.matchMedia`). It gives the first client render the correct value immediately, rather than rendering with a wrong value and correcting it in a later effect.
**Approved**: pending

**Decision**: The component applies no styles of its own beyond one structural class (`adh-color-mode-toggle`, plus any host `className`) and three icon-part classes; all colors, sizing, and icon-visibility rules live in CSS.
**Rationale**: This lets a host fully restyle the button and its icons — including the host's own button identity via `className` — without forking the component per design system. Correctness depends on that CSS: `.adh-color-mode-toggle__*` in `styles/components.css` is what actually decides which icon, and the auto-mode badge, is visible, so that stylesheet is a required runtime dependency of this component, not an optional layer the host may omit.
**Approved**: pending

**Decision**: On a `MediaQueryList` without `addEventListener` (Safari < 14, which shipped only the legacy `addListener`/`removeListener`), the component returns a no-op unsubscribe and renders using `mode` alone, without system-preference tracking, rather than falling back to `addListener`.
**Rationale**: The check probes for the modern API rather than assuming it, for the same reason the host's own appearance store does. Supporting the legacy `addListener` path would mean carrying and testing a second, deprecated subscription mechanism for a browser version past its support window; the component instead degrades gracefully to a static `mode`-only render, keeping the subscription logic to one code path.
**Approved**: pending

**Decision**: `ColorModeToggle` and the separate [adhsdk.ingredient.controls.appearance-mode-toggle](cookbook:46e077a8-1171-4564-9781-7997ff76813a) ingredient are not merged, despite both being a three-state (auto/dark/light) cycling icon button.
**Rationale**: They bind to two different, incompatible document contracts. This component's CSS reads `data-color-mode`/`.dark` on `<html>`, driven by a controlled `mode` prop and the family's own appearance store. `AppearanceModeToggle` reads `data-appearance-mode` and dispatches an `awt:appearance-cycle` custom event for a separate, legacy appearance system still used by one demo site. Merging them would change that site's live document contract, not just its markup, so they stay separate until that site migrates.
**Approved**: pending

