
- **render-identity-header**: The component MUST always render the identity
  header (avatar, display name, @slug) regardless of which optional sections
  are populated. The member-since date is part of the header only when
  `createdAt` is present; it is omitted when `createdAt` is null or
  undefined.
- **suppress-empty-sections**: Each of the five gated sections (Social,
  Email, Phone, Address, Personas) MUST be omitted from the DOM when its
  corresponding collection is empty.
- **show-separator-when-gated**: A `<Separator>` MUST appear between the
  identity header and the gated sections when at least one gated section is
  populated, and MUST be absent when all collections are empty.
- **link-social-externally**: Each social link MUST open in a new tab
  (`target="_blank" rel="noopener noreferrer"`) with the platform label and
  handle displayed.
- **native-contact-links**: Each email MUST render as an
  `<a href="mailto:...">` link and each phone number MUST render as an
  `<a href="tel:...">` link.
- **show-initials-fallback**: When `avatarUrl` is null or the image fails
  to load, the `AvatarFallback` MUST show up to two initials derived from
  `displayName`, falling back to the slug, falling back to a generic
  `UserIcon`.
- **use-displayname-or-slug**: The heading MUST display `displayName` when
  non-null, and `slug` otherwise. (See **Edge Cases** for the empty-string
  `displayName` case — the check is for null/undefined, not emptiness.)
- **label-article**: The `<article>` MUST carry `aria-label` of
  `"<displayName>'s profile"` (or `"<slug>'s profile"` when no display name).
- **field-passthrough**: The component MUST NOT hide fields based on its
  own privacy logic; it renders only what the DTO provides.
- **accept-optional-classname**: The component MUST accept a `className`
  prop and apply it to the root `<article>`.
- **skeleton-busy-state**: `UserCardSkeleton` MUST carry
  `role="status" aria-busy="true" aria-label="Loading profile…"` on its root
  element.

