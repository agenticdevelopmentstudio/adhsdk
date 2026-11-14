
**Decision**: Shot renders `media` exactly as passed, applying no transformation, processing, or optimization.
**Rationale**: The host (landing or feature page) owns the content strategy — optimizing images, deferring video load, and handling accessibility are the host's responsibility. Shot's responsibility is framing, not transformation.
**Approved**: pending

**Decision**: The placeholder is a mandatory visual state, not an optional one — when `media` is absent, an obviously unfinished frame (diagonal hatch background) renders to prevent shipping an incomplete capture by accident.
**Rationale**: The source JSDoc for `media` states: "Absent renders the placeholder frame — deliberately, obviously unfinished, so one shipped by accident is caught rather than mistaken for a screenshot of a product that looks like that."
**Approved**: pending

**Decision**: The placeholder check is a deliberate `media === undefined`, not a nullish or falsy check.
**Rationale**: A host that passes `media={null}` or `media={false}` has made an explicit choice to render nothing there, and Shot renders `media` verbatim. The cost is that the unfinished-frame safeguard does not catch those values: they leave a bare title bar with no placeholder, so a host that wants the placeholder must leave `media` undefined (`capture ?? undefined`).
**Approved**: pending

**Decision**: The caption in the placeholder is rendered in a `<b>` element that the stylesheet resets to normal weight.
**Rationale**: This is how the source is written, and the `<b>` gives the CSS a hook for the caption. It carries no emphasis meaning, but assistive technology may read it as emphasis, so `semantic-markup` stays partial; a port SHOULD use a plain `<span>` (or its platform's plain text element) instead.
**Approved**: pending

**Decision**: Shot does not apply Reduce Motion handling itself; for autoplaying video or motion-sensitive clips, hosts use the package's `Clip` component or the `usePrefersReducedMotion` hook.
**Rationale**: Keeping motion-preference handling out of Shot lets Shot stay a simple frame while `Clip` (or a host driving its own element) owns the two cooperating halves that reduced-motion handling requires.
**Approved**: pending

