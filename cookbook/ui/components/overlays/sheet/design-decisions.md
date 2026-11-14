
**Decision**: Sheet is implemented as a series of composed sub-components (Header, Footer, Title, Description) rather than a monolithic component.
**Rationale**: This allows flexibility in content structure and reuse of individual parts. The pattern matches the shadcn/ui design philosophy.
**Approved**: pending

**Decision**: The component wraps Base UI's Dialog primitive, which provides keyboard handling (Escape to close), focus management, and ARIA attributes automatically.
**Rationale**: This offloads accessibility complexity to a vetted foundation.
**Approved**: pending

**Decision**: Animation durations are calculated using `calc()` with a `--apt-anim-scale` custom property.
**Rationale**: This allows global animation control (e.g., for reduced motion) without changing component code.
**Approved**: pending

**Decision**: The `showCloseButton` prop defaults to `true`, providing an always-available close affordance.
**Rationale**: Every sheet then has a discoverable way to dismiss it without relying on Escape or an overlay click; consumers with their own close control can turn it off.
**Approved**: pending

**Decision**: Left and right drawers are constrained to 75% viewport width, capped at 24rem, on small+ screens, leaving the underlying content partially visible.
**Rationale**: A visible strip of the underlying content preserves the user's context, and the cap stops a drawer from growing to fill a wide screen.
**Approved**: pending

**Decision**: The backdrop includes a blur effect (via `supports-backdrop-filter:backdrop-blur-xs`) to create visual separation.
**Rationale**: This is a visual preference; the blur is optional on unsupporting browsers.
**Approved**: pending

