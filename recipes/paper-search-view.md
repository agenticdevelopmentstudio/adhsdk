---
id: 968f66df-4c2d-47ba-92cf-ff1e34f5deb2
title: Paper Search View
domain: adhsdk://recipes/paper-search-view
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Searchable paper corpus interface with author filtering and customizable
  labels.
platforms:
- typescript
- web
tags:
- search
- papers
depends-on:
- adhsdk://recipes/search-view
related: []
references: []
approved-by: ''
approved-date: ''
---

# Paper Search View

## Overview

Paper Search View is a React component that provides a search interface for a public paper corpus. It wraps SearchView to handle paper-specific configuration, including API endpoint setup, document type registration, and author filtering. The component is designed to be mounted on both a corpus-wide search page and on individual author index pages, with the only difference being the optional `authorSlug` prop that narrows results to a single author.

## Behavioral Requirements

- **document-href-required**: Component MUST accept a required `documentHref` prop that is a function accepting a PaperSearchHit and returning a string representing the document's URL on the host.
- **search-source-configuration**: Component MUST configure a SearchSource with endpoints for results (`/public/papers`), tags (`/public/papers/tags`), and categories (`/public/papers/categories`).
- **no-store-cache-policy**: Component MUST set cache policy to `no-store` on fetch requests to ensure search results reflect the current corpus state.
- **author-slug-filter**: Component MAY accept an optional `authorSlug` prop; when provided, search results MUST be filtered to that author.
- **author-slug-normalization**: When `authorSlug` is provided, the component MUST trim it and convert it to lowercase before use. If the trimmed result is an empty string, the component MUST treat `authorSlug` as if it had not been provided (no `author` fixed param).
- **base-url-override**: Component MAY accept an optional `baseUrl` prop to override the default API prefix (defaults to same-origin `/api`).
- **default-search-label**: Component MAY accept an optional `searchLabel` prop; when omitted, defaults to `Search research papers`.
- **default-search-placeholder**: Component MAY accept an optional `searchPlaceholder` prop; when omitted, defaults to `Search papers…`.
- **default-landmark-label**: Component MAY accept an optional `searchLandmarkLabel` prop; when omitted, defaults to `Research paper search`.
- **document-type-registration**: Component MUST register `markdownDocumentType` as the document type for search results.
- **search-view-props**: Component MUST render the wrapped SearchView component, passing exactly these props: `source` (the configured SearchSource), `documentType`, `documentHref`, `searchLabel`, `searchPlaceholder`, and `searchLandmarkLabel`.
- **paper-search-source-factory**: The package MUST export `paperSearchSource(options?: { baseUrl?: string; authorSlug?: string }): SearchSource` as a standalone function producing the same SearchSource configuration the component uses internally, so a host can construct it without mounting the component.

## Appearance

Not applicable: Paper Search View is a wrapper component that delegates all visual rendering to the wrapped SearchView component. The appearance is determined entirely by SearchView's implementation.

## States

Not applicable: Paper Search View is a stateless wrapper component. All state management is handled by the wrapped SearchView component.

## Accessibility

Paper Search View owns the default accessible name (`Search research papers`) and landmark label (`Research paper search`) for the search control, expressed as the `searchLabel` and `searchLandmarkLabel` prop defaults (see **default-search-label**, **default-landmark-label**). Together with `searchPlaceholder` (see **default-search-placeholder**), these are forwarded to the wrapped SearchView on every render (see **search-view-props**). SearchView implements the actual ARIA roles, keyboard interaction, and focus management, as described in its own recipe (adhsdk://recipes/search-view); this component's responsibility ends at supplying correct, overridable label text.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| psv-001 | document-href-required | PaperSearchViewProps with documentHref function | SearchView rendered with documentHref passed through |
| psv-002 | search-source-configuration | Default props (no baseUrl, no authorSlug) | SearchSource configured with endpoints `/public/papers`, `/public/papers/tags`, `/public/papers/categories` and baseUrl `/api` |
| psv-003 | no-store-cache-policy | Any props | SearchSource fetchInit set to `{ cache: 'no-store' }` |
| psv-004 | author-slug-filter | PaperSearchViewProps with authorSlug='author-name' | SearchSource fixedParams includes `{ author: 'author-name' }` (already lowercase) |
| psv-005 | base-url-override | PaperSearchViewProps with baseUrl='/custom/api' | SearchSource baseUrl set to `/custom/api` |
| psv-006 | default-search-label | PaperSearchViewProps with searchLabel='Custom label' | SearchView receives searchLabel='Custom label' |
| psv-007 | default-search-label | PaperSearchViewProps without searchLabel | SearchView receives searchLabel='Search research papers' |
| psv-008 | default-search-placeholder | PaperSearchViewProps with searchPlaceholder='Custom…' | SearchView receives searchPlaceholder='Custom…' |
| psv-009 | default-search-placeholder | PaperSearchViewProps without searchPlaceholder | SearchView receives searchPlaceholder='Search papers…' |
| psv-010 | default-landmark-label | PaperSearchViewProps with searchLandmarkLabel='Custom landmark' | SearchView receives searchLandmarkLabel='Custom landmark' |
| psv-011 | default-landmark-label | PaperSearchViewProps without searchLandmarkLabel | SearchView receives searchLandmarkLabel='Research paper search' |
| psv-012 | document-type-registration | Any props | SearchView receives documentType=markdownDocumentType |
| psv-013 | author-slug-normalization | PaperSearchViewProps with authorSlug='  Jane Doe  ' | SearchSource fixedParams includes `{ author: 'jane doe' }` |
| psv-014 | author-slug-normalization | PaperSearchViewProps with authorSlug='   ' (whitespace only) | SearchSource has no `fixedParams.author` key |
| psv-015 | paper-search-source-factory | `paperSearchSource()` called directly with no options | Returns `{ baseUrl: '/api', endpoints: { results: '/public/papers', tags: '/public/papers/tags', categories: '/public/papers/categories' }, fetchInit: { cache: 'no-store' } }` with no `fixedParams` key |
| psv-016 | search-view-props | Any props | SearchView rendered with exactly the props source, documentType, documentHref, searchLabel, searchPlaceholder, searchLandmarkLabel — no others |

## Edge Cases

- **Missing documentHref**: `documentHref` is a required, non-optional prop with no runtime default. This is a type-level constraint enforced by the TypeScript compiler at call sites, not an observable runtime behavior, so it has no conformance test vector.
- **authorSlug whitespace**: See **author-slug-normalization** — authorSlug is trimmed and lowercased before being passed to fixedParams, and an empty string after trimming is treated as authorSlug not having been provided.
- **baseUrl override**: When baseUrl is provided, it MUST override the default `/api` value. No validation of baseUrl format is performed by the component.
- **Label customization**: The searchLabel, searchPlaceholder, and searchLandmarkLabel props exist to support host-specific terminology. The component MUST NOT validate or modify these values.
- **Empty corpus response**: No edge case handling is specified for empty search results; this is handled by SearchView.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| documentHref | `(hit: PaperSearchHit) => string` | Required | URL mapping function for search result links |
| authorSlug | `string` | undefined | Author slug to filter corpus results |
| baseUrl | `string` | `/api` | API prefix override |
| searchLabel | `string` | `Search research papers` | Accessible label for search input |
| searchPlaceholder | `string` | `Search papers…` | Placeholder text for search input |
| searchLandmarkLabel | `string` | `Research paper search` | Landmark label for search region |

## Deep Linking

Not applicable: Paper Search View is a search interface component. Deep linking to specific papers is handled by the documentHref prop, which is configured by the host application to route to the appropriate paper pages.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| searchLabel | `Search research papers` | Accessible label for the search field |
| searchPlaceholder | `Search papers…` | Placeholder text shown in search input |
| searchLandmarkLabel | `Research paper search` | Landmark/region label for accessibility |

## Accessibility Options

Not applicable: Paper Search View is a wrapper component. Accessibility option support (Reduce Motion, Increase Contrast, Differentiate Without Color) is implemented by SearchView. The component passes through the necessary labels to support keyboard and screen reader navigation.

## Feature Flags

Not applicable: Paper Search View does not implement feature flags. Feature flag behavior, if any, is managed by SearchView or the underlying backend API.

## Analytics

Not applicable: Paper Search View does not directly emit analytics events. Analytics tracking is the responsibility of the wrapped SearchView component.

## Privacy

Not applicable: Paper Search View does not collect, store, or transmit sensitive user data. It is a stateless wrapper that passes requests through to SearchView and the backend API. Privacy obligations belong to SearchView and the search backend.

## Logging

Not applicable: Paper Search View does not implement logging. Any debug or error logging is handled by SearchView or the backend API.

## Platform Notes

- **Web**: PaperSearchView is defined in `packages/web/packages/search/src/components/PaperSearchView.tsx`. It is a React functional component that wraps SearchView (`./SearchView`). The `paperSearchSource` helper function constructs the SearchSource configuration (see **paper-search-source-factory**). Developers import both `PaperSearchView` and `paperSearchSource` directly.
- **SwiftUI**: Implement as a SwiftUI View using `.searchable(text:prompt:)` to drive the search field, wrapping an underlying SearchView implementation configured with the same parameters (documentHref closure, authorSlug, baseUrl, label customizations). Because there is no same-origin browsing context on Apple platforms, `baseUrl` MUST be supplied as an absolute URL rather than defaulting to `/api`.
- **Compose**: Implement as a Composable function accepting the same parameters as the web component. Use Compose Material 3 `SearchBar` or similar native component for the search field, and configure the underlying SearchView Composable with the provided SearchSource configuration. As on other native platforms, `baseUrl` MUST be an absolute URL — there is no same-origin default to fall back to.
- **AppKit / UIKit**: Implement as a view controller or view class wrapping `NSSearchField` (AppKit) or `UISearchBar` (UIKit). Accept the same configuration parameters and configure the underlying SearchView implementation with the SearchSource endpoints and options. `baseUrl` MUST be supplied as an absolute URL on these platforms; there is no same-origin browser context to default from.
- **WinUI 3**: Implement as a UserControl wrapping the native WinUI 3 SearchView port (an `AutoSuggestBox`-based control) configured with the same parameters as the other platforms (documentHref callback, authorSlug, baseUrl, label customizations), rather than querying the SearchSource endpoints directly. Set `AutoSuggestBox.PlaceholderText` from `searchPlaceholder`, use `AutomationProperties.LandmarkType="Search"` together with `AutomationProperties.Name` (from `searchLandmarkLabel`) for the accessible landmark, and use `searchLabel` as the control's accessible name. Because there is no same-origin browser context, `baseUrl` MUST be supplied as an absolute URL — never default to `/api`. Bind `documentHref` as a navigation callback when results are selected.

## Design Decisions

**Decision**: Paper Search View exists as a wrapper component that centralizes SearchSource configuration and prop defaults in one place, rather than letting each mount point (corpus-wide search page, author index page) configure its own SearchView.
**Rationale**: This prevents configuration drift between mounting contexts — without a single wrapper, "the author page searches something slightly different from /search" is a one-line drift away. This prioritizes consistency over flexibility: local customization goes through the explicit props interface rather than direct SearchView configuration at the call site.
**Approved**: pending

**Decision**: The accessible names (`searchLabel`, `searchPlaceholder`, `searchLandmarkLabel`) are props with string defaults, not literals baked into SearchView.
**Rationale**: The package owns the UI but the host owns the words. This lets the same component mount on multiple sites, or in multiple languages, without modification, delegating vocabulary choices to the host application.
**Approved**: pending

**Decision**: `documentHref` is required at every call site rather than derived from configuration.
**Rationale**: This implements the LINK seam documented in `packages/web/packages/search/src/types.ts` (one of the package's three configurable seams: SCOPE/SOURCE, DOCUMENT-TYPE, and LINK) — the URL space belongs to the host, not the search package, because the same corpus is addressed differently on different hosts and the component must not assume or prescribe the URL scheme.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | partial | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`screen-reader-support` rests on the component always supplying `searchLabel`/`searchLandmarkLabel` values (defaulted or host-provided) to the wrapped SearchView on every render. The two internationalization checks are `partial` because `PaperSearchView.tsx` sets the English strings as literal default parameter values rather than resource-file entries — the props exist precisely so a host can override them per locale, but the source cannot show that any host does; `PaperSearchView.tsx` is a thin wrapper delegating to `SearchView`, with the search-source/slug-normalization logic living in the separately exported `paperSearchSource` function (separation-of-concerns: passed), while `buildSearchUrl.test.ts` and `paperSearchSource.test.ts` thoroughly exercise that helper logic but no test renders `PaperSearchView` itself (unit-test-coverage: partial).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed all requirements to subject-only kebab-case; added author-slug-normalization and paper-search-source-factory requirements with vectors; reworded search-view-props to list exact props with a vector; reworded the missing-documentHref edge case as a type-level constraint; filled in Accessibility and Compliance sections; reformatted Design Decisions into Decision/Rationale/Approved blocks; defined the LINK seam by its source in types.ts; corrected the SwiftUI and WinUI 3 platform notes and added a native absolute-baseUrl note to all native platforms; added depends-on for search-view |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation (drafted by Claude Haiku 4.5) |
