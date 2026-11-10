
- **Decision**: Headline precedence is `title` > `noun` > `listTitle` > the fully generic default.
  **Rationale**: The hierarchy allows maximum flexibility — a custom title can override computed headlines entirely, while the noun provides specificity. This design prioritizes application control over component magic.
  **Approved**: pending

- **Decision**: The suffix " to view or edit it here." is appended to computed headlines only when no `children` are provided.
  **Rationale**: When descriptive copy is present, the suffix is omitted to avoid redundant messaging and keep the interface concise.
  **Approved**: pending

- **Decision**: The mouse-pointer icon is marked `aria-hidden` and conveys no essential information beyond visual guidance.
  **Rationale**: The icon is semantically decorative; marking it `aria-hidden` prevents assistive technology from announcing it redundantly with the headline text.
  **Approved**: pending

- **Decision**: When the list is empty (`selectable=false`), the computed headline is hidden; an explicit `title` still renders regardless of `selectable`.
  **Rationale**: There is nothing to select in an empty list, so the automatic call-to-action headline is suppressed, while the optional `children` prop still allows explanatory text (e.g., "No workspaces yet. Create one to get started.") without a false call to action.
  **Approved**: pending

- **Decision**: The Card is constrained to a maximum width of 448px (`max-w-md`).
  **Rationale**: This keeps the component readable and prevents it from sprawling on very wide screens; it is a responsive affordance, not a hard constraint.
  **Approved**: pending

- **Decision**: All appearance properties (colors, sizes, spacing) are expressed as Tailwind classes and `apt-*` semantic tokens.
  **Rationale**: This makes the component portable to any Tailwind-configured project; the design tokens (`apt-border`, `apt-surface`, `apt-text`, `apt-text-dim`, `apt-text-muted`) must be defined in the host project's Tailwind config.
  **Approved**: pending

