
- **Decision**: Use `to` instead of `href` for the destination prop.
  **Rationale**: Matches the `DocLinkComponent` interface contract used by `doc-breadcrumbs` and `doc-nav` for router-adapter injection on web; other platforms use a different injection mechanism (see Platform Notes), so this is a web-specific naming choice rather than a claim of one signature shared across platforms.
  **Approved**: pending

- **Decision**: Perform no internal validation of `to`.
  **Rationale**: The component trusts the caller to provide a valid, safe destination path. Validating and sanitizing untrusted values — including blocking unsafe schemes such as `javascript:` — is the host application's responsibility, since it has the context about where `to` originates.
  **Approved**: pending

- **Decision**: Apply no visual styling.
  **Rationale**: Delegating all appearance to CSS and browser defaults enables composition into different UI contexts (breadcrumbs, navigation trees, etc.) without tight coupling to a specific design system.
  **Approved**: pending

- **Decision**: Spread remaining props onto the anchor element.
  **Rationale**: Lets callers apply arbitrary HTML attributes, event handlers, and styling without modifying the component. Because `{...rest}` spreads after `href={to}` (see **accept-and-spread-attributes**), the `Omit<AnchorHTMLAttributes, "href">` type is what keeps `to` authoritative for `href` in normal, typed usage.
  **Approved**: pending

