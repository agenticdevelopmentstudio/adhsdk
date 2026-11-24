
- **Decision**: The rail has a fixed width of 14 rem, and long heading text wraps onto additional lines rather than being truncated.
  **Rationale**: A fixed width aligns with the document's grid and keeps the rail's layout predictable; the component neither truncates long text nor lets it escape the rail, so it wraps within that width instead (an unbreakable token long enough to still exceed it scrolls inside the rail, since the aside's `overflow-y: auto` makes its `overflow-x` compute to `auto` as well).
  **Approved**: pending

- **Decision**: The title renders in monospace font.
  **Rationale**: Monospace distinguishes the title as "component chrome" rather than document content, following design conventions for supplementary UI.
  **Approved**: pending

- **Decision**: Heading depth is represented via left padding, not a tree hierarchy or nested list.
  **Rationale**: The document's heading outline is already visible in the main content, so a flat, indented list is enough to convey structure in the rail.
  **Approved**: pending

- **Decision**: The component indents based on heading depth but never hides or skips headings at deep nesting levels; all headings are included in the list.
  **Rationale**: Omitting deep headings would make the rail an incomplete map of the document.
  **Approved**: pending

- **Decision**: The active heading is the first heading, in document order, whose element intersects a viewport band tracked via `useScrollSpy`'s `IntersectionObserver` (`rootMargin: "-80px 0px -60% 0px"`) — from 80px below the viewport top down to 60% of the viewport height. There is no debounce, so the marker can flip rapidly when headings sit close together; but when no heading intersects the band (scrolled deep into a long section, or past the last heading), the hook deliberately keeps the last active heading rather than clearing it — a sticky fallback, not the absence of one.
  **Rationale**: A band rather than a single line tolerates ordinary scroll jitter without flip-flopping between two adjacent headings, and holding the last position when nothing intersects the band avoids blanking the "on this page" marker while the reader is still inside a section.
  **Approved**: pending

- **Decision**: Clicking a heading smooth-scrolls the page instead of jumping instantly, and default link navigation is prevented, so the URL hash does not update.
  **Rationale**: A smooth scroll improves the reader's sense of where the click took them and reduces visual jarring; the component takes over the scroll itself instead of relying on default browser hash-navigation.
  **Approved**: pending

- **Decision**: All color values are sourced from CSS custom properties, never hardcoded.
  **Rationale**: This lets the component respect theme changes and adapt to light/dark mode without prop drilling or conditional styling.
  **Approved**: pending

