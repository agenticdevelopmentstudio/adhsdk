
- **Decision**: The drawer's `open` prop is controlled by the host, not managed internally by the component.
  **Rationale**: The "open" button lives in a separate header component outside this nav subtree. An uncontrolled drawer would leave that button silently dead after the drawer closed. Controlled state ensures the two stay in sync.
  **Approved**: pending

- **Decision**: Section expansion state is held above both renderings, in `DocNav`, rather than inside the tree component.
  **Rationale**: Desktop and mobile render the same tree description twice, as two separate React component instances. If expansion state lived inside the tree component, the desktop and mobile copies would diverge: the user opens a section on mobile, closes the drawer, and the section is now closed on mobile but still open on desktop. Holding `expanded` and `toggle` above both renderings keeps both instances in sync. A single-rendering host (desktop only) can omit this and let the tree own its own state internally.
  **Approved**: pending

- **Decision**: Expansion state does not auto-update on navigation; it is seeded from `activePath` once, on mount, only.
  **Rationale**: This preserves a reader's deliberate collapse choices as they navigate. Automatically closing a section they had opened would feel hostile.
  **Approved**: pending

- **Decision**: Heading sub-lists are part of the nav tree, not a separate anchoring feature.
  **Rationale**: Links to headings on the current page scroll instead of navigating; from any other page they navigate normally. This allows readers to jump within a long page without losing their place in the tree, and also keeps heading links shareable since the URL still carries the hash.
  **Approved**: pending

- **Decision**: The mobile drawer scrolls its own contents (`overflow-y-auto` on `nav`), not the page body.
  **Rationale**: Giving the drawer's own contents an independent scroll region means opening it doesn't require the page underneath to scroll for the nav to be usable. No explicit body-scroll lock is applied by this component, so the page behind the overlay can still scroll on its own.
  **Approved**: pending

- **Decision**: The desktop sidebar never wraps text, scrolling horizontally for anything still too long; the mobile drawer allows wrapping instead.
  **Rationale**: A row that wraps reads as two separate nav items, so the desktop column prevents it. Mobile deliberately omits this so long labels wrap onto a second line instead of requiring horizontal scroll, which is more natural on phone-sized screens.
  **Approved**: pending

- **Decision**: A node's children are ordered by type — leaves before branches — rather than following the host's input array order.
  **Rationale**: A reader scanning a section wants the section's own pages before its sub-directories. Without this reordering, the tree would read differently depending on how the host happened to sort the input array, reducing predictability.
  **Approved**: pending

- **Decision**: The selected link's indicator uses both bold weight and a left accent bar, not color alone.
  **Rationale**: This satisfies the requirement that status be distinguishable without relying on color alone (see **track-active-page** and the Differentiate Without Color accessibility option).
  **Approved**: pending

