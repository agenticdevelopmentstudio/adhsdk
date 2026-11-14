
- SectionLabel renders a plain `div`, **not** a semantic heading (`h1`–`h6`) or
  `role="heading"` — it is a *display* label, so it does not enter the document's
  heading outline. Consumers who need the label in the outline SHOULD supply
  their own heading semantics.
- It carries no interactivity of its own; the `trailing` slot's node (a button,
  say) brings its own accessible name and focus behavior.
- Sufficient for a quiet in-pane label whose associated content follows visually;
  the treatment relies on size/case/tracking, not color alone, to read as a
  heading.
- Rendered at `text-[0.625rem]` (10px) in the dim `apt-text-dim` color token,
  this is small, low-contrast text; it MUST meet WCAG AA's 4.5:1 contrast ratio
  against the pane/card surfaces it appears on (see the `contrast-ratio`
  compliance check below) — the source defines the token but not its resolved
  color, so verify `apt-text-dim` against each surface it is used on.

