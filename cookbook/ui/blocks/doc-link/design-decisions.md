
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
  **Rationale**: Lets callers apply arbitrary HTML attributes, event handlers, and styling without modifying the component. `{...rest}` is spread after `href={to}` in JSX, so the `Omit<AnchorHTMLAttributes, "href">` type is what keeps `to` authoritative for `href` in normal, typed usage; a caller that bypasses the type system to smuggle `href` into the spread attributes would have that value win over `to` (see test vector doc-link-012).
  **Approved**: pending

- **Decision**: Do not enforce an accessible name on the anchor.
  **Rationale**: The component renders `children` as provided and adds no warning or fallback label, so the caller is responsible for supplying non-empty `children` or an `aria-label`; this is why screen-reader-support is only partial. Implementers on other platforms should make the same choice.
  **Approved**: pending
