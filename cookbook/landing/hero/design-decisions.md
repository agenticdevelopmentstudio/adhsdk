
- **Decision**: `mark` is accepted as a `ReactNode` rather than a file path or URL.
  **Rationale**: Defers image loading and styling to the host, avoiding a hard dependency on `next/image`.
  **Approved**: pending

- **Decision**: The component renders as a non-semantic `<div>` (via `Screen as="div"`), not a `<section>`. (root-is-non-semantic)
  **Rationale**: A `<div>` has no implicit role, so this is a deliberate placement choice rather than an accessibility default — it lets the host wrap Hero in whatever semantic landmark (if any) the surrounding page needs.
  **Approved**: pending

- **Decision**: `glow` defaults to `true`.
  **Rationale**: Matches the expected landing-page look; a host can disable it for alternative layouts.
  **Approved**: pending

- **Decision**: No validation or error handling is performed on `headline` or `tagline`.
  **Rationale**: Keeps the component a thin presentational layer; the host is responsible for providing meaningful, well-formed content.
  **Approved**: pending

- **Decision**: A landing page renders at most one Hero.
  **Rationale**: Hero is the page's sole centered screen and its `headline` is the page's single value-proposition claim rendered as an `<h1>`; a second Hero would duplicate that `<h1>` and undermine the page's heading structure.
  **Approved**: pending

