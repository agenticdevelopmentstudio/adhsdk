
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | suppress-empty-sections, show-separator-when-gated | DTO with all empty collections | No separator, no section headings |
| T2 | show-separator-when-gated | DTO with one social link | Separator rendered between header and social section |
| T3 | link-social-externally | DTO with a GitHub link | `<a>` has `target="_blank"` + `rel="noopener noreferrer"`, displays "GitHub" + "@handle" |
| T4 | show-initials-fallback | `avatarUrl: null`, `displayName: "Ada Lovelace"` | AvatarFallback shows "AL" |
| T5 | show-initials-fallback | `avatarUrl: null`, `displayName: null`, `slug: "ada"` | AvatarFallback shows "A" (first char of slug, uppercased) |
| T6 | use-displayname-or-slug | `displayName: null`, `slug: "ada"` | Heading text is "ada" |
| T7 | label-article | `displayName: "Ada Lovelace"` | `<article aria-label="Ada Lovelace's profile">` |
| T8 | skeleton-busy-state | render `UserCardSkeleton` | DOM has `role="status"`, `aria-busy="true"`, `aria-label="Loading profile…"` |
| T9 | accept-optional-classname | `className="my-custom"` | root `<article>` includes `my-custom` in classList |
| T10 | render-identity-header | any valid DTO | Identity header always rendered; slug always present |
| T11 | render-identity-header | `createdAt: null` (or omitted) | Identity header renders (avatar, display name, @slug); no member-since line present |
| T12 | use-displayname-or-slug, show-initials-fallback | `displayName: ""`, `slug: ""` | Heading text is empty; `AvatarFallback` renders the generic `UserIcon`, not initials |
| T13 | field-passthrough | DTO with `emails`, `phones`, and `addresses` all populated | All three sections render every item in their collections; none are filtered out by the component |
| T14 | suppress-empty-sections | DTO with only `socialLinks` populated | Only the Social section renders; Email, Phone, Address, and Personas sections are absent |
| T15 | suppress-empty-sections | DTO with only `emails` populated | Only the Email section renders |
| T16 | suppress-empty-sections | DTO with only `phones` populated | Only the Phone section renders |
| T17 | suppress-empty-sections | DTO with only `addresses` populated | Only the Address section renders |
| T18 | suppress-empty-sections | DTO with only `personas` populated | Only the Personas section renders |
| T19 | show-initials-fallback | `avatarUrl` set to a URL whose image fails to load | `AvatarImage` transitions to its error state and `AvatarFallback` renders, resolving through the same initials-then-slug-then-`UserIcon` chain as a null `avatarUrl` |
| T20 | native-contact-links | DTO with one email | `<a href="mailto:<email>">` rendered with the email as link text |
| T21 | native-contact-links | DTO with one phone | `<a href="tel:<phone>">` rendered with the phone number as link text |

