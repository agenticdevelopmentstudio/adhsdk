---
id: d8ff2f23-db7f-49a9-8200-6328fa00033f
title: "Favicon"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A website's own icon, requested from the site itself by trying known icon paths in turn, or the caller's fallback glyph when none loads."
platforms:
  - typescript
  - web
tags:
  - component
  - favicon
  - ui
depends-on: []
related: []
references:
  - https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/winrt/microsoft.ui.xaml.controls.image
approved-by: ""
approved-date: ""
---

# Favicon

## Overview

`Favicon` draws the icon of a website next to a link. It takes any address on the site, keeps only its origin, and asks that origin for its icon, trying each entry of the exported `FAVICON_PATHS` list in order and keeping the first one that loads. When every candidate has failed, or the address is not a valid URL, it renders the caller's `fallback` (a glyph such as a globe), or nothing when no fallback is given. The source comment explains the two design points: there is no single place a site keeps its icon (`/favicon.ico` is the old convention, and a Next.js app that declares `app/icon.svg` or `app/icon.png` serves it at `/icon.svg` or `/icon.png` and may have no `.ico`), and the image is "requested from the site itself, never through a third-party favicon service, so drawing a link does not tell anyone else which links a page draws". The module is a client component (`"use client"`).

## Behavioral Requirements

- **request-from-site-origin**: The component MUST request the icon from the origin of `href`, and MUST ignore the path, query and fragment of `href`.
- **request-first-candidate-first**: The first request MUST be for the first entry of `FAVICON_PATHS`, `/favicon.ico`, joined to the origin.
- **candidate-order**: The candidate paths MUST be tried in this order: `/favicon.ico`, `/icon.svg`, `/icon.png`, `/icon`, `/apple-icon.png`, `/apple-icon`.
- **advance-on-load-error**: When the current candidate fails to load, the component MUST request the next candidate.
- **keep-first-loaded**: The component MUST keep showing the first candidate that loads and MUST NOT request later candidates.
- **fresh-load-per-candidate**: Each candidate MUST be a new image element, so that a new address is a new load with its own load and error events.
- **fallback-after-exhaustion**: When every candidate has failed, the component MUST render the `fallback` in place of the image and MUST NOT render an image element.
- **fallback-for-invalid-address**: When `href` is not a valid absolute URL, the component MUST render the `fallback` and MUST NOT request any image.
- **fallback-defaults-to-nothing**: When no `fallback` is given and no icon can be shown, the component MUST render nothing.
- **no-third-party-request**: The component MUST NOT request the icon from any host other than the origin of `href`.
- **recheck-failure-before-hydration**: After mounting, when the current image is already complete with a natural width of zero, the component MUST advance to the next candidate, because a failure before hydration is never delivered to the component as an error event.
- **hide-from-assistive-technology**: The image MUST have an empty alternative text and MUST be hidden from assistive technology.
- **square-size**: The image MUST be drawn as a square whose width and height attributes equal `size`, which defaults to 16.
- **decode-asynchronously**: The image MUST request asynchronous decoding.
- **merge-class-name**: The component MUST merge a caller `className` with its own classes `shrink-0`, `rounded-[3px]` and `object-contain`.
- **export-candidate-list**: The module MUST export the candidate list as `FAVICON_PATHS`.
- **load-as-client-module**: The module MUST be marked `"use client"`. This is verified by a static check for the directive at the top of `favicon.tsx`, not by a runtime test vector.

## Appearance

- **Corner radius**: 3px (`rounded-[3px]`).
- **Padding**: None.
- **Font**: Not applicable: the component draws an image; any fallback glyph is drawn by the caller.
- **Background**: None.
- **Foreground/Text**: Not applicable: the component draws an image.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: Square, `size` px on each side (default 16px). The image does not shrink inside a flex row (`shrink-0`) and is scaled to fit without distortion (`object-contain`).

## States

| State | Appearance change |
|-------|------------------|
| Default | An image of the first candidate, `/favicon.ico`, loading or loaded. |
| Trying next candidate | The previous image is replaced by a new image for the next path in the list; no intermediate state is drawn. |
| Fallback | The caller's `fallback` replaces the image, or nothing is drawn when there is none. |
| Pressed | Not applicable: the component is not interactive. |
| Disabled | Not applicable: the component is not interactive. |
| Focused | Not applicable: the component is not focusable. |
| Loading | The browser's own image loading; the component draws no placeholder while a candidate is in flight. |

## Accessibility

- **Role/trait**: The image is decorative: it has empty alternative text and `aria-hidden` of `true`, so assistive technology skips it.
- **Label requirements**: None on the image; the caller's link text names the destination. A caller-supplied `fallback` is rendered as given and carries whatever accessibility the caller gives it.
- **Announce state changes**: Not applicable: the component announces nothing; the move from image to fallback is silent.
- **Minimum tap target**: Not applicable: the component is not interactive, and the icon is a decoration inside a caller's control.

## Conformance Test Vectors

The suite beside the source is `favicon.test.tsx` (`packages/web/packages/ui/src/__tests__/favicon.test.tsx`); vectors derived from it name its tests.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| favicon-001 | request-from-site-origin, request-first-candidate-first, no-third-party-request | Render with `href` of `https://example.com/some/page` (test "asks the site itself for its icon") | The image `src` is `https://example.com/favicon.ico` |
| favicon-002 | candidate-order, advance-on-load-error | Render with `href` of `https://example.com` and a fallback; fire an error event on the image six times, reading `src` before each (test "tries each candidate in turn, then shows the fallback") | The `src` values are `https://example.com` joined to each entry of `FAVICON_PATHS`, in order |
| favicon-003 | fallback-after-exhaustion | Same render, after the sixth error event | No image element exists and the fallback text is present |
| favicon-004 | fallback-for-invalid-address | Render with `href` of `not a url` and a fallback (test "shows the fallback for an address that is not one") | The fallback is present and no image element exists |
| favicon-005 | fallback-defaults-to-nothing | Render with `href` of `not a url` and no fallback | The component's output is empty |
| favicon-006 | keep-first-loaded | Render with `href` of `https://example.com`; let the first image load without an error event | The image `src` stays `https://example.com/favicon.ico` and no second image is requested |
| favicon-007 | request-from-site-origin | Render with `href` of `https://example.com:8080/a/b?q=1#frag` | The image `src` is `https://example.com:8080/favicon.ico` |
| favicon-008 | hide-from-assistive-technology, square-size, decode-asynchronously | Render with `href` of `https://example.com` and `size` of 24 | The image has `alt` of the empty string, `aria-hidden` of `true`, `width` and `height` of 24 and `decoding` of `async` |
| favicon-009 | square-size | Render with `href` of `https://example.com` and no `size` | The image has `width` and `height` of 16 |
| favicon-010 | merge-class-name | Render with `className` of `ml-1` | The image carries `ml-1`, `shrink-0`, `rounded-[3px]` and `object-contain` |
| favicon-011 | recheck-failure-before-hydration | In a browser, server-render the component, let the image fail before hydration so it is complete with a natural width of zero, then hydrate | After mount the image `src` is the second candidate, `/icon.svg`, without any error event having been delivered |
| favicon-012 | export-candidate-list | Import `FAVICON_PATHS` | The list equals `/favicon.ico`, `/icon.svg`, `/icon.png`, `/icon`, `/apple-icon.png`, `/apple-icon` in that order |
| favicon-013 | fresh-load-per-candidate | Render, then fire an error event on the image | The image element after the event is a different element from the one before it |

## Edge Cases

- **Null and empty input**: An empty `href`, or one that does not parse as an absolute URL, MUST render the fallback and request nothing. An omitted `fallback` MUST render nothing.
- **Boundary values**: After the last candidate (`/apple-icon`) fails, the component MUST stop and render the fallback; it MUST NOT loop back to the first candidate. A `size` of 0 or a negative size is passed to the image attributes unchanged; the source does not validate it.
- **Opaque origins**: NEEDS REVIEW: Not implemented in source. For an `href` that parses but has an opaque origin (a `data:` or `mailto:` address), `URL.origin` is the string "null", so the first candidate address becomes `null/favicon.ico`, a relative address on the current page's origin; the source has no check for it. The owner of the component would settle whether such an address should go straight to the fallback.
- **Changing href**: NEEDS REVIEW: Not implemented in source. The count of failed candidates is component state and is not reset when `href` changes, so a component that has already failed on one site starts the next site partway down the list, or at the fallback. The owner of the component would settle whether `href` change should restart the list.
- **Concurrent access**: A failure that happens before hydration MUST be caught by the post-mount re-check, because the server-rendered image starts fetching as soon as the HTML arrives and React never sees its error event. Apart from that, the component holds only its own counter and image reference, and error events for a replaced image belong to an element that no longer exists.
- **Error states**: A failed load of any candidate MUST advance to the next candidate; the component renders no error message and logs nothing.
- **Offline or disconnected state**: When the network is unavailable every candidate fails in turn and the component MUST end on the fallback, with no retry once the list is exhausted.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `href` | `string` | required | Any address on the site; only its origin is used. |
| `fallback` | `ReactNode` | `null` | Rendered once every candidate has failed or the address is invalid. |
| `size` | `number` | `16` | Square size in px. |
| `className` | `string` | none | Extra classes merged onto the image. |
| `FAVICON_PATHS` | `string[]` (export) | six paths in the order above | The candidate paths, most likely first. |

## Deep Linking

Not applicable: the component has no URL routing; it only reads the origin of the address it is given.

## Localization

Not applicable: the component renders no text of its own; the image alternative text is empty.

## Accessibility Options

Not applicable: the component has no animation or color of its own and responds to no accessibility display option.

## Feature Flags

Not applicable: the component has no feature flag logic.

## Analytics

Not applicable: the component performs no analytics tracking.

## Privacy

- **Data collected**: None by the component. The icon request goes to the site being linked, which sees an ordinary image request from the visitor's browser.
- **Storage**: None. The component keeps no cache of its own; the browser's image cache applies.
- **Transmission**: The image is requested from the site itself and never through a third-party favicon service, so no other party learns which links a page draws. This is stated in the source comment.
- **Retention**: None.

## Logging

Not applicable: the component performs no logging.

## Platform Notes

- **SwiftUI**: Start with `AsyncImage(url:)` over the origin plus each candidate path, driven by a `@State` index advanced from the `.failure` phase of the `AsyncImage` content closure, with the fallback view in the exhausted case; mark the image with `.accessibilityHidden(true)`. Differs from the source: `AsyncImage` restarts on a new URL by identity, and there is no pre-hydration case, so the re-check has no equivalent. Build the origin from `URLComponents` (scheme, host, port), because `URL` has no origin property.
- **Compose**: Start with Coil's `AsyncImage` or `SubcomposeAsyncImage` with an `onError` callback that advances a `remember`ed index, the fallback composable in the exhausted case, and `contentDescription` of null to mark the image decorative. Differs from the source in having no hydration step; Coil's request cache replaces the browser image cache.
- **React/Web**: `packages/web/packages/ui/src/components/favicon.tsx` is the implementation: an `img` keyed by the attempt counter so each candidate is a new element, an `onError` handler that advances the counter, and an effect that advances it when the element is complete with a natural width of zero. The suite is `packages/web/packages/ui/src/__tests__/favicon.test.tsx`.
- **AppKit / UIKit**: Start with `NSImageView` (macOS) or `UIImageView` (iOS) loading each candidate with `URLSession`, advancing an index on a failed response or an image that does not decode, and swapping in the fallback view when the list is exhausted. Set `setAccessibilityElement(false)` on the image view, or `isAccessibilityElement` of false on iOS. Differs from the source: the load and failure are explicit in the session callback, so no re-check is needed, and the origin comes from `URLComponents`.
- **WinUI 3**: Start with an `Image` control whose `Source` is a `BitmapImage` created from the origin plus the current candidate path, and handle `Image.ImageFailed` (and `BitmapImage.ImageFailed`) to advance an index and assign a new `BitmapImage`, creating a new source per candidate so each is a fresh load. When the index passes the end, collapse the `Image` (`Visibility="Collapsed"`) and show the fallback element in the same `Grid` cell, bound to a `FallbackContent` property on a `UserControl`. Set `Width` and `Height` to the size, `Stretch="Uniform"` for object-contain, and round the corners by wrapping the `Image` in a `Border` with `CornerRadius="3"` and `Clip` or `ClipToBounds`. Mark the image decorative with `AutomationProperties.AccessibilityView="Raw"`. Differs from the source: there is no server render, so no pre-hydration failure exists; SVG candidates need `SvgImageSource` instead of `BitmapImage`; and `Uri` has `Scheme`, `Host` and `Port` but no single origin property, so the origin is assembled from those.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/favicon.tsx` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

- **Decision**: Try a list of known icon paths in order instead of asking only for `/favicon.ico`.
  **Rationale**: The source comment states there is no single place a site keeps its icon; a Next.js app that declares `app/icon.svg` or `app/icon.png` serves it there and may have no `.ico`, and an icon generated from `app/icon.tsx` is served at the bare `/icon` or `/apple-icon`, which has no extension and no static copy at the other paths.
  **Approved**: pending

- **Decision**: Request the icon from the site itself and never through a third-party favicon service.
  **Rationale**: The source comment states that drawing a link then does not tell anyone else which links a page draws.
  **Approved**: pending

- **Decision**: Re-check a finished image that decoded to nothing after mount, in addition to handling the error event.
  **Rationale**: The source comment states a failed load can happen before hydration, because the server-rendered image starts fetching as soon as the HTML arrives, and React never sees that error event; a finished image with a natural width of zero is what a pre-hydration failure leaves behind.
  **Approved**: pending

- **Decision**: Render a new image element for each candidate by keying on the attempt counter.
  **Rationale**: The source comment states one element per candidate makes a new source a new load with its own events.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.privacy-and-data.third-party-disclosure](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/036c9768-1c60-543d-b692-4adb3d3c884f) | passed | Privacy |
| [adc.check.reliability.graceful-degradation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/9a57e6ff-2e53-5163-8cce-6783d44f6b9f) | passed | Reliability |
| [adc.check.reliability.error-recovery](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/694a971d-282d-501b-8861-c4ece3b01edd) | partial | Reliability |

`separation-of-concerns` passes because the component only resolves and shows an icon and leaves the fallback and surrounding layout to the caller. `unit-test-coverage` is passed because `favicon.test.tsx` has a test for every vector, favicon-001 through favicon-013; favicon-011 simulates the pre-hydration state in jsdom by stubbing `complete` and `naturalWidth` on the image. `screen-reader-support` passes because the image is decorative, with empty alternative text and `aria-hidden`. `third-party-disclosure` passes because the image is requested only from the linked site. `graceful-degradation` passes because every failure path ends in the fallback. `error-recovery` is partial because failures advance through the candidates but the counter is not reset when `href` changes, as the open question on the changing-href edge case records.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (favicon.test.tsx, 13 of 13 vectors); unit-test-coverage now passed. |
