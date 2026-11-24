
**Decision**: Shot renders `media` exactly as passed, applying no transformation, processing, or optimization.
**Rationale**: The host (landing or feature page) owns the content strategy — optimizing images, deferring video load, and handling accessibility are the host's responsibility. Shot's responsibility is framing, not transformation.
**Approved**: pending

**Decision**: The placeholder is a mandatory visual state, not an optional one — when `media` is absent, an obviously unfinished frame (diagonal hatch background) renders to prevent shipping an incomplete capture by accident.
**Rationale**: The source JSDoc for `media` states: "Absent renders the placeholder frame — deliberately, obviously unfinished, so one shipped by accident is caught rather than mistaken for a screenshot of a product that looks like that."
**Approved**: pending

**Decision**: Shot does not apply Reduce Motion handling itself; for autoplaying video or motion-sensitive clips, hosts use the package's `Clip` component or the `usePrefersReducedMotion` hook.
**Rationale**: Keeping motion-preference handling out of Shot lets Shot stay a simple frame while `Clip` (or a host driving its own element) owns the two cooperating halves that reduced-motion handling requires.
**Approved**: pending

