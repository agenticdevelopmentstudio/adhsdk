---
id: db6178e1-c613-4358-a0b4-8c6f5bfaaff9
title: "UserCard"
type: ingredient
version: 1.3.1
status: review
language: en
created: 2026-06-26
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Renders a user's profile card from a backend DTO; privacy gating applied server-side, component renders whatever fields are present."
platforms:
  - typescript
  - web
tags:
  - component
  - user-card
  - profile
  - ui
depends-on:
  - e3a2394d-d0d0-4495-bde4-59197f9d7866
  - 4a3761c5-5809-43c9-9a45-6f91fe82ae97
  - da56ecc7-18f6-412e-9368-3beb29309d8d
  - 2cfe57f0-cdd4-4723-a6e0-2ce4f136ce7f
  - b329d08b-9812-47d0-8094-516359d82d19
  - fce1333d-7f42-49f8-86da-508159701043
related: []
references: []
approved-by: ""
approved-date: ""
---

# UserCard

## Overview

`UserCard` is a shared profile card component that accepts a `UserCardDto` —
a structural mirror of a backend's `PublicUserProfile`-shaped schema — and
renders whatever fields are present.

All privacy gating is enforced server-side before the DTO is produced. The
component never hides or filters fields on its own; it simply suppresses
empty sections (an empty array is an invisible section). This makes the same
component render correctly for both the public audience (PUBLIC card) and
authenticated hub members (HUB+PUBLIC card with more fields).

Two exports are provided: `UserCard` (the main card) and `UserCardSkeleton`
(a placeholder for the loading state).

**Known consumers**: the Agentic Developer Hub (ADH) uses this component on
its public profile route (`/<slug>`) and in its profile-settings live
preview; ADH's social-links settings editor also imports `PLATFORM_LABELS`
from this module for its own platform picker.

## Behavioral Requirements

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

## Appearance

```
┌──────────────────────────────────────────────┐
│  [avatar]  Display Name                      │
│            @slug                             │
│            MEMBER SINCE <Month Year>         │
├──────────────────────────────────────────────┤  ← separator (only when gated content)
│  SOCIAL                                      │
│  ↗ Platform @handle   ↗ Platform @handle     │  ← wrapping flex row
├──────────────────────────────────────────────┤
│  EMAIL                                       │
│  ✉ email@example.com                         │
├──────────────────────────────────────────────┤
│  PHONE / ADDRESS / PERSONAS …               │
└──────────────────────────────────────────────┘
```

- Root: `rounded-xl border border-apt-border bg-apt-bg text-apt-text`.
- Avatar: `size-16` mobile, `size-20` sm+, with a fallback initials ring.
- Display name: `font-serif text-2xl` mobile, `text-3xl` sm+.
- Slug: `font-mono text-sm text-apt-text-muted`.
- Member since: `font-mono text-[0.7rem] uppercase tracking-[0.08em] text-apt-text-dim`.
- Section labels: `font-mono text-[0.6rem] uppercase tracking-[0.1em] text-apt-text-dim`.
- Social links: inline flex, `text-apt-text-muted hover:text-apt-text`, focus ring `apt-gold/40`.
- Persona items: `rounded-lg border border-apt-border bg-apt-surface p-3`; badge for `visibility`.

## States

| State | Appearance change |
|---|---|
| Loading | `UserCardSkeleton` — shimmer blocks replace all sections |
| Identity only | No separator, no gated sections; only the header area is shown |
| Full card | Separator + all populated gated sections visible |
| No avatar | `AvatarFallback` with two-letter initials or `UserIcon` placeholder |
| Long display name | Wraps inside the `min-w-0 flex-1` column; never truncated |

## Accessibility

- Root element is `<article>` with `aria-label="<displayName>'s profile"`.
  `<article>` is not one of the ARIA landmark roles (banner, complementary,
  contentinfo, form, main, navigation, region, search), so screen readers do
  not announce it as a landmark; the `aria-label` is exposed as the
  accessible name of the article element when it's reached, not as a
  landmark heading. A consumer that wants this card reachable via landmark
  navigation should add `role="region"` alongside the existing `aria-label`.
- Social links are native `<a>` elements; `rel="noopener noreferrer"` is set for
  security; they do NOT carry additional `aria-label` because the visible text
  (platform + handle) is already descriptive.
- Email links use `mailto:` scheme; phone links use `tel:` scheme — native
  controls, no custom ARIA needed (see **native-contact-links**).
- Addresses use `<address>` element with `not-italic` (the browser default
  italic style for address is suppressed via CSS).
- `UserCardSkeleton` declares `role="status" aria-busy="true"` so assistive
  technologies announce the loading state.
- All lucide icon imports carry `aria-hidden="true"` since their meaning is
  conveyed by adjacent text.
- Focus ring for interactive elements: `focus-visible:ring-2 focus-visible:ring-apt-gold/40`.

## Conformance Test Vectors

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

## Edge Cases

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

## Configuration

**Import path:**
```ts
import { UserCard, UserCardSkeleton, type UserCardDto } from '@adh-sdk/ui/blocks/user-card';
```

**Props:**

| Prop | Type | Required | Description |
|---|---|---|---|
| `user` | `UserCardDto` | yes | The profile DTO from the backend. |
| `className` | `string` | no | Extra Tailwind classes applied to the root `<article>`. |

**`UserCardDto` shape:**

| Field | Type | Description |
|---|---|---|
| `slug` | `string` | Unique user slug. Used as fallback display name. |
| `displayName` | `string \| null` | User's chosen display name. |
| `avatarUrl` | `string \| null` | Avatar image URL (arbitrary origin; not run through Next.js optimizer). |
| `createdAt` | `string \| null \| undefined` | ISO 8601 timestamp; rendered as "Member since Month Year". Omitted (e.g. an owner's own preview where no account date is available) hides the line. |
| `socialLinks` | `UserCardSocialLink[]` | Visible social links from the privacy-gated set. |
| `emails` | `string[]` | Visible email addresses. |
| `phones` | `string[]` | Visible phone numbers. |
| `addresses` | `UserCardAddress[]` | Visible physical addresses. |
| `personas` | `UserCardPersona[]` | Visible personas (public or unlisted). |

**`UserCardSkeleton` props:**

| Prop | Type | Required | Description |
|---|---|---|---|
| `className` | `string` | no | Extra classes on the skeleton root. |

## Deep Linking

Not applicable: The component is a pure presentational render with no integrated navigation. Deep linking is the responsibility of the page or layout that wraps this component.

## Localization

Applicable: the component renders fixed English strings directly in its
JSX — the five section labels (`Social`, `Email`, `Phone`, `Address`,
`Personas`), the `Member since` prefix, `UserCardSkeleton`'s
`Loading profile…` label, and the `"<name>'s profile"` article `aria-label` —
plus the platform display names in `PLATFORM_LABELS`. None of these are
externalized to a resource file or accepted as a prop; there is currently no
mechanism (for example, a labels prop) for a consumer to override or
translate them, so localizing this component today requires forking it or
replacing the rendered text after the fact. `formatMemberSince` itself is
locale-aware — it calls `toLocaleDateString(undefined, …)`, which follows
the runtime's locale for month/year formatting (this casing/format choice is
locale-sensitive by design, not an invariant-culture call).

## Accessibility Options

Not applicable: The component uses system focus styles and does not implement custom accessibility options like reduced-motion animations or high-contrast modes. It delegates to the design system's token values (e.g., `apt-border`, `apt-bg`) which are applied globally.

## Feature Flags

Not applicable: The component has no feature flag requirements. It is always available and renders deterministically based on its input DTO.

## Analytics

Not applicable: `UserCard` is a pure presentational component with no built-in instrumentation. Event tracking (if needed by a consumer) is the responsibility of the page or layout that wraps this component and calls it.

## Privacy

Applicable: the DTO can include email addresses, phone numbers, and physical
addresses, all personal data. All privacy gating — deciding which of these
fields a given viewer may see — is enforced server-side before the DTO is
constructed (see **No client-side privacy gating** in Design Decisions).
`UserCard` itself does not collect, store, or transmit this data; it only
renders whatever fields are present in the DTO it receives.

## Logging

No logging. `UserCard` is a pure presentational component. It emits no telemetry
or structured log events. Error logging (e.g. avatar load failures) is delegated
to the browser console and handled by Base UI's `Avatar.Image` built-in error
handling (it transitions to error and reveals `Avatar.Fallback`).

## Platform Notes

- **SwiftUI**: Build a view composition from `VStack` + `HStack`, using `AsyncImage` for the avatar with a fallback symbol (`Image(systemName: "person.circle")`). Render sections conditionally based on collection emptiness. Use SwiftUI's `@Environment` to access design token colors. Member since date formatting uses `Date.FormatStyle.dateTime.month(.wide).year()`, not `.abbreviated` — `.abbreviated` produces a full month/day/year date, not month and year alone.
- **Compose**: Use `Column` for the layout with `AsyncImage` from Coil for avatar loading. Conditional rendering via Kotlin's `if` within the composable. Social links render as an `AnnotatedString` carrying a `LinkAnnotation.Url`, opened via the composition-local `LocalUriHandler` (`ClickableText` is deprecated, and there is no `navigateToExternalUrl()` API in Compose). Section visibility determined by collection checks.
- **React/Web**: Source is `packages/web/packages/ui/src/blocks/user-card.tsx` using Base UI's `@base-ui/react/avatar`, Lucide React icons, and Tailwind CSS (`apt-*` tokens). Conditional rendering suppresses empty sections. `UserCardSkeleton` uses the `Skeleton` component from the same package for the loading state.
- **AppKit / UIKit**: Implement as a `UIViewController` on iOS (wrapped in a SwiftUI `UIViewControllerRepresentable` only when hosted from SwiftUI) or an `NSViewController` on macOS, with `NSImageView`/`UIImageView` + `NSTextField`/`UILabel` composition. Use `URLSession` or the system's own image-loading facilities for async avatar loading — no third-party dependency is needed. Render the fixed set of static sections as a vertical stack view (`NSStackView`/`UIStackView`), not a table view, since the section list isn't a dynamically scrolling collection. Focus ring uses the system focus appearance rather than a hardcoded `UIColor.systemBlue`.
- **WinUI 3**: Implement using WinUI `Grid` for layout, and the built-in `PersonPicture` control for the avatar — it already handles the image/initials/fallback-glyph chain in one control, instead of hand-building an `Image` plus a Segoe MDL2 glyph. Use `TextBlock` for text with automatic wrapping. Section visibility via `Visibility` property (Collapsed/Visible). Apply Fluent 2 theme resources for colors and spacing. Social links use `HyperlinkButton` with `NavigateUri` binding.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/user-card.tsx` | unverified |

## Design Decisions

**Decision**: The component renders exactly what the DTO contains; privacy
logic lives entirely in the backend.
**Rationale**: Keeps the component simple and ensures the two card variants
(PUBLIC, HUB+PUBLIC) share one render path.
**Approved**: pending

**Decision**: Use Base UI's `Avatar.Image` (via the shared `AvatarImage`)
instead of a Next.js `<Image />` for the avatar.
**Rationale**: Avatar URLs come from arbitrary user-supplied origins that
can't be enumerated in a consuming Next.js app's image-optimizer allowlist.
`Avatar.Image` gives browser-native lazy loading and a clean fallback via
`AvatarFallback` (the image transitions to error and reveals
`AvatarFallback`) without requiring an allowlist.
**Approved**: pending

**Decision**: `UserCardDto` structurally mirrors the backend's public-profile
schema rather than importing a generated type.
**Rationale**: Keeps `@adh-sdk/ui` free of any API-types
dependency; the structural match is enforced at the call site by the
TypeScript compiler.
**Approved**: pending

**Decision**: Export the `PLATFORM_LABELS` platform-label map from this
module.
**Rationale**: Makes this file the single source of truth for platform
display names, so a consumer's social-links settings editor (e.g. ADH's) can
import the same map instead of duplicating it.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.privacy-and-data.no-pii-in-logs](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/23bca2e1-dc0f-5ff4-beaf-03891ad48e6b) | passed | Privacy & Data |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

These statuses rest on the source's native `<a>`/`<address>` elements and
rem-based Tailwind text sizes for the passed accessibility checks, the
`apt-*` design tokens whose actual color values live outside this file for
the partial `contrast-ratio`, the total absence of any logging call for the
passed `no-pii-in-logs`, the hardcoded `Social`/`Email`/`Phone`/`Address`/
`Personas`/`Member since` strings and the `PLATFORM_LABELS` map for the
failed internationalization checks, `formatMemberSince`'s use of
`toLocaleDateString` plus the non-truncating wrapping layout for the passed
internationalization checks, and the untested RTL flex ordering together
with `initialsOf`'s single-UTF-16-code-unit character slicing for the
partial internationalization checks. `separation-of-concerns` passes because
`initialsOf`, `platformLabel`, `formatMemberSince`, and `addressLines` are
pure helper functions kept apart from the render body; `unit-test-coverage`
fails because no test exercises `UserCard`.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial recipe authoring for existing shared component. |
| 1.1.0 | 2026-07-03 | Mike Fullerton | Reattribute the avatar image engine from Radix to Base UI (`@base-ui/react/avatar`), matching `avatar.tsx`; behavior (load/error → initials fallback) unchanged. |
| 1.2.0 | 2026-09-22 | Claude Haiku 4.5 | Add missing template sections (Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, Privacy) with proper "not applicable" explanations; restructure Platform Notes into five-platform format with concrete implementation guidance for each platform; correct domain URI; set status to review. |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename all requirements to subject-only kebab-case (no `must-` prefix); fix the member-since and initials-count requirement/vector contradictions; formalize `native-contact-links` and add vectors for field-passthrough, per-section suppression, avatar load failure, contact links, and the empty-slug/displayName edge case; correct Platform Notes APIs (WinUI `PersonPicture`, Compose `LinkAnnotation`/`LocalUriHandler`, AppKit/UIKit stack view + `URLSession`, SwiftUI `.dateTime.month(.wide).year()`); mark Localization and Privacy applicable; reformat Design Decisions and rebuild Compliance from the actual catalog; add `depends-on` for the composed avatar/skeleton/separator/badge/external-link/section-label pieces; generalize ADH-specific wording into a Known Consumers note. |
| 1.3.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
