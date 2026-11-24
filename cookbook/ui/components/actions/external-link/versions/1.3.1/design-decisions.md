
- **Decision**: Bake `target="_blank"` and `rel="noopener noreferrer"` into the
  component rather than leaving them to the caller.
  **Rationale**: Every external jump-out is reverse-tabnabbing-safe by
  construction — the common mistake of a caller forgetting the safe attributes
  is centralised away.
  **Approved**: pending
- **Decision**: Ship one default skin (small mono info-blue deep-link grammar)
  and let consumers restyle via a `cn()`-merged `className` instead of adding
  variant props.
  **Rationale**: The deep-link grammar is the dominant use, so it is the
  default; anything else (UserCard's sans muted social links) is an override
  rather than a variant — keeping the component a thin anchor.
  **Approved**: pending
- **Decision**: Expose the trailing `↗` as a boolean (`glyph`), not a slot, on
  by default and dropped with `glyph={false}` when a leading icon already
  signals "external".
  **Rationale**: The trailing arrow is the one affordance most links want;
  a boolean avoids two arrows when a leading icon already carries the meaning.
  **Approved**: pending
- **Decision**: Mark the `↗` glyph `aria-hidden="true"`.
  **Rationale**: The arrow is a visual affordance, not content, so the
  accessible name stays the label.
  **Approved**: pending
- **Decision**: Set `target` and `rel` *after* spreading `...props`, not
  before.
  **Rationale**: This guarantees the safe defaults win over any
  caller-supplied `target`/`rel` (see **safe-attrs-not-overridable**), so the
  reverse-tabnabbing hole cannot be reopened by props.
  **Approved**: pending

