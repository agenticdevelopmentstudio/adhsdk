
- **Single-word display name**: `initialsOf("Alice")` returns "A" (one initial; see **show-initials-fallback**, "up to two initials").
- **Slug with no spaces**: initials fallback uses the first character of the slug, uppercased.
- **Null displayName**: falls back to slug for the heading AND initials.
- **Empty-string displayName**: `use-displayname-or-slug` reads
  `user.displayName ?? user.slug`, which only falls back on `null`/`undefined`;
  an empty string `""` is neither, so the heading renders empty. If `slug` is
  also an empty string (violates the DTO's implied non-empty contract but
  isn't type-enforced), `initialsOf` also returns `""` for both the
  displayName- and slug-derived initials, and `AvatarFallback` renders the
  generic `UserIcon` placeholder instead of initials.
- **Avatar URL from arbitrary origin**: images use Base UI's `Avatar.Image` (via the shared `AvatarImage`; browser-native lazy load) rather than a Next.js `<Image />`, because arbitrary user-supplied origins can't be enumerated in a consuming app's image-optimizer allowlist. The component comment documents this explicitly.
- **Avatar image fails to load**: on an image error, Base UI's `Avatar.Image`
  transitions to its error state and reveals `AvatarFallback`, which resolves
  through the same fallback chain (initials, then slug, then `UserIcon`) as a
  null `avatarUrl` (see **show-initials-fallback**).
- **Large persona list**: each persona item wraps text; no truncation; the `<ul>` is scrollable by the parent container.
- **createdAt edge case**: `formatMemberSince` returns the locale-specific month+year. An invalid date string renders as "Invalid Date" — callers should validate upstream.

