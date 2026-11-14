---
id: e3a2394d-d0d0-4495-bde4-59197f9d7866
title: "Avatar"
type: ingredient
version: 1.3.0
status: review
language: en
created: 2026-09-22
modified: 2026-11-13
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Thin wrapper around Base UI's Avatar primitive (Root/Image/Fallback) exposing stable adh-avatar* classes as a public theming surface."
platforms:
  - macos
  - typescript
  - web
tags:
  - component
  - avatar
  - ui
depends-on: []
related: []
references:
  - https://base-ui.com/react/components/avatar
  - https://learn.microsoft.com/en-us/windows/winui/api/microsoft.ui.xaml.controls.personpicture
approved-by: ""
approved-date: ""
---

# Avatar

## Overview

`Avatar` is the shared avatar ingredient in `@adh-sdk/ui`: a thin,
three-part wrapper around Base UI's `Avatar` primitive (`@base-ui/react/avatar`),
the reference implementation for this ingredient's delegated behavior. It exports
`Avatar` (wraps `Avatar.Root`), `AvatarImage` (wraps `Avatar.Image`), and
`AvatarFallback` (wraps `Avatar.Fallback`). Each wrapper's only job is to apply
one of the semantic classes `adh-avatar`, `adh-avatar__image`, or
`adh-avatar__fallback` (merged with any consumer-supplied `className`) and
forward every other prop unchanged to the underlying Base UI primitive. The
module is a client component (`'use client'`). The source comment at
`avatar.tsx` documents why the class names must stay stable: "Base UI
avatar styled through the SEMANTIC `adh-avatar*` classes (skinned in
`../styles/components.css`): the class names are a public theming surface for
the theme editor and user CSS themes, so they stay stable hooks in the DOM."

<!-- appkit-avatar -->
**AppKit (`AvatarView`).** The macOS face of the same ingredient is `AvatarView` in `AgenticDeveloperHubSDKMacOS` (`macOS/UI/Avatar/`): a round view showing a picture when one loads and initials on a coloured circle until then and whenever it does not. It is drawn from an `AvatarContent` (`name`, `seed`, `imageURL`) rather than any feature's user type, so the Accounts settings and the git window's commit authors share it. The circle's colour comes from a stable hash of `seed` over the [commit graph cell](cookbook:595f1a5e-0f92-49c5-a980-af6f809be932)'s lane palette, from the [theme engine](cookbook:0e35ddf2-3e87-4a5a-9fd9-24bafc7325b6).

## Behavioral Requirements

- **render-root-with-semantic-class**: `Avatar` MUST render Base UI's `Avatar.Root` (`AvatarPrimitive.Root`) with the class name `adh-avatar` applied.
- **render-image-with-semantic-class**: `AvatarImage` MUST render Base UI's `Avatar.Image` (`AvatarPrimitive.Image`) with the class name `adh-avatar__image` applied.
- **render-fallback-with-semantic-class**: `AvatarFallback` MUST render Base UI's `Avatar.Fallback` (`AvatarPrimitive.Fallback`) with the class name `adh-avatar__fallback` applied.

These three class names are the public theming surface quoted in Overview — stable DOM hooks consumed by the theme editor and user CSS themes — so renaming any of `adh-avatar`, `adh-avatar__image`, or `adh-avatar__fallback` is a breaking change for every theme built against them, not a local refactor.

- **merge-consumer-classname**: Each of `Avatar`, `AvatarImage`, and `AvatarFallback` MUST merge a consumer-supplied `className` prop with its own semantic class name (via the `cn` helper imported from `../lib/utils`) rather than dropping either class.
- **forward-remaining-props**: Each of `Avatar`, `AvatarImage`, and `AvatarFallback` MUST forward every prop other than `className` unchanged to its underlying Base UI primitive.
- **load-as-client-module**: The module MUST be marked `'use client'`, so `Avatar`, `AvatarImage`, and `AvatarFallback` render as client components. This is verified by a static check for the `'use client'` directive at the top of `avatar.tsx`, not by a runtime conformance test vector.

<!-- appkit-avatar -->
AppKit `AvatarView`:

- **appkit-content**: `content` (`AvatarContent?`) MUST drive the view: setting a different value MUST cancel any load in flight, show the initials and start a load for `imageURL`; setting an equal value MUST do nothing.
- **appkit-initials**: The initials MUST be the uppercased first letters of `name`'s first two whitespace-separated words, else the uppercased first letter of `seed`, else `?`.
- **appkit-no-url-no-fetch**: An `imageURL` of `nil` MUST never call the fetch.
- **appkit-picture**: A fetch answering 2xx (or a non-HTTP response) with bytes that decode as an image MUST replace the initials with the picture; an error, a non-2xx answer (even one that decodes) or undecodable bytes MUST leave the initials up and log at debug level.
- **appkit-retry**: Moving into a window while no picture is showing MUST retry the load; a picture already showing MUST NOT be fetched again.
- **appkit-colour**: The circle MUST be filled with `SemanticPalette.laneColor(i)`, `i` the FNV-1a 64-bit hash of `seed`'s UTF-8 bytes modulo 12, so one person keeps one colour across launches; it MUST repaint on theme change.
- **appkit-side**: `init(side:fetch:)` MUST size the view to `side × side` (default 48 pt) with corners of radius `side / 2`.
- **appkit-fetch-seam**: The fetch MUST be injectable (`Fetch = @Sendable (URL) async throws -> (Data, URLResponse)`); the default goes through `URLSession.shared`, whose HTTP cache follows the server's headers, and the view keeps no cache of its own.

## Appearance

Not applicable: Component applies only semantic class names; styling values are defined externally in `../styles/components.css` and are outside this wrapper's scope.

<!-- appkit-avatar -->
AppKit `AvatarView`: a `side × side` circle; initials in the theme's `onAccentText` role, `heading` text role, semibold, centred, on the lane colour for `seed`; the picture fills the circle, scaled proportionally, clipped round.

## States

Not applicable: Component is a stateless rendering wrapper; interactive state management is delegated to Base UI's Avatar primitives.

<!-- appkit-avatar -->
AppKit `AvatarView`:

- **Empty**: no content; an empty coloured circle.
- **Initials**: content shown, no picture (no URL, loading, or failed).
- **Picture**: the picture loaded and replaced the initials.

## Accessibility

The wrapper adds no accessibility defaults of its own — it forwards every prop unchanged — so these obligations fall on the consumer:

- **Required `alt`**: `AvatarImage` forwards `alt` unchanged to Base UI's `Avatar.Image`, which renders it on the underlying `<img>`; consumers MUST supply a meaningful `alt` value, since the wrapper performs no validation or default of its own.
- **Decorative fallback**: `AvatarFallback` forwards `children` unchanged to Base UI's `Avatar.Fallback` with no default `aria-hidden`; consumers SHOULD mark fallback content `aria-hidden="true"` when it is purely decorative (e.g., initials that duplicate a name already shown as text elsewhere), to avoid a redundant screen-reader announcement.

<!-- appkit-avatar -->
AppKit `AvatarView`: role `image`, label `Avatar for <name>`, default identifier `avatar`, which a host replaces (Accounts uses `accounts.detail.avatar`).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| avatar-001 | render-root-with-semantic-class | Render `<Avatar />` with no props | Rendered root element has class `adh-avatar` |
| avatar-002 | render-image-with-semantic-class | Render `<Avatar><AvatarImage src="<1x1 stub already loaded>" /></Avatar>` | Rendered image element has class `adh-avatar__image` |
| avatar-003 | render-fallback-with-semantic-class | Render `<Avatar><AvatarFallback /></Avatar>` | Rendered fallback element has class `adh-avatar__fallback` |
| avatar-004 | merge-consumer-classname | Render `<Avatar className="ring-2" />` | Rendered root element has both `adh-avatar` and `ring-2` classes |
| avatar-005 | merge-consumer-classname | Render `<Avatar><AvatarImage className="opacity-0" src="<1x1 stub already loaded>" /></Avatar>` | Rendered image element has both `adh-avatar__image` and `opacity-0` classes |
| avatar-006 | merge-consumer-classname | Render `<Avatar><AvatarFallback className="bg-muted" /></Avatar>` | Rendered fallback element has both `adh-avatar__fallback` and `bg-muted` classes |
| avatar-007 | forward-remaining-props | Render `<Avatar data-testid="a1" />` | Rendered root element carries `data-testid="a1"` |
| avatar-008 | forward-remaining-props | Render `<Avatar><AvatarImage alt="Ada Lovelace" src="<1x1 stub already loaded>" /></Avatar>` | Rendered image element carries `alt="Ada Lovelace"` |

<!-- appkit-avatar -->
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| avatar-101 | appkit-picture | 200 with image bytes | picture shown. |
| avatar-102 | appkit-picture | 404 with image bytes | initials stay. |
| avatar-103 | appkit-picture | 200 with `<html>` | initials stay. |
| avatar-104 | appkit-retry | offline, then 200; view added to a window | 2 fetches, picture shown. |
| avatar-105 | appkit-retry | 200; view added to a window after loading | 1 fetch, no load in flight. |
| avatar-106 | appkit-no-url-no-fetch | content with `imageURL` nil | 0 fetches, initials shown. |
| avatar-107 | appkit-initials | name `ada lovelace byron`; name blank, seed `zed@b.c`; both empty | `AL`; `Z`; `?`. |
| avatar-108 | appkit-colour | seeds ``, `ada@x.y`, `b` | palette indices 5, 6, 1. |
| avatar-109 | appkit-side | `side` 20 | fitting size 20 × 20. |

## Edge Cases

- **Null/empty `className`**: `Avatar`, `AvatarImage`, and `AvatarFallback` MUST still render when `className` is omitted (`undefined`), passing `undefined` as the second argument to `cn`; the wrapper performs no validation of `className` before doing so.
- **No other props supplied**: `Avatar` MUST render correctly when called
  with no props beyond (or including) `className`, since `{...props}` is
  spread unconditionally and the wrapper performs no required-prop checking
  of its own. `AvatarImage` and `AvatarFallback` MUST likewise render
  correctly with no props beyond `className`, but only when nested inside
  `<Avatar>`: both delegate to a Base UI part that reads `Avatar`'s root
  context, so either one MUST throw ("Base UI: AvatarRootContext is
  missing. Avatar parts must be placed within `<Avatar.Root>`.") when
  rendered standalone, regardless of what other props it receives.
- **Boundary values**: Not applicable: Component defines no numeric, length, or size-constrained props of its own (e.g. no `size`, `min`, `max`); any such constraints belong to the underlying Base UI `Avatar.Root`/`Image`/`Fallback` API.
- **Concurrent access**: Not applicable: `Avatar`, `AvatarImage`, and `AvatarFallback` are stateless functional components with no internal state, refs, or module-level mutable data; each render is an independent, pure function call.
- **Error states**: `AvatarImage` MUST unmount when its underlying `<img>` fails to load, which is what reveals `AvatarFallback`; this load-failure-to-fallback handoff is Base UI's `Avatar.Image`/`Avatar.Fallback` behavior (`@base-ui/react/avatar`), not logic this wrapper adds.
- **Offline or disconnected state**: `AvatarImage` MUST fall back the same way whether a load failure is caused by an offline network or any other image-load error, because Base UI's Avatar has no separate retry or timeout path for network failures — a failed load unmounts `Avatar.Image` and reveals `Avatar.Fallback` exactly as in Error states above.

<!-- appkit-avatar -->
- **AppKit — replaced content mid-load**: setting new content cancels the old load, and a cancelled load never writes its picture or clears the new load's task.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `className` (on `Avatar`) | `string \| undefined` | `undefined` | Extra class merged with `adh-avatar` via `cn`. |
| `className` (on `AvatarImage`) | `string \| undefined` | `undefined` | Extra class merged with `adh-avatar__image` via `cn`. |
| `className` (on `AvatarFallback`) | `string \| undefined` | `undefined` | Extra class merged with `adh-avatar__fallback` via `cn`. |
| `...props` (on `Avatar`) | `AvatarPrimitive.Root.Props`, minus `className` | — | Forwarded unchanged to Base UI's `Avatar.Root`. |
| `...props` (on `AvatarImage`) | `AvatarPrimitive.Image.Props`, minus `className` | — | Forwarded unchanged to Base UI's `Avatar.Image`. |
| `...props` (on `AvatarFallback`) | `AvatarPrimitive.Fallback.Props`, minus `className` | — | Forwarded unchanged to Base UI's `Avatar.Fallback`. |

The wrapper forwards all other props to the underlying Base UI primitives unchanged. See `@base-ui/react/avatar` for the exhaustive `Avatar.Root.Props`, `Avatar.Image.Props`, and `Avatar.Fallback.Props` type definitions.

<!-- appkit-avatar -->
AppKit `AvatarView`:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `side` | `CGFloat` | `48` | Width and height of the circle. |
| `fetch` | `AvatarView.Fetch` | `URLSession.shared.data(from:)` | Loads a picture's bytes. |
| `content` | `AvatarContent?` | `nil` | `name`, `seed` (stable identity, e.g. an email) and `imageURL`. |

## Deep Linking

Not applicable: Component has no URL routing or deep linking logic.

## Localization

Not applicable: Component has no user-facing strings or localization concerns.

## Accessibility Options

Not applicable: Component does not respond to platform accessibility display options.

## Feature Flags

Not applicable: Component has no feature flag logic.

## Analytics

Not applicable: Component performs no analytics tracking.

## Privacy

- **Data collected**: None. `Avatar`, `AvatarImage`, and `AvatarFallback` perform no data collection of their own; they render whatever `src`/`children`/props a consumer supplies.
- **Storage**: None. This file contains no persistence logic.
- **Transmission**: Not applicable: Component has no transmission logic; any network requests for image loading are delegated to Base UI's `Avatar.Image` implementation.
- **Retention**: None. This file has no caching or retention logic of its own.

<!-- appkit-avatar -->
- **AppKit transmission**: `AvatarView` fetches only `imageURL`, and only when it is set; callers that must not reach the network (commit authors) pass `nil`.

## Logging

Not applicable: Component performs no logging.

<!-- appkit-avatar -->
AppKit `AvatarView` logs failed loads, non-2xx answers and undecodable bytes at debug level through its `Loggable` logger; the URL is never logged.

## Platform Notes

- **SwiftUI**: Start with `Image` and `Text` views in a container (e.g., `ZStack` or `Group`). SwiftUI has no built-in Avatar primitive, so composition is manual. Differs from web in requiring explicit state logic to toggle image visibility when loading or on error; web Avatar delegates this to Base UI's fallback reveal.
- **Compose**: Start with Coil's `AsyncImage` or standard `Image` composable for the image and a `Text` composable for fallback initials. Kotlin/Jetpack Compose has no built-in Avatar primitive, so composition is manual. Differs from web in requiring explicit error handling and fallback reveal within the composable; web delegates this to Base UI.
- **React/Web**: `Avatar`, `AvatarImage`, and `AvatarFallback` (`packages/web/packages/ui/src/components/avatar.tsx`) wrap Base UI's `Avatar.Root`, `Avatar.Image`, and `Avatar.Fallback` (`@base-ui/react/avatar`), applying the semantic classes `adh-avatar`, `adh-avatar__image`, and `adh-avatar__fallback` (skinned in `../styles/components.css`) merged with any consumer `className`, and forwarding all other props. The module is a client component (`'use client'`).
- **AppKit / UIKit**: Start with `NSImageView` (macOS) or `UIImageView` (iOS) for the image and `NSTextField`/`UILabel` or button for fallback initials. AppKit/UIKit have no built-in Avatar primitive, so composition is manual. Differs from web in requiring explicit visibility toggling and layout constraints; web Avatar delegates image-with-fallback reveal to Base UI.
- **WinUI 3**: A Windows developer would start from `Microsoft.UI.Xaml.Controls.PersonPicture`, the built-in WinUI 3 avatar control, since it natively provides the same image-with-initials-fallback contract that `Avatar`/`AvatarImage`/`AvatarFallback` compose from three separate Base UI primitives. The key difference: `PersonPicture` bakes the image/fallback decision into one control (via its `ProfilePicture`, `Initials`, and `DisplayName` properties) rather than exposing three independently composable Root/Image/Fallback pieces, so it cannot be skinned through three discrete semantic classes the way `adh-avatar`/`adh-avatar__image`/`adh-avatar__fallback` are; matching this ingredient's exact three-part composition on Windows instead requires a custom control built from an `Image` plus a `TextBlock` inside a `Border`/`Grid`, since WinUI 3 has no direct Root/Image/Fallback primitive split.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/avatar.tsx` | unverified |
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/UI/Avatar/AvatarView.swift` | confirmed (1.3.0) |

## Design Decisions

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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`unicode-support` passes because `AvatarFallback` forwards `children` unprocessed with no string manipulation of its own. `dynamic-type-support`, `contrast-ratio`, and `semantic-markup` are partial because sizing, color, and font scaling are defined externally in `../styles/components.css`, and ARIA semantics are owned by Base UI's `Avatar.Root`/`Image`/`Fallback` — none of which this wrapper's source can confirm. `text-expansion-tolerance` is partial because the wrapper imposes no width constraint of its own on fallback text, but the source also cannot show whether a caller-constrained layout truncates expanded text. Best-practices statuses rest on the wrapper being pure presentation delegating entirely to Base UI's `Avatar.Root`/`Image`/`Fallback` with no logic of its own (separation-of-concerns: passed), and on `dropdownMenu.test.tsx` directly rendering `Avatar`/`AvatarFallback` and asserting on the result (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.3.0 | 2026-11-13 | Mike Fullerton | Added the AppKit AvatarView (moved from Accounts, made public): AvatarContent input, initials rule, no fetch without an imageURL, retry on show, seed-hashed lane colour, configurable side. |
| 1.2.1 | 2026-09-25 | Mike Fullerton | avatar-003/006 vectors and the no-props Edge Case corrected: AvatarFallback/AvatarImage throw outside <Avatar> (Base UI AvatarRootContext), so vectors now nest them inside <Avatar>. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: dropped invented Base UI retry/timeout behavior in favor of the actual load-failure-to-fallback handoff; quoted the in-source comment once with its location instead of repeating unquoted references to it; replaced "refer to the source for details" pointers with inline behavior statements; documented the consumer-facing accessibility contract (required `alt`, decorative fallback) instead of marking Accessibility not applicable; deleted the duplicate class-name-stability requirement and folded its rationale into a note under the three class requirements; renamed all requirement names to subject-only kebab-case; fixed avatar-002/005/008 to nest `AvatarImage` inside `Avatar` with a loaded stub; moved the client-module check out of the conformance table to a static-check note and removed the source-text-only avatar-010 vector; reformatted Design Decisions into the three-line Decision/Rationale/Approved form; replaced the prose Compliance section with a checks table; rewrote MUST-tagged edge cases as normative MUST clauses; fixed the WinUI 3 bullet's "this recipe" noun; added reference URLs for Base UI Avatar and WinUI 3 PersonPicture |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Revise Phase 1: replace library-delegation markers with plain statements; update status to review |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
