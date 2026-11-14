
- **render-both-sides**: Component MUST render exactly two panels, one for the "them" option and one for the "us" option.
- **render-required-title**: Component MUST render the title from each `VersusSide` as an h3 element.
- **render-optional-lede**: Component MUST render the lede as a paragraph element whenever `lede` is defined (not undefined); this includes an explicitly empty value, since the component checks only presence, not emptiness. See **Design Decisions** for why.
- **render-optional-points**: Component MUST render points as a bullet list only if `points` is defined and has length greater than zero; a defined-but-empty list renders nothing.
- **distinguish-sides**: Component MUST apply a distinguishing visual marker to the "us" panel that differs from the "them" panel, marking "us" as the active/highlighted option.
- **consistent-side-structure**: Both panels MUST produce the same element structure for the same shape of props — "us" and "them" render identically for a given `title`/`lede`/`points` combination.
- **fixed-side-order**: Component MUST render "them" before "us" in reading/DOM order; the order does not adapt to text direction (no right-to-left handling).
- **stack-below-breakpoint**: Component MUST switch from a two-column to a single-column layout when the container is too narrow to fit two columns at their minimum width, stacking "them" above "us".

