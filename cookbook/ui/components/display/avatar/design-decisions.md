
- **Decision**: Keep the class names `adh-avatar`, `adh-avatar__image`, and `adh-avatar__fallback` exactly as they are, rather than treating them as ordinary, freely-renameable implementation classes.
  **Rationale**: The source comment quoted in Overview documents them as a public theming surface for the theme editor and user CSS themes; renaming any of the three is a breaking change for every theme built against them, not a local refactor. This is the stability note attached to `render-root-with-semantic-class`, `render-image-with-semantic-class`, and `render-fallback-with-semantic-class`.
  **Approved**: pending

- **Decision**: `Avatar`, `AvatarImage`, and `AvatarFallback` add no logic beyond class assignment and prop forwarding.
  **Rationale**: Loading/error/fallback-reveal behavior, ARIA semantics, and any interactive states are owned entirely by Base UI's `Avatar` primitive (`@base-ui/react/avatar`), delegated to deliberately to keep this wrapper stateless and composable.
  **Approved**: pending

<!-- appkit-avatar -->
- **Decision**: The AppKit view takes an `AvatarContent` (`name`, `seed`, `imageURL`) rather than `AccountUser`.
  **Rationale**: Accounts and commit authors are different people models; a value type of exactly what the view draws lets both share one view, and `seed` keeps the colour stable without exposing an id.
  **Approved**: pending

