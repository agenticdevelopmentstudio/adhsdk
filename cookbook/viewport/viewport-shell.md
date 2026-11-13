---
id: 960a1577-bf48-4d56-a93f-aa690853f64f
title: "ViewportShell"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Page-level shell that locks viewport and manages keyboard inset for the page."
platforms:
  - typescript
  - web
tags:
  - viewport
  - layout
depends-on: []
related:
  - c10a6fd9-470a-45a1-a025-3c75554c2a41
  - 556f7dbf-2a14-4e97-aaa2-0954c7488e6f
references: []
approved-by: ""
approved-date: ""
---

# ViewportShell

## Overview

ViewportShell is a top-level page shell component that locks the document to the visible viewport, preventing page scroll, and mounts the keyboard-inset hook to track and respond to virtual keyboard visibility. It provides a vertical flex container for slotting child components and can optionally allow overflow to hang beyond its boundaries.

## Behavioral Requirements

- **page-lock**: The component MUST prevent `html` and `body` from scrolling. This is provided by the package's `base.css` (`html, body { overflow: hidden; overscroll-behavior: none }`), imported once at the app root — the shell does not set or restore this style itself, so mounting, unmounting, or nesting multiple `<ViewportShell>` instances has no effect on it.
- **render-children**: The component MUST render its `children` prop as the content of a flex container.
- **keyboard-inset**: The component MUST call `useKeyboardInset()` on render. The hook MUST write the `--kb-inset` CSS custom property, in pixels, onto `document.documentElement`, computed from `window.visualViewport`'s `height` and `offsetTop` on every `resize` and `scroll` event; descendants read the current inset via `var(--kb-inset)` (e.g. `ViewportComposer`'s `.vp-composer` bottom padding).
- **root-class**: The component MUST apply the CSS class `viewport-shell` to its root element.
- **clip-prop**: The component MUST accept a `clip` boolean prop that defaults to `true`. `.viewport-shell` sets `overflow: hidden`, so the default clips the shell's own overflow.
- **open-class**: When `clip` is `false`, the component MUST also apply the CSS class `vp-shell--open` to its root element. `.viewport-shell.vp-shell--open` sets `overflow: visible`.
- **class-name-merge**: The component MUST accept an optional `className` prop and append it to the root element's class list.
- **ignore-empty-class-name**: When `className` is `undefined` or the empty string `''`, the component MUST NOT add it to the class list. Any other string — including one that is only whitespace — is added as-is, since the implementation filters with `Array.prototype.filter(Boolean)`, which only removes falsy values.

## Appearance

- **Container**: Vertical flex container — `.viewport-shell` sets `display: flex; flex-direction: column`.
- **Background**: Transparent (inherits from parent; no background is set)
- **Overflow behavior**: Controlled by `clip` prop — `.viewport-shell` sets `overflow: hidden`; `clip={false}` adds `.vp-shell--open`, which sets `overflow: visible`.
- **Sizing**: `.viewport-shell` sets `height: 100dvh`, filling the visible viewport height.

## States

| State | Trigger | Appearance Change |
|-------|---------|------------------|
| Clipped (default) | `clip={true}` or prop omitted | CSS class `viewport-shell` applied; overflow hidden |
| Open | `clip={false}` | CSS classes `viewport-shell` and `vp-shell--open` applied; overflow visible |

## Accessibility

ViewportShell itself renders no text, interactive elements, or ARIA roles: it is a plain `<div>` wrapper, and accessibility for slotted content is owned by whatever children are placed inside it. Two page-level effects are still the shell's own responsibility:

- It renders a plain, non-interactive `div` with no ARIA attributes, so it introduces nothing for a screen reader or keyboard user to trip over (see **semantic-markup** and **screen-reader-support** in Compliance).
- Locking `html`/`body` to `overflow: hidden` (see **page-lock**) means content taller than the viewport is only reachable if something inside the shell provides its own scrollable region. Neither `ViewportShell` nor `ViewportSpacer` sets `overflow: auto` anywhere in `base.css` — a scrollable child region, if the slotted content needs one, is the consumer's (or a child component's) responsibility to provide (see **keyboard-navigable** in Compliance, `partial`).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| viewport-001 | render-children | `<ViewportShell><div>Content</div></ViewportShell>` | Rendered div with text "Content" appears in the DOM as a child of the shell |
| viewport-002 | root-class | `<ViewportShell />` | Root element has class `viewport-shell` |
| viewport-003 | open-class, clip-prop | `<ViewportShell clip={false} />` | Root element has classes `viewport-shell` and `vp-shell--open`; computed `overflow` of the root element is `visible` |
| viewport-004 | class-name-merge | `<ViewportShell className="custom-class" />` | Root element has classes `viewport-shell` and `custom-class` |
| viewport-005 | ignore-empty-class-name | `<ViewportShell className="" />` | Root element has class `viewport-shell` only; empty string is not added to class list |
| viewport-006 | clip-prop | `<ViewportShell />` (clip omitted) | Root element does not have `vp-shell--open` class; computed `overflow` of the root element is `hidden` |
| viewport-007 | keyboard-inset | `<ViewportShell />` mounted, then `visualViewport` dispatches a `resize` event such that `innerHeight - visualViewport.height - visualViewport.offsetTop` equals 300 | `document.documentElement.style.getPropertyValue('--kb-inset')` equals `"300px"` |
| viewport-008 | page-lock | `<ViewportShell />` mounted with the package's `base.css` loaded | `getComputedStyle(document.documentElement).overflow` and `getComputedStyle(document.body).overflow` are both `"hidden"` |
| viewport-009 | page-lock | Two `<ViewportShell>` instances mounted at once, then one is unmounted | `document.documentElement`'s computed `overflow` stays `"hidden"` throughout; neither shell's mount nor unmount changes it |
| viewport-010 | render-children | `<ViewportShell>{null}</ViewportShell>` | Root element renders with no child content |
| viewport-011 | render-children | `<ViewportShell>{[]}</ViewportShell>` | Root element renders with no child elements |
| viewport-012 | render-children | `<ViewportShell><span>A</span><span>B</span></ViewportShell>` | Both children appear in the DOM as siblings, in the order provided |
| viewport-013 | class-name-merge | `<ViewportShell className="  " />` | The whitespace-only string is included verbatim in the joined class attribute; it is not trimmed or filtered out |
| viewport-014 | clip-prop, open-class | `<ViewportShell clip={true} />` re-rendered with `clip={false}`, then back to `clip={true}` | Class list and computed `overflow` update synchronously on each render; the same children instance is preserved, not remounted |

## Edge Cases

- **Null children**: When `children` is `null`, the component MUST render its root element with no child content.
- **Empty children array**: When `children` is an empty array, the component MUST render its root element with no child elements.
- **Multiple children**: The component MUST render all children in the order provided.
- **clip prop is undefined**: When `clip` is not provided, the component MUST default to `true` and MUST NOT apply the `vp-shell--open` class.
- **className with whitespace**: A whitespace-only `className` (e.g. `"  "`) MUST NOT be trimmed or rejected — `Array.prototype.filter(Boolean)` only removes falsy values, so it is joined into the class list as-is, alongside `viewport-shell`.
- **Rapid clip prop changes**: When `clip` changes between `true` and `false` across renders, the component MUST update its class list and computed overflow synchronously, and MUST preserve `children` without remounting them.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `children` | ReactNode | (required) | Content to render within the shell |
| `clip` | boolean | `true` | When `false`, allows content to overhang the shell's box (page remains locked regardless) |
| `className` | string | undefined | Additional CSS class names to apply to the root element |

## Deep Linking

Not applicable: ViewportShell is a page-level shell component and does not handle deep linking itself.

## Localization

Not applicable: ViewportShell has no user-facing text and does not perform localization.

## Accessibility Options

Not applicable: ViewportShell is a structural container and does not directly respond to accessibility display options. All accessibility handling is delegated to child components.

## Feature Flags

Not applicable: ViewportShell has no feature flag requirements.

## Analytics

Not applicable: ViewportShell is a foundational container component and does not emit analytics events.

## Privacy

Not applicable: ViewportShell does not collect, store, or transmit any data.

## Logging

Not applicable: ViewportShell has no logging requirements.

## Platform Notes

- **React/Web**: `ViewportShell.tsx` renders a `div` and calls `useKeyboardInset()` unconditionally. Classes are built with `['viewport-shell', clip ? '' : 'vp-shell--open', className].filter(Boolean).join(' ')`. `useKeyboardInset()` writes `--kb-inset` onto `document.documentElement` from `window.visualViewport`'s `resize`/`scroll` events.
- **SwiftUI**: Use `.ignoresSafeArea(.container)` on the root container to lock it to the viewport, and rely on SwiftUI's automatic keyboard avoidance (or read the keyboard safe-area inset directly) instead of ignoring the keyboard safe area — `edgesIgnoringSafeArea` is deprecated, and ignoring the keyboard inset would undo the behavior this component exists to provide.
- **Compose**: Use `Modifier.fillMaxSize().imePadding()` (or observe `WindowInsets.ime` directly) to lock the layout to the viewport and react to the keyboard. `Modifier.verticalScroll(enabled = false)` is meaningless — Compose layouts don't scroll unless scrolling is explicitly added — so it implements nothing.
- **AppKit / UIKit**: On iOS, pin the view to its superview with Auto Layout constraints and use `view.keyboardLayoutGuide` (iOS 15+) to react to keyboard visibility; the `UIKeyboardWillShow`/`UIKeyboardWillHide` notification pair is outdated, and `autoresizingMaskIntoConstraints` is for opting a view *out* of Auto Layout, not for filling a safe area. On macOS, an `NSView` filling the window's content area is sufficient; keyboard handling is not applicable.
- **WinUI 3**: Implement as a `Grid` with `VerticalAlignment="Stretch"` and `HorizontalAlignment="Stretch"`, and leave `Background` unset so the shell stays transparent, matching the Appearance section. Observe `InputPaneInterop.GetForWindow(hwnd)` to track virtual keyboard state — `InputPane.GetForCurrentView()` is UWP-only and does not work in a desktop WinUI 3 app. The `clip` flag controls whether child content is clipped via `UIElement.Clip` (a `RectangleGeometry`) — `ClipToBounds` is a WPF property and doesn't exist on WinUI's `FrameworkElement`.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/viewport/src/ViewportShell.tsx` | unverified |

## Design Decisions

**Decision**: `clip` defaults to `true`, which keeps `.viewport-shell`'s own `overflow: hidden`; passing `clip={false}` adds `vp-shell--open` (`overflow: visible`) for content that must deliberately overhang the shell's box, such as a corner badge.
**Rationale**: Most page layouts should constrain overflow to avoid unintended visual overflow and layout shift, so the overhang case is opt-in. The page itself stays locked (`overflow: hidden` on `html`/`body`, via `base.css`) regardless of `clip`, so opening the shell can never introduce a document-level scrollbar.
**Approved**: pending

**Decision**: `useKeyboardInset()` is mounted unconditionally rather than made opt-in.
**Rationale**: Virtual-keyboard tracking is a foundational concern for any page-level shell. The hook writes the `--kb-inset` CSS custom property onto `document.documentElement`, so any descendant can read `var(--kb-inset)` in its own CSS — as `ViewportComposer`'s `.vp-composer` bottom padding does — without prop threading or a React context.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

These statuses rest on `ViewportShell.tsx` rendering a plain `<div>` with only class-list attributes and no ARIA overrides (`semantic-markup`, `screen-reader-support`), and on `base.css` locking `html`/`body` scroll while declaring no `overflow: auto` anywhere in the `viewport` package's own CSS, leaving reachability of tall content dependent on a scrollable region the consumer supplies (`keyboard-navigable`, partial). `separation-of-concerns` passes because the keyboard-inset measurement logic is delegated entirely to the `useKeyboardInset` hook, leaving the component itself pure presentation; `unit-test-coverage` fails because no test exercises it.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names; grounded keyboard-inset, page-lock, and clip/open-class semantics in source; reformatted Design Decisions; replaced Accessibility and Compliance with real content; corrected className-whitespace behavior and Edge Cases RFC 2119 phrasing; rewrote Platform Notes APIs and relabeled React/Web; expanded Conformance Test Vectors; added related recipes |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
