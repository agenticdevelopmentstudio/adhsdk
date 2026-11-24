**Decision**: Requirements are phrased over an **active press** — the interval from a `pointerdown` on the rendered primitive to the earliest of an element-level or window-level `pointerup`/`pointercancel` — rather than over the internal `held` state variable.
**Rationale**: `held` and `pressed` are private `useState` values in `button-pressable.tsx` with no attribute of their own, so a requirement written over `held` can only be proven by indirect inference (for example, dispatching a window-level release afterward and checking that `data-pressed` still cleared). An "active press" is a window defined purely by dispatched events, so an outside test can observe and drive it directly, and `held`/`pressed` stay the implementation detail that satisfies it.
**Approved**: pending

**Decision**: Every Behavioral Requirement is a MUST; none are SHOULD or MAY.
**Rationale**: `button-pressable.tsx` contains no conditional or caller-configurable deviation in its press-tracking logic — every state transition is an unconditional, deterministic response to a specific event, so no permitted alternative behavior exists to write as SHOULD/MAY.
**Approved**: pending

**Decision**: A `window`-level `pointerup`/`pointercancel` listener pair is attached only while an active press is in progress, and torn down as soon as the press resolves (via an element-level release, an earlier window-level release, or unmount).
**Rationale**: `pointerleave` alone does not end an active press (by design, to support re-entry), so a release or cancel landing outside the element would otherwise leave the press stuck forever; the `useEffect` in `button-pressable.tsx` attaches the `window` listeners only while `held` is `true` and removes them the moment it becomes `false` or the component unmounts, so no listener is left attached once the press has resolved. This implementation is what satisfies `#requirements/pressed-cleared-on-window-release-during-active-press`, `#requirements/window-release-no-effect-outside-active-press` and `#requirements/no-window-listener-after-unmount`.
**Approved**: pending

**Decision**: `button-pressable.tsx` never calls `setPointerCapture`.
**Rationale**: Capture would re-target subsequent pointer events to the button and defeat the leave/re-enter detection that the `pointerleave`/`pointerenter` handlers depend on. The doc comment on `PressableButton` states this explicitly ("No `setPointerCapture`").
**Approved**: pending

**Decision**: Keyboard activation (Space/Enter) never changes the pressed visual.
**Rationale**: The pressed visual is intentionally pointer-only; Space/Enter activation is left entirely to the underlying Base UI `Button` primitive and never touches `pressed`. The doc comment on `PressableButton` states this explicitly.
**Approved**: pending

**Decision**: Consumer-supplied pointer handlers are composed with the component's own tracking, never replaced, and the order in which the two run is not a contract.
**Rationale**: `compose()` in `button-pressable.tsx` calls both the caller's handler and the component's own tracking logic, so passing e.g. `onPointerUp` does not silently disable press tracking and the component does not silently disable a caller's handler. Today `compose()` calls the caller's handler first, but both calls happen synchronously within the same event-handler tick and React defers the actual `data-pressed` DOM mutation regardless of which ran first, so no outside-observable effect distinguishes the two orders and a black-box Conformance Test Vector cannot prove one. A port may run them in either order.
**Approved**: pending

**Decision**: This ingredient is the single owner of the press-tracking behavioral contract for `button-pressable.tsx`; [adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0) depends on it.
**Rationale**: Two independent decompositions of the same source drift as the source changes, so one document owns the contract and the other points to it. The decomposition here is deliberately atomic and independently testable.
**Approved**: pending

**Decision**: `platforms` is `[typescript, web]`, matching [adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0) and `copy-button`.
**Rationale**: The component is written in TypeScript and runs in the browser, so both platform tags apply, and keeping the same pair across the button family lets tooling group them.
**Approved**: pending

**Decision**: Add the tags `pointer-events` and `pressable`.
**Rationale**: The established family vocabulary (`component`, `button`, `ui`) is kept, and these two tags are added because this ingredient's scope — the interaction layer alone, apart from `Button`'s visual variants — is not covered by any existing tag in the family.
**Approved**: pending

**Decision**: Appearance, Accessibility (role/label/announce/tap-target), States (Disabled/Focused/Loading), Deep Linking, Localization, Accessibility Options, Feature Flags, and Analytics are marked not applicable, not incomplete.
**Rationale**: `button-pressable.tsx` is purely a pointer-tracking behavior layer; it owns no styling, no ARIA semantics, no routing, no strings, no flags, and no telemetry. Those concerns belong to `button.tsx` (styling) and the Base UI `Button` primitive (semantics).
**Approved**: pending

**Decision**: Keep `title: PressableButton` — the exported symbol name — even though the file is `button-pressable.md`.
**Rationale**: Cookbook file-naming convention requires a kebab-case filename derived from what the component is, while `title` is documented as a human-readable label; sibling ingredients (e.g. `Button`/`button.md`) already let the two diverge in case. Noting the export name here avoids ambiguity for a reader who sees only the frontmatter.
**Approved**: pending
