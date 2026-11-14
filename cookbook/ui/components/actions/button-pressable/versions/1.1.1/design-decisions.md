
**Decision**: Requirements are phrased over an **active press** — the interval from a `pointerdown` on the rendered primitive to the earliest of an element-level or window-level `pointerup`/`pointercancel` — rather than over the internal `held` state variable.
**Rationale**: `held` and `pressed` are private `useState` values in `button-pressable.tsx` with no attribute of their own; every requirement that referenced `held` directly (13 of the previous 24) forced its Conformance Test Vector to prove the internal value by indirect inference (e.g. dispatching a window-level release afterward and checking that `data-pressed` still cleared). Anchoring requirements to "active press" — a window defined purely by dispatched events — states the same contract in terms an outside test can observe and drive directly, and keeps `held`/`pressed` as the implementation detail that satisfies it.
**Approved**: pending

**Decision**: Every Behavioral Requirement above is a MUST; none are SHOULD or MAY.
**Rationale**: `button-pressable.tsx` contains no conditional or caller-configurable deviation in its press-tracking logic — every state transition is an unconditional, deterministic response to a specific event, so no permitted alternative behavior exists to write as SHOULD/MAY.
**Approved**: pending

**Decision**: A `window`-level `pointerup`/`pointercancel` listener pair is attached only while an active press is in progress, and torn down as soon as the press resolves (via an element-level release or an earlier window-level release).
**Rationale**: `pointerleave` alone does not end an active press (by design, to support re-entry), so a release or cancel landing outside the element would otherwise leave the press stuck forever; the `useEffect` in `button-pressable.tsx` attaches the `window` listeners only while `held` is `true` and removes them the moment it becomes `false`, so no listener is left attached once the press has resolved. This implementation is what satisfies `#requirements/pressed-cleared-on-window-release-during-active-press` and `#requirements/window-release-no-effect-outside-active-press`.
**Approved**: pending

**Decision**: `button-pressable.tsx` never calls `setPointerCapture`.
**Rationale**: `button-pressable.tsx`'s doc comment on `PressableButton` states this explicitly ("No `setPointerCapture`") — capture would re-target subsequent pointer events to the button and defeat the leave/re-enter detection that the `pointerleave`/`pointerenter` handlers depend on.
**Approved**: pending

**Decision**: Keyboard activation (Space/Enter) never changes the pressed visual.
**Rationale**: `button-pressable.tsx`'s doc comment on `PressableButton` states the pressed visual is "intentionally pointer-only" — Space/Enter activation is left entirely to the underlying Base UI `Button` primitive and never touches `pressed`.
**Approved**: pending

**Decision**: `button-pressable.tsx`'s `compose()` helper invokes the caller-supplied handler (`theirs?.(event)`) before the component's own state update (`ours(event)`) for every intercepted pointer event, but this ordering is not a standalone Behavioral Requirement.
**Rationale**: Both calls happen synchronously within the same event-handler tick, and React defers the actual `data-pressed` DOM mutation regardless of which call ran first, so no outside-observable side effect distinguishes "handler ran first" from "handler ran second" — a black-box Conformance Test Vector cannot prove the ordering (the prior vector 022 read `data-pressed` synchronously inside the spy and passed under both orderings). The ordering is documented here as an implementation fact grounded in `compose()`'s source, not asserted as a testable contract.
**Approved**: pending

**Decision**: Consumer-supplied pointer handlers are composed, never replaced.
**Rationale**: `compose()` in `button-pressable.tsx` always calls the caller's handler before the component's own tracking logic, so passing e.g. `onPointerUp` does not silently disable this component's press tracking, and the component does not silently disable a caller's handler.
**Approved**: pending

**Decision**: This recipe is the single owner of the press-tracking behavioral contract for `button-pressable.tsx`; its atomic, independently-testable requirement decomposition (14 requirements after this pass) is more granular than the sibling [adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0) recipe's compound description of the same source (12 requirements), and `button.md` SHOULD cite this file's `#requirements/...` fragments for press-tracking behavior instead of restating them in its own words.
**Rationale**: Both recipes describe the same underlying source file's pointer-tracking logic independently; the higher count here reflects the behavioral-requirements guideline's prohibition on compound statements, not a completeness gap. Two independent decompositions of the same source drift as the source changes — designating this file as the single owner and having `button.md` reference these fragments removes that duplicate source of truth. (This file cannot edit `button.md` directly; that citation change is `button.md`'s to make.)
**Approved**: pending

**Decision**: `platforms: [web]`, not `[typescript, web]` like sibling recipes.
**Rationale**: [adhsdk.ingredient.ui.components.actions.button](cookbook:f3c25236-d72f-4a7b-839a-b7f335b3acd0) and `copy-button` list both `typescript` and `web`. This recipe was generated from a single specified source-platform set of `web` only, so `platforms` reflects exactly that input rather than inferring `typescript` from the source file's extension.
**Approved**: pending

**Decision**: Add the new tags `pointer-events` and `pressable`.
**Rationale**: The established family vocabulary (`component`, `button`, `ui`) is kept, and these two tags are added because this recipe's scope — the interaction layer alone, apart from `Button`'s visual variants — is not covered by any existing tag in the family.
**Approved**: pending

**Decision**: Appearance, Accessibility (role/label/announce/tap-target), States (Disabled/Focused/Loading), Deep Linking, Localization, Accessibility Options, Feature Flags, and Analytics are marked not applicable, not incomplete.
**Rationale**: `button-pressable.tsx` is purely a pointer-tracking behavior layer; it owns no styling, no ARIA semantics, no routing, no strings, no flags, and no telemetry. Those concerns belong to `button.tsx` (styling) and the Base UI `Button` primitive (semantics), neither of which was provided as source for this recipe.
**Approved**: pending

**Decision**: Keep `title: PressableButton` — the exported symbol name — even though the file is `button-pressable.md`.
**Rationale**: Cookbook file-naming convention requires a kebab-case filename derived from what the component is, while `title` is documented as a human-readable label; sibling recipes (e.g. `Button`/`button.md`) already let the two diverge in case. Noting the export name here avoids ambiguity for a reader who sees only the frontmatter.
**Approved**: pending

