---
id: fe09968a-6575-40d0-b0b8-af6ce52d8efd
title: "Service List"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Displays a list of services with titles, descriptions, and formatted pricing information."
platforms:
  - typescript
  - web
tags:
  - list
  - services
  - pricing
depends-on: []
related:
  - 6c034a7a-3a43-4da6-bc1a-0cbc39f32cc4
  - 6579e030-0455-453c-81cf-177dae3dd82e
references: []
approved-by: ""
approved-date: ""
---

# Service List

## Overview

The Service List component displays a collection of services with their titles, optional descriptions, and formatted pricing. It renders as a semantic section containing an unordered list of service items. When the services array is empty, the component renders nothing.

## Behavioral Requirements

- **render-section**: Component MUST render a `<section>` element when the services array contains one or more items.
- **hide-when-empty**: Component MUST NOT render any output when the services array is empty (`services.length === 0`). The `services` prop is a required array; passing `null` or `undefined` is outside the documented contract (see Edge Cases).
- **render-heading**: Component MUST render an `<h2>` heading with the text "Services" within the section. This text is currently a hardcoded literal, not read from a string-key lookup (see the **string-externalization** compliance status).
- **render-list**: Component MUST render an unordered list (`<ul>`) containing one list item per service.
- **display-title**: Component MUST display each service's title as an `<h3>` heading within the list item.
- **display-price**: Component MUST display each service's formatted price using the priceText formatter (see **pricing-free**, **pricing-barter**, **pricing-rate-on-request**, **pricing-range**, **pricing-single-value**, and **pricing-suffix** for the individual formatting rules).
- **display-description**: Component SHOULD display each service's description text when the description property is present and non-empty.
- **semantic-elements**: Component MUST NOT wrap rendered content in non-semantic containers (e.g. generic `<div>` elements). The only elements it renders are `<section>`, `<h2>`, `<ul>`, `<li>`, `<h3>`, and `<p>`.
- **pricing-free**: Component MUST display "Free" when `pricingModel` is `free`, bypassing numeric formatting entirely.
- **pricing-barter**: Component MUST display "Trade or barter" when `pricingModel` is `barter`, bypassing numeric formatting entirely.
- **pricing-rate-on-request**: Component MUST display "Rate on request" when both `priceMin` and `priceMax` are absent and `pricingModel` is neither `free` nor `barter`.
- **pricing-range**: Component MUST display a formatted range (`{min}–{max}`, en dash, no surrounding spaces) when both `priceMin` and `priceMax` are present and differ. Each bound is formatted as currency via `Intl.NumberFormat` with `maximumFractionDigits: 0` and the service's `currency` (defaulting to `USD` when absent).
- **pricing-single-value**: Component MUST display a single formatted currency value — using whichever of `priceMin`/`priceMax` is present — when only one bound is present, or when both bounds are present and equal.
- **pricing-suffix**: Component MUST append a trailing suffix to the formatted price: "per hour" (`hourly`), "per job" (`per_job`), "per deliverable" (`per_deliverable`), "per month" (`subscription`). Component MUST omit the suffix (display the amount alone) when `pricingModel` matches none of these four values.
- **unique-titles**: The `services` array MUST contain unique `title` values. The component uses `service.title` as its React iteration key; duplicate titles are unsupported for stable list reconciliation (see **unique-titles** under Design Decisions).

## Appearance

- **Corner radius**: None (component uses browser default)
- **Padding**: Defined by CSS classes, not inline styles: `rp-services` (section), `rp-services__heading` (h2), `rp-services__list` (ul), `rp-service` (li), `rp-service__title` (h3), `rp-service__description` (p, conditional), `rp-service__price` (p)
- **Font**: Inherited from parent; no inline font styling applied
- **Background**: Inherited from parent; no inline background color applied
- **Foreground/Text**: Inherited from parent; no inline text color applied
- **Border**: None applied by component
- **Shadow**: None applied by component
- **Min/Max size**: No constraints applied by component

## States

| State | Appearance change |
|-------|------------------|
| Default | Services displayed in list format |
| Empty | No output rendered |

## Accessibility

- **Role**: The component uses semantic HTML (`<section>`, `<h2>`, `<ul>`, `<li>`, `<h3>`, `<p>`), which provides correct semantic roles to assistive technologies.
- **Heading hierarchy**: Uses `<h2>` for "Services" section heading and `<h3>` for individual service titles, maintaining proper document outline.
- **List structure**: Unordered list markup provides clear list semantics to screen readers.
- **Text content**: All text content (titles, descriptions, prices) is marked up as text, not images or non-semantic elements.
- **No interactive elements**: This component contains no interactive controls; it is a static display component.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| service-list-001 | render-section, render-heading, render-list | services = [{title: "Web Design", description: "Custom website design", pricingModel: "hourly", priceMin: 75, priceMax: 150, currency: "USD"}] | Renders `<section class="rp-services">` with `<h2 class="rp-services__heading">Services</h2>` and `<ul class="rp-services__list">` |
| service-list-002 | display-title, display-price, display-description, pricing-range, pricing-suffix | services = [{title: "Web Design", description: "Custom website design", pricingModel: "hourly", priceMin: 75, priceMax: 150, currency: "USD"}] (locale: en-US, as hardcoded by priceText) | Renders `<h3>Web Design</h3>`, `<p>Custom website design</p>`, and price as "$75–$150 per hour" |
| service-list-003 | display-price, pricing-free | services = [{title: "Consultation", pricingModel: "free"}] | Renders price text as "Free" |
| service-list-004 | display-price, pricing-barter | services = [{title: "Trade Services", pricingModel: "barter"}] | Renders price text as "Trade or barter" |
| service-list-005 | display-price, pricing-rate-on-request | services = [{title: "Custom Rate", pricingModel: "hourly"}] (with no priceMin/priceMax) | Renders price text as "Rate on request" |
| service-list-006 | display-description | services = [{title: "Service Name", description: null}] | Does not render description paragraph |
| service-list-007 | hide-when-empty | services = [] | Component returns null; no output rendered |
| service-list-008 | semantic-elements | Any valid services array | Every rendered element is one of `<section>`, `<h2>`, `<ul>`, `<li>`, `<h3>`, `<p>` — no other element type appears |
| service-list-009 | pricing-single-value | services = [{title: "Equal Bound", pricingModel: "hourly", priceMin: 100, priceMax: 100, currency: "USD"}] | Renders price text as "$100 per hour" (single value, not a range, since priceMin equals priceMax) |
| service-list-010 | pricing-single-value | services = [{title: "Min Only", pricingModel: "hourly", priceMin: 50, currency: "USD"}] (priceMax absent) | Renders price text as "$50 per hour" |
| service-list-011 | pricing-single-value | services = [{title: "Max Only", pricingModel: "hourly", priceMax: 200, currency: "USD"}] (priceMin absent) | Renders price text as "$200 per hour" |
| service-list-012 | pricing-suffix | services = [{title: "Job Based", pricingModel: "per_job", priceMin: 300, currency: "USD"}] | Renders price text as "$300 per job" |
| service-list-013 | pricing-suffix | services = [{title: "Deliverable Based", pricingModel: "per_deliverable", priceMin: 500, currency: "USD"}] | Renders price text as "$500 per deliverable" |
| service-list-014 | pricing-suffix | services = [{title: "Subscription Based", pricingModel: "subscription", priceMin: 20, currency: "USD"}] | Renders price text as "$20 per month" |
| service-list-015 | pricing-suffix | services = [{title: "Unknown Model", pricingModel: "quote_only", priceMin: 40, currency: "USD"}] | Renders price text as "$40" with no trailing suffix, since "quote_only" matches no entry in the suffix map |
| service-list-016 | unique-titles | services = [{title: "Duplicate", pricingModel: "free"}, {title: "Duplicate", pricingModel: "barter"}] | Both items render on the initial render; duplicate titles used as the React key are unsupported for stable reconciliation across re-renders |

## Edge Cases

- **Empty services array**: Component returns null and renders nothing when `services.length === 0` — see **hide-when-empty** (reference implementation: `ServiceList.tsx`).
- **Single service**: Component correctly renders section, heading, and list with one item.
- **Missing description**: Component conditionally renders the description paragraph only when `service.description` is truthy — see **display-description** (reference implementation: the conditional check in `ServiceList.tsx`).
- **Non-array or null `services`**: The `services` prop is typed as a required array; the component reads `services.length` without a null guard. Passing `null` or `undefined` is outside the documented contract and throws at runtime rather than rendering nothing.
- **Price edge cases**: The `priceText` function (in `ServiceList.tsx`) handles free, barter, absent bounds, equal bounds, and range pricing — see **pricing-free**, **pricing-barter**, **pricing-rate-on-request**, **pricing-single-value**, and **pricing-range**.
- **Unknown pricing model**: An unrecognized `pricingModel` still formats the numeric amount but omits a suffix — see **pricing-suffix**.
- **Currency formatting**: Uses `Intl.NumberFormat('en-US', ...)` with `maximumFractionDigits: 0` to format prices (no decimal places). The locale is hardcoded to `en-US` regardless of the host's locale — see the **locale-aware-formatting** compliance status.
- **List key**: Component uses `service.title` as the React key — see **unique-titles**.

## Configuration

Not applicable: Component accepts a single `services` prop array as input; no configuration options or settings exposed.

## Deep Linking

Not applicable: This component is a display component with no interactive navigation or state that would warrant deep linking.

## Localization

The strings below document the intended externalization targets. The current source (`ServiceList.tsx`) hardcodes each of them directly as literal English text — the "Services" heading and every pricing suffix — rather than reading them from a string-key lookup; see the **string-externalization** compliance status.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| services.heading | "Services" | Section heading text; hardcoded literal in `ServiceList.tsx` |
| pricing.free | "Free" | Displayed when pricingModel is "free" |
| pricing.barter | "Trade or barter" | Displayed when pricingModel is "barter" |
| pricing.rate_on_request | "Rate on request" | Displayed when both priceMin and priceMax are null |
| pricing.per_hour | "per hour" | Suffix displayed for hourly pricing model |
| pricing.per_job | "per job" | Suffix displayed for per_job pricing model |
| pricing.per_deliverable | "per deliverable" | Suffix displayed for per_deliverable pricing model |
| pricing.per_month | "per month" | Suffix displayed for subscription pricing model |

## Accessibility Options

- **Reduce Motion**: Not applicable. Component has no animations or motion effects.
- **Increase Contrast**: Component relies on CSS styling via classes; contrast requirements are handled by the CSS implementation, not the component.
- **Differentiate Without Color**: Component uses text and semantic markup; no information conveyed by color alone.

## Feature Flags

Not applicable: Component accepts data via props only; no feature flags control rendering behavior.

## Analytics

Not applicable: Component contains no analytics event tracking or user interaction handlers.

## Privacy

- **Data collected**: Component displays service data passed via props; does not collect user data.
- **Storage**: No local storage or persistent storage by component.
- **Transmission**: Component does not transmit data; it only displays data provided via props.
- **Retention**: No retention of data by component; rendering is stateless.

## Logging

Not applicable: Component contains no logging statements.

## Platform Notes

- **React/Web**: Renders semantic HTML using JSX. Uses `services.map()` to iterate over the array and `Intl.NumberFormat` for currency formatting. CSS classes (rp-services, rp-services__list, rp-service, etc.) handle styling. Key prop uses service.title; ensure titles are unique within the array to avoid React reconciliation issues.
- **SwiftUI**: Map the services array using a `List` with `ForEach`. Use `Section(header: Text("Services"))` for the heading. Display title with `Text` at heading level, description conditionally with `.lineLimit(nil)`, and price using a localized NumberFormatter configured for currency. Apply `.listStyle(.plain)` or appropriate list style.
- **Compose**: Use a `LazyColumn` or `Column` within a `Surface` for the section. Display the "Services" heading with appropriate typography style. Iterate services using `.forEach` and render `Row` or `Column` layouts for each item. Format price using NumberFormat or Locale-aware price formatting. Apply conditional rendering for description using `if (service.description != null)`.
- **AppKit / UIKit**: Use `UIStackView` (vertical axis) as the container, or `NSStackView` on macOS, with a `UILabel`/`NSTextField` for the "Services" heading. Render the item list with a plain `UITableView`, or a `UICollectionView` configured with `UICollectionLayoutListConfiguration`, rather than nesting a `UITableViewController`/`UICollectionViewController` inside the stack view — a view controller does not belong inside a stack view. For each service, render title as bold, description as regular text, and price formatted using `NumberFormatter` with currency style. Conditionally include description based on presence.
- **WinUI 3**: Use a `StackPanel` with `Orientation="Vertical"` as container. Add a `TextBlock` for the "Services" heading using the `SubtitleTextBlockStyle` theme resource rather than a hardcoded `FontSize`, so it follows the app's type ramp. Use an `ItemsControl` or `ListViewBase` bound to the services collection. For each item, template a `TextBlock` for title using `BodyStrongTextBlockStyle`, a conditional `TextBlock` for description using `BodyTextBlockStyle`, and a `TextBlock` for formatted price. Format price using `NumberFormatInfo` for the appropriate culture with `CurrencySymbol`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/registry-profile/src/ServiceList.tsx` | unverified |

## Design Decisions

**Decision**: Styling is delegated entirely to CSS classes (`rp-services`, `rp-services__heading`, `rp-services__list`, `rp-service`, `rp-service__title`, `rp-service__description`, `rp-service__price`) rather than inline styles.
**Rationale**: Keeps presentation separate from markup and lets styling be managed independently of the component.
**Approved**: pending

**Decision**: The React key for each list item is `service.title`; the component requires titles to be unique within a given `services` array rather than accepting a separate identifier prop (see **unique-titles**).
**Rationale**: The source has no `id` field on `PublicService` to key on instead; adding one would be new behavior beyond what the source implements today.
**Approved**: pending

**Decision**: Pricing formatting (`priceText`) stays inline in `ServiceList.tsx` rather than being extracted into a shared formatter ingredient.
**Rationale**: It currently has exactly one consumer; extracting it now would create a shared component with no second caller to validate the abstraction against. Revisit once another recipe needs the same formatting rules.
**Approved**: pending

**Decision**: The component renders nothing (`return null`) when `services.length === 0`, rather than rendering an empty section.
**Rationale**: Lets parent layouts collapse the section entirely instead of showing an empty heading with no content.
**Approved**: pending

**Decision**: The section and item heading levels are fixed at `<h2>` and `<h3>` rather than accepting a configurable heading level.
**Rationale**: The source hardcodes both levels; hosts embedding this component MUST place it at a point in the page outline where `<h2>` is the correct next heading level.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | partial | Internationalization |
| [adc.check.user-safety.content-moderation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f1e3ffdc-3e47-54d5-82c8-a1c266284959) | partial | User Safety |
| [adc.check.user-safety.reporting-mechanism](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7127c04-8ad0-5cdd-82f8-74e851f234b7) | partial | User Safety |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on `ServiceList.tsx`: it renders only semantic HTML tags with no inline color or font-size overrides (semantic-markup passes; dynamic-type-support and contrast-ratio are partial because actual scaling and contrast depend on the CSS classes it references, not shown here); it hardcodes the "Services" heading and every pricing suffix as literal English strings and hardcodes the `en-US` locale inside `Intl.NumberFormat` (string-externalization fails; locale-aware-formatting is partial since it uses a locale-aware API but with a fixed locale); and it renders whatever `title`/`description` text it is given, submitted by registry members, with no moderation step or reporting affordance of its own (content-moderation and reporting-mechanism are partial, since either could be handled upstream of this component). `separation-of-concerns` passes because the `priceText` formatting logic is factored into its own pure function, separate from the rendering, and `unit-test-coverage` is partial because `ServiceList` has no test of its own — it is exercised only indirectly, through its parent `RegistryProfile`, in `RegistryProfile.test.tsx`'s empty-services and priced-service cases.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from ServiceList.tsx source |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case, added named pricing/unique-title requirements, replaced line-number citations with symbol references, reformatted Design Decisions, added a Compliance table, added coverage/locale test vectors, fixed the UIKit/WinUI native-controls notes, and added related links to the registry-profile family |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
