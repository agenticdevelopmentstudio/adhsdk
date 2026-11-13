---
id: 6c034a7a-3a43-4da6-bc1a-0cbc39f32cc4
title: "Registry Profile"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Displays a registry entry with profile details, custom fields, services, and links."
platforms:
  - typescript
  - web
tags:
  - profile
  - registry
depends-on:
  - 6579e030-0455-453c-81cf-177dae3dd82e
  - fe09968a-6575-40d0-b0b8-af6ce52d8efd
related:
  - 6579e030-0455-453c-81cf-177dae3dd82e
  - fe09968a-6575-40d0-b0b8-af6ce52d8efd
references: []
approved-by: ""
approved-date: ""
---

# Registry Profile

## Overview

Registry Profile displays a comprehensive view of a single registry entry, including identity information (name, photo, summary), metadata (category, location, languages), custom fields with visibility controls, services, keywords, and external links. The component adapts to the serving context through pluggable image resolution and optional contact affordances.

## Behavioral Requirements

- **render-display-name**: Component MUST render the entry's `displayName` as an `<h1>` heading.
- **render-full-display-name-untruncated**: Component MUST render the full `displayName` string with no truncation; whether the name wraps or overflows is determined by CSS.
- **render-photo-when-available**: Component MUST render the entry's photo if `photoAttachmentId` is present and `resolveImageUrl(photoAttachmentId)` returns a non-null value.
- **render-photo-alt-empty**: Component MUST set the photo `alt` attribute to an empty string (not a description), as the photo is decorative context for sighted users and the name heading provides textual identity.
- **render-summary-when-present**: Component MUST render the entry's `summary` as a paragraph if the summary string is truthy.
- **render-category-when-present**: Component MUST render the entry's `category` as a metadata row if the category string is truthy.
- **render-location-when-present**: Component MUST render the entry's `locationText` as a metadata row if the location string is truthy.
- **render-languages-list**: Component MUST render the entry's `languages` array as a comma-separated string in a metadata row if the array length is greater than zero.
- **render-metadata-list-unconditionally**: Component MUST render the `<dl class="rp__meta">` metadata list container even when category, location, and languages are all falsy or empty. Only the individual metadata rows are conditional; the container itself is not.
- **render-keywords-list**: Component MUST render the entry's `keywords` array as an unordered list of keyword items if the array length is greater than zero.
- **render-contact-affordance-conditionally**: Component MUST render the `contact` prop inside a contact container only if `entry.contactMode === 'dm'` AND `contact` is not null or undefined.
- **render-all-fields**: Component MUST render every field in `entry.fields` as a description-list item with the field's label and value.
- **omit-fields-section-when-empty**: Component MUST render the profile without a `rp__fields` section when `entry.fields.length === 0`.
- **render-field-visibility-marker**: Component MUST render a visibility marker span inside the field label if the field's visibility is not `public`. The marker text MUST be "Signed-in members only" for `authenticated` visibility and "Private" for `private` visibility.
- **omit-marker-for-public-fields**: Component MUST NOT render a visibility marker for fields with `public` visibility.
- **render-service-list**: Component MUST render a `ServiceList` component with the entry's `services` array. When `services` is empty, whether anything is shown is entirely delegated to `ServiceList`, which itself renders nothing for an empty array (see [adhsdk.ingredient.registry-profile.service-list](cookbook:fe09968a-6575-40d0-b0b8-af6ce52d8efd)).
- **render-links-section**: Component MUST render a navigation section with `aria-label="Elsewhere"` containing an unordered list of links if `entry.links` array length is greater than zero.
- **render-links-with-fallback-label**: Component MUST render each link with the link's `label` as display text if the label is truthy, otherwise use the `url` as display text.
- **set-link-security-attributes**: Component MUST set `rel="noopener noreferrer nofollow"` and `target="_blank"` on all links.
- **use-resolver-for-image-urls**: Component MUST use the `resolveImageUrl` prop to resolve all image attachment IDs to URLs. If `resolveImageUrl` is not provided, Component MUST default to looking up the ID in `entry.imageUrls`.
- **default-resolver-null-for-unmapped-id**: When `resolveImageUrl` is not provided, the default resolver MUST return `null` when `entry.imageUrls` has no key for the given attachment ID.
- **accept-null-from-resolver**: Component MUST treat a `null` return value from `resolveImageUrl` as "no image" and render the profile without that image.
- **render-as-article**: Component MUST render the profile root as an `<article>` element.

## Appearance

- **Root container**: `<article>` with className `rp`
- **Header section**: `<header>` with className `rp__header`
- **Photo**: `<img>` with className `rp__photo`, rendered only if URL is available
- **Identity container**: `<div>` with className `rp__identity`
- **Display name**: `<h1>` with className `rp__name`
- **Summary**: `<p>` with className `rp__summary`
- **Metadata list**: `<dl>` with className `rp__meta`
- **Metadata row**: `<div>` with className `rp__meta-row`
- **Metadata label**: `<dt>` element
- **Metadata value**: `<dd>` element
- **Keywords list**: `<ul>` with className `rp__keywords`
- **Keyword item**: `<li>` with className `rp__keyword`
- **Contact container**: `<div>` with className `rp__contact`
- **Fields section**: `<dl>` with className `rp__fields`
- **Field container**: `<div>` with className `rp__field` and data attribute `data-field-key={field.key}`
- **Field label**: `<dt>` with className `rp__field-label`
- **Field visibility marker**: `<span>` with className `rp__field-audience` and data attribute `data-audience={field.visibility}`
- **Field value**: `<dd>` with className `rp__field-value`
- **Links section**: `<nav>` with className `rp__links` and `aria-label="Elsewhere"`

## States

| State | Condition | Appearance change |
|-------|-----------|------------------|
| With photo | `photoAttachmentId` present and URL resolves | Photo visible in header |
| Without photo | `photoAttachmentId` absent or URL resolves to null | No photo element rendered |
| With summary | `summary` is truthy | Summary paragraph displayed |
| Without summary | `summary` is falsy | No summary element rendered |
| With metadata | Category, location, or languages present | Metadata rows displayed in definition list |
| Metadata list container | any input | `<dl class="rp__meta">` renders unconditionally, even when it contains no rows |
| With keywords | `keywords.length > 0` | Keywords rendered as list items |
| Without keywords | `keywords.length === 0` | No keywords section rendered |
| Contact available | `contactMode === 'dm'` AND `contact` prop provided | Contact affordance container rendered |
| Contact unavailable | `contactMode !== 'dm'` OR `contact` prop absent | No contact container rendered |
| Field public | `field.visibility === 'public'` | No visibility marker rendered |
| Field authenticated | `field.visibility === 'authenticated'` | "Signed-in members only" marker rendered |
| Field private | `field.visibility === 'private'` | "Private" marker rendered |
| With links | `links.length > 0` | Links navigation section rendered |
| Without links | `links.length === 0` | No links section rendered |

## Accessibility

- **Role**: The root element is an `<article>`, which defines the profile as a standalone, self-contained piece of content.
- **Heading structure**: The display name is an `<h1>`, which provides proper document structure.
- **Photo alt text**: The photo `alt` attribute is an empty string, signaling to assistive technology that it is decorative; the `<h1>` provides the identity.
- **Metadata structure**: The metadata (category, location, languages) is rendered in a description list (`<dl>`), providing semantic structure for screen readers.
- **Links section**: The links navigation has `aria-label="Elsewhere"` to describe the section purpose to assistive technology users.
- **Field labels**: Each field is rendered with a `<dt>` label paired with a `<dd>` value in a definition list, providing semantic structure.
- **Visibility markers**: Visibility markers are inline in the field label, ensuring users encounter the visibility restriction immediately when they reach the field.
- **Field values**: `FieldValue` renders each value by type: `url` as an `<a>` with `rel="noopener noreferrer nofollow"` and `target="_blank"`, `image` as an `<img>` whose `alt` is the field label, and every other type (text, textarea, markdown, date, select, multi_select, boolean, address, email, phone) as text content. The `<dt>` label supplies the accessible name for each `<dd>` value. See [adhsdk.ingredient.registry-profile.field-value](cookbook:6579e030-0455-453c-81cf-177dae3dd82e).
- **Services**: `ServiceList` is a static section headed by an `<h2>` ("Services") with one `<h3>` per service, continuing the heading hierarchy under the profile's `<h1>`. It has no interactive elements, so there is nothing to reach by keyboard. See [adhsdk.ingredient.registry-profile.service-list](cookbook:fe09968a-6575-40d0-b0b8-af6ce52d8efd).
- **Touch targets**: The only interactive elements are inline text links (the "Elsewhere" links and `url` field values). Inline links within text are exempt from the WCAG 2.5.8 minimum target size; the profile adds no buttons or controls.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| profile-001 | render-display-name | `entry.displayName = "Alice"` | Output contains `<h1 class="rp__name">Alice</h1>` |
| profile-002 | render-photo-when-available | `entry.photoAttachmentId = "photo-123"`, `resolveImageUrl("photo-123") = "https://cdn.example.com/photo.jpg"` | Output contains `<img class="rp__photo" src="https://cdn.example.com/photo.jpg" alt="" />` |
| profile-003 | render-photo-alt-empty | `entry.photoAttachmentId = "photo-123"`, `resolveImageUrl` returns URL | Photo element has `alt=""` (empty string) |
| profile-004 | render-summary-when-present | `entry.summary = "Software engineer"` | Output contains `<p class="rp__summary">Software engineer</p>` |
| profile-005 | render-summary-when-present | `entry.summary = ""` (empty string) | Output does not contain `rp__summary` element |
| profile-006 | render-category-when-present | `entry.category = "Engineering"` | Output contains metadata row with label "Category" and value "Engineering" |
| profile-007 | render-category-when-present | `entry.category = null` | Output does not contain category metadata row |
| profile-008 | render-location-when-present | `entry.locationText = "San Francisco"` | Output contains metadata row with label "Location" and value "San Francisco" |
| profile-009 | render-languages-list | `entry.languages = ["English", "Spanish"]` | Output contains metadata row with label "Languages" and value "English, Spanish" |
| profile-010 | render-languages-list | `entry.languages = []` | Output does not contain languages metadata row |
| profile-011 | render-keywords-list | `entry.keywords = ["react", "typescript"]` | Output contains `<li class="rp__keyword">react</li>` and `<li class="rp__keyword">typescript</li>` |
| profile-012 | render-keywords-list | `entry.keywords = []` | Output does not contain `rp__keywords` element |
| profile-013 | render-contact-affordance-conditionally | `entry.contactMode = "dm"`, `contact = <ContactButton />` | Contact container rendered with ContactButton inside |
| profile-014 | render-contact-affordance-conditionally | `entry.contactMode = "email"`, `contact = <ContactButton />` | Contact container is not rendered |
| profile-015 | render-contact-affordance-conditionally | `entry.contactMode = "dm"`, `contact = null` | Contact container is not rendered |
| profile-016 | render-all-fields | `entry.fields = [{key: "email", label: "Email", value: "alice@example.com", visibility: "public"}]` | Output contains field container with data-field-key="email" |
| profile-017 | render-field-visibility-marker | `field.visibility = "authenticated"` | Field label contains span with text "Signed-in members only" |
| profile-018 | render-field-visibility-marker | `field.visibility = "private"` | Field label contains span with text "Private" |
| profile-019 | omit-marker-for-public-fields | `field.visibility = "public"` | Field label does not contain visibility marker span |
| profile-020 | use-resolver-for-image-urls | `resolveImageUrl = (id) => (id === "photo-123" ? "https://cdn.example.com/custom.jpg" : null)`, `entry.imageUrls = { "photo-123": "https://cdn.example.com/from-map.jpg" }`, `entry.photoAttachmentId = "photo-123"` | Output contains `src="https://cdn.example.com/custom.jpg"` (the provided resolver's value), never the `entry.imageUrls` value |
| profile-021 | use-resolver-for-image-urls | `resolveImageUrl` not provided | Component falls back to `entry.imageUrls[id]` |
| profile-022 | render-as-article | any input | Root element is `<article class="rp">` |
| profile-023 | render-links-section | `entry.links = [{url: "https://example.com", label: "Portfolio"}]` | Output contains `<nav class="rp__links" aria-label="Elsewhere">` with link |
| profile-024 | render-links-with-fallback-label | `entry.links = [{url: "https://example.com", label: ""}]` | Link displays the URL as text, not the empty label |
| profile-025 | set-link-security-attributes | `entry.links = [{url: "https://example.com", label: "Site"}]` | Link has `rel="noopener noreferrer nofollow" target="_blank"` |
| profile-026 | render-service-list | `entry.services = [{title: "Consulting", description: "Advice", pricingModel: "hourly", priceMin: 100, priceMax: 100, currency: "USD", unit: "hour", deliveryMode: "virtual"}]` | Output contains a `ServiceList` section listing "Consulting" |
| profile-027 | render-service-list | `entry.services = []` | Output does not contain `rp-services` (ServiceList renders nothing for an empty array) |
| profile-028 | default-resolver-null-for-unmapped-id | `resolveImageUrl` not provided, `entry.photoAttachmentId = "missing-id"`, `entry.imageUrls = {}` | No photo element rendered; contrast with profile-021, where the ID is present in the map |
| profile-029 | accept-null-from-resolver | `resolveImageUrl = () => null`, `entry.photoAttachmentId = "photo-123"` | No photo element rendered; component does not throw or render a broken-image placeholder; contrast with profile-002, where the resolver returns a URL |
| profile-030 | render-location-when-present | `entry.locationText = ""` (empty string) | Output does not contain location metadata row |
| profile-031 | render-links-section | `entry.links = []` | Output does not contain `rp__links` element |
| profile-032 | omit-fields-section-when-empty | `entry.fields = []` | Output does not contain `rp__fields` element; contrast with profile-016, where one field is present |
| profile-033 | render-full-display-name-untruncated | `entry.displayName = "A".repeat(300)` | Output contains the full 300-character string inside `<h1 class="rp__name">`, with no truncation or ellipsis |
| profile-034 | render-metadata-list-unconditionally | `entry.category = ""`, `entry.locationText = ""`, `entry.languages = []` | Output still contains `<dl class="rp__meta">`, with no `rp__meta-row` children inside it |

## Edge Cases

- **Null or undefined entry**: Not applicable. The component requires a `PublicEntry` and will error if `entry` is null. The host is responsible for ensuring a valid entry is provided.
- **Empty entry.fields array**: See **omit-fields-section-when-empty**.
- **photoAttachmentId without URL resolution**: If `photoAttachmentId` is present but `resolveImageUrl` returns `null`, Component MUST render the profile without a photo (see **accept-null-from-resolver**).
- **All metadata fields falsy**: See **render-metadata-list-unconditionally**. The `<dl class="rp__meta">` container is still rendered; only the category, location, and languages rows inside it are omitted.
- **Link URL scheme is not restricted**: `entry.links[*].url` is rendered directly as the link's `href` with no scheme allow-list in this component; a `javascript:` or `data:` URL would render as a live, clickable link. `rel="noopener noreferrer nofollow"` and `target="_blank"` are the only safety attributes this component applies. Restricting or validating the URL scheme is the responsibility of the server that populates `entry.links`, not this presentation component.
- **Field with empty label**: Not applicable. The source assumes field labels are provided by the server; empty labels are a server data quality issue.
- **Resolver throws an error**: Not applicable. The component assumes the resolver does not throw and returns a string or null. Error handling is the host's responsibility.
- **Very long display name**: See **render-full-display-name-untruncated**.
- **Very long field values**: Component delegates to `FieldValue` component. Edge case handling is FieldValue's responsibility.
- **Concurrent updates to entry prop**: Not applicable. The component is a functional React component and does not maintain mutable state. Behavior when `entry` prop changes is React's re-render lifecycle, not a component-defined edge case.
- **contact prop changes between render cycles**: Component MUST render the new contact prop value on the next render.

## Configuration

Not applicable: RegistryProfile is a presentation component with no configuration options. All behavior is determined by the `entry` data and the optional `resolveImageUrl` and `contact` props.

## Deep Linking

Not applicable: RegistryProfile does not define any deep linking behavior. The host application is responsible for routing to this component and providing the entry data.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| field-visibility.authenticated | "Signed-in members only" | Marker text shown when a field is visible only to authenticated users |
| field-visibility.private | "Private" | Marker text shown when a field is marked private |
| metadata.category | "Category" | Label for the category metadata row |
| metadata.location | "Location" | Label for the location metadata row |
| metadata.languages | "Languages" | Label for the languages metadata row |
| nav.elsewhere | "Elsewhere" | aria-label for the links navigation section |

These keys describe intent, not an implemented lookup: the TypeScript source hardcodes each string as an English literal (the `AUDIENCE_NOTE` record, and the `"Category"`/`"Location"`/`"Languages"`/`"Elsewhere"` literals inline in `RegistryProfile.tsx`). There is no resource file, i18n library call, or override prop. A host that needs another language must fork the component or wrap it; the component itself provides no localization mechanism.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: RegistryProfile does not animate. All content is static. |
| Increase Contrast | Deferred to CSS styling and the host application's theme. Component does not define color values. |
| Differentiate Without Color | Deferred to the FieldValue and ServiceList child components and CSS styling. |

## Feature Flags

Not applicable: RegistryProfile has no feature flags. All behavior is always enabled.

## Analytics

Not applicable: RegistryProfile is a presentational component and does not emit analytics events. Event tracking is the host application's responsibility.

## Privacy

- **Data collected**: None. RegistryProfile is a presentation component and collects no telemetry, tracking, or user interaction data.
- **Storage**: Not applicable. Component does not store data.
- **Transmission**: Not applicable. Component does not transmit data beyond rendering what was passed in.
- **Retention**: Not applicable. Component does not retain data.
- **Note**: The component renders data that was passed to it by the host. The host is responsible for privacy handling of the entry data (e.g., filtering fields the viewer is not authorized to see, which the server already does via the `PublicEntry` type and the backend's filtering logic).

## Logging

Not applicable: RegistryProfile does not emit logging. The host application is responsible for logging user interactions with the profile.

## Platform Notes

- **TypeScript/React Web**: Source is a React functional component in TypeScript at `packages/web/packages/registry-profile/src/RegistryProfile.tsx`. Key implementation details: the component uses conditional rendering (`? :`) for optional sections, a resolver pattern for image URLs with a nullish coalescing fallback to `entry.imageUrls`, and an exhaustive `Record<FieldVisibility, string | null>` to ensure visibility markers are defined for every audience type. The component does not fetch data; all content is provided via props.
- **SwiftUI**: Translate the component as a View that renders a scrollable VStack. The header is an HStack with the photo (Image, if available) and a VStack for identity details. The component has no internal state — every section is driven entirely by its inputs — so gate each optional section with a plain `if` on the input values (`entry.summary`, `entry.category`, and so on), not `@State`. Map `FieldVisibility` to a conditional `Text` rendered inline with the field's label. Delegate field value rendering to a FieldValue View and service rendering to a ServiceList View (see [adhsdk.ingredient.registry-profile.field-value](cookbook:6579e030-0455-453c-81cf-177dae3dd82e) and [adhsdk.ingredient.registry-profile.service-list](cookbook:fe09968a-6575-40d0-b0b8-af6ce52d8efd)). Links (the "Elsewhere" list and any `url`-typed field) are external destinations, not in-app routes, so open them with `Link` or the `@Environment(\.openURL)` action; `navigationLink(destination:)` pushes an in-app SwiftUI view and does not open an external URL.
- **Compose**: Implement as a Composable function that renders a Column (scrollable) with a Row header containing the photo (Image) and identity content. Use conditional composition (`if`) for optional sections, driven entirely by the incoming parameters. Render metadata rows and field items as plain rows inside that same scrollable Column rather than nesting a `LazyColumn` inside it — a scrollable `LazyColumn` inside a scrollable `Column` throws at runtime; use a single `LazyColumn` for the whole screen instead if the field list needs lazy loading. Delegate to FieldValue and ServiceList Composables. Open external links (the "Elsewhere" list, `url`-typed fields) with `LocalUriHandler.current.openUri(url)`; there is no `navController.openUrl()` API.
- **AppKit / UIKit**: On UIKit, implement as a `UIViewController` with a scroll view containing a stack view (horizontal or vertical) for the header (image view, vertical stack for identity), followed by nested stack views for metadata, keywords, contact, fields, and links; use `UILabel` for display name and summary, and `UIStackView` for fields and metadata rows. On AppKit, use an `NSScrollView` with an `NSStackView` hierarchy of the same shape, `NSTextField` (non-editable, bezel-less) in place of `UILabel`, and `NSImageView` for the photo. Delegate field rendering to a FieldValue view (see [adhsdk.ingredient.registry-profile.field-value](cookbook:6579e030-0455-453c-81cf-177dae3dd82e)). This component defines no deep linking (see Deep Linking above); do not add custom URL scheme or universal link handling here. Render the visibility marker inline within the field label's text/stack item, not as an overlay on the field row, matching the inline-in-label design decision.
- **WinUI 3**: Implement as a XAML UserControl or Page. Use Grid and StackPanel for layout: a StackPanel header contains an Image for the photo and a StackPanel for identity (TextBlock for name, TextBlock for summary). Use `ItemsControl`/`ItemsRepeater` for the metadata definition list, rendering each row as a Grid with two TextBlocks, and the same for fields, with a custom `DataTemplate` that includes a TextBlock for the label, a conditional TextBlock for the visibility marker, and a custom FieldValue control for the value — WinUI 3 has no `DataGrid` control. Use `ItemsControl` for keywords, styling each as a Border with a TextBlock. Conditionally include a ContentPresenter for the contact affordance. Render links as a ListView or ItemsControl with HyperlinkButton controls, opening each with `Launcher.LaunchUriAsync(uri)`; WinUI 3 opens external URIs out-of-process, so there is no `rel="noopener"` equivalent to set.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/registry-profile/src/RegistryProfile.tsx` | unverified |

## Design Decisions

- **Decision**: The component accepts an optional `resolveImageUrl` function rather than fetching images directly, falling back to the `entry.imageUrls` map when no resolver is supplied.
  **Rationale**: This allows the host to control image delivery (CDN, proxy, storybook fixtures) without the component knowing which is in use. The fallback to `entry.imageUrls` supports the common case where the backend already resolved all URLs. This design keeps the component decoupled from the host's infrastructure.
  **Approved**: pending

- **Decision**: Visibility markers are rendered inside the `<dt>` field label, not floated beside the field value.
  **Rationale**: This ensures a reader who encounters the marker has not already read a value they believed was public. The marker placement is a compromise between making the visibility constraint immediately visible and avoiding layout reflow.
  **Approved**: pending

- **Decision**: The `AUDIENCE_NOTE` Record is exhaustive on `FieldVisibility`, so adding a new visibility type to the enum without defining its marker text is a TypeScript compile error rather than a silently unmarked field.
  **Rationale**: This prevents silent rendering of unmarked fields, which is the failure mode that matters most (an unmarked field reads as public).
  **Approved**: pending

- **Decision**: The component assumes the server has already filtered out fields the viewer is not authorized to see, and renders every field in `entry.fields` with no additional client-side hiding.
  **Rationale**: Rendering only the fields in `entry.fields` is safe because the server removes inaccessible ones. The component does not hide fields in CSS or conditionally skip rendering, which would leave values in the markup where view-source tools could find them.
  **Approved**: pending

- **Decision**: The `contact` prop is a slot (a React node), not a callback function.
  **Rationale**: This gives the host full control over what contact experience is rendered (the hub messaging composer on an ADH site, no contact on an embedder's site). The slot pattern decouples the component from knowing which contact implementation is in use.
  **Approved**: pending

- **Decision**: Field labels come from `entry.fields[*].label`, which the server provides; the component does not localize these labels itself.
  **Rationale**: The server is responsible for providing labels in the viewer's language. This keeps localization out of the presentation layer.
  **Approved**: pending

- **Decision**: The display name always renders as an `<h1>`, with no prop to change the heading level.
  **Rationale**: The component assumes it is rendered as the top-level content of the page or view presenting the entry, matching how it is used today. A host that embeds it inside a page with its own `<h1>` accepts a duplicate top-level heading; the component does not currently offer a way to renumber it.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

These statuses rest on `RegistryProfile.tsx`: it sets `href` on every link from `entry.links[*].url` with `rel="noopener noreferrer nofollow"` and `target="_blank"` but no scheme check (input-sanitization partial, see **Link URL scheme is not restricted** above); it renders semantic `<article>`, `<header>`, `<dl>`/`<dt>`/`<dd>`, and `<nav aria-label="Elsewhere">` elements with a decorative empty `alt` on the photo and text-or-fallback labels on every link (screen-reader-support, keyboard-navigable, semantic-markup all passed); it applies no inline color or font size of its own, leaving contrast and dynamic type up to CSS classes this file does not define (both partial); and it hardcodes "Category", "Location", "Languages", "Elsewhere", and the `AUDIENCE_NOTE` marker strings as English literals rather than reading them from a resource file (string-externalization and no-hardcoded-strings both failed), while every other string the component displays (`displayName`, `summary`, `category`, `locationText`, `languages`, `keywords`) is passed through untouched (unicode-support passed). Field rendering is delegated to `FieldValue`, and the image-URL resolver is a small overridable default rather than embedded fetch logic (separation-of-concerns passed); `RegistryProfile.test.tsx` directly exercises every field, the audience marker, the contact slot, image resolution (default map, missing id, host override), and services rendering (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed every requirement to subject-only kebab-case (dropped `must-`/`must-not-` prefixes) and fixed the backwards `omit-marker-for-public-fields` wording; restated the default-resolver requirement to describe the `entry.imageUrls` fallback rather than a resolver return contract; clarified that empty `services` rendering is delegated to `ServiceList`; corrected the false "metadata list omitted when empty" claim (the `<dl>` container always renders) and promoted it, plus the fields-empty and no-truncation edge cases, to named requirements; removed the incorrect claim that a missing photo and an unresolvable photo render distinguishably; documented the unrestricted link URL scheme as an edge case; added a Design Decision for the fixed `<h1>` heading level; added `depends-on`/`related` links to the field-value and service-list recipes and linked them inline; unquoted `modified` to match `created`; replaced the "Not applicable" Compliance section with a real Check/Status/Category table; reformatted Design Decisions into Decision/Rationale/Approved triplets; added missing test vectors (service-list, default-resolver, accept-null-from-resolver, links-empty, location-absent, fields-empty, no-truncation, metadata-list-unconditional) and sharpened profile-020 into a concrete assertion; fixed the SwiftUI, Compose, AppKit/UIKit, and WinUI 3 platform notes to reference real APIs and added AppKit-specific guidance; and corrected Localization to state the strings are hardcoded literals, not read from a resource system. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
