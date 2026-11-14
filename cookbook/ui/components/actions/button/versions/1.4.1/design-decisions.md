
**Decision**: Split the client boundary; keep `buttonVariants` server-safe.
**Rationale**: The pressed state needs React hooks, but `buttonVariants` must remain a plain server-callable function. So the stateful interactivity lives in a sibling `"use client"` `PressableButton`, and `button.tsx` stays a non-client module that re-exports the variants and renders the client layer.
**Approved**: pending

**Decision**: Drive the pressed visual from `data-pressed`, not CSS `:active`.
**Rationale**: CSS `:active` does not clear when the pointer leaves a held button, so it cannot express "released visual while still armed." Tracking held + pointer-inside in JS and reflecting it via `data-pressed` gives the precise behavior, and matches the `data-[pressed]` token pattern already used elsewhere in the library.
**Approved**: pending

**Decision**: Never call `setPointerCapture`.
**Rationale**: Capture would re-target subsequent pointer events to the button and defeat the leave/re-enter detection; tracking held state plus a window release listener is simpler and reversible.
**Approved**: pending

**Decision**: Keep press feedback subtle and token-only.
**Rationale**: The dip (`translate-y-px`) is kept and a `brightness-95` darken added — variant-agnostic and free of color literals, so it reads as pressed on every variant without per-variant color rules.
**Approved**: pending

**Decision**: `warning` reuses the M3 warning role instead of minting a new alias.
**Rationale**: The variant reads the `apt-orange` role that every theme already defines (exposed by `@adh-sdk/themes`), rather than minting a second color alias — it needs no new token and no per-theme work.
**Approved**: pending

**Decision**: Make the minimum size ancestor-settable instead of prop-drilled.
**Rationale**: `--adh-button-min-height` and `--adh-button-min-width` default to `0px`, so nothing changes anywhere until an ancestor sets them; a surface that needs a bigger hit target (`button.tsx`'s own comments cite shipr's dialogs, where the buttons were reported as too small) sets the pair once on itself and every descendant button grows, whatever its `size` — including buttons nested components render that the surface never names. The alternative was passing `size="lg"` down through every dialog and button bar, which is the same decision made in a hundred places and is why it drifted in the first place. The tradeoff, documented honestly in Accessibility above: the default floor is `0px`, so none of the fixed size variants meet the 44×44pt/48×48dp guidance on their own — a surface MUST opt in.
**Approved**: pending

**Decision**: `icon*` sizes redefine `--adh-button-min-width` rather than emitting a second utility.
**Rationale**: Redefining the variable to the height var (rather than emitting a second `min-w-*` utility) matters because `buttonVariants` is also called bare (`<Link className={buttonVariants()}/>`), where no tailwind-merge runs to resolve two conflicting arbitrary `min-width` utilities — which one would win there is decided by CSS source order, i.e. by nothing anyone can see from the call site.
**Approved**: pending

**Decision**: Make `className` merge precedence a SHOULD, not a MUST.
**Rationale**: `buttonVariants({ variant, size, className })` passes the consumer's `className` through `cva`/`cn`, which is the project's general override convention rather than a rule specific to this component; a valid deviation would be a call site that intentionally does not want overridable classes, which is why it is a SHOULD.
**Approved**: pending

**Decision**: Document the `--adh-button-min-*` / `apt-orange` prefix mismatch as-is rather than normalizing it.
**Rationale**: `--adh-button-min-height`/`--adh-button-min-width` and the `apt-orange` warning-role token both belong to the `@adh-sdk` package family, but use different abbreviated prefixes (`adh` vs `apt`). Reconciling the two is a source-code naming change outside the scope of this recipe pass, so the recipe records the tokens exactly as `button.tsx` and the theme package expose them.
**Approved**: pending

