---
id: 8d76adce-493b-4e44-9b15-826c4899d3cd
title: ConnectorAnchor
domain: adhsdk://recipes/connector-anchor
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Registration point for visual connectors in multi-pane layouts; invisible
  to end users.
platforms:
- typescript
- web
tags:
- connector
- anchor
- layout
- registry
depends-on:
- adhsdk://recipes/connector-registry
related:
- adhsdk://recipes/connector-registry
references: []
approved-by: ''
approved-date: ''
---

# ConnectorAnchor

## Overview

ConnectorAnchor is a registration anchor for visual connectors that link UI elements across a multi-pane layout. The component renders as an invisible span that registers its DOM reference with a shared connector registry, enabling external connector logic to query anchor positions and draw lines or other visual connections between designated points. The component is not visible to end users or assistive technologies.

The connector registry is any object implementing the `ConnectorRegistry` contract (see adhsdk://recipes/connector-registry): `register(id: string, el: HTMLElement): () => void`. Every call to `register` returns a cleanup function that removes the entry when invoked; ConnectorAnchor relies on this to unregister unconditionally on unmount and on `id` change.

## Behavioral Requirements

- **render-as-span**: Component MUST render as an HTML `<span>` element.
- **accept-id**: Component MUST accept a required string `id` prop that uniquely identifies the anchor point.
- **register-with-registry**: Component MUST register its DOM reference with the connector registry using the provided `id` when the component mounts.
- **return-null-if-no-registry**: Component MUST render nothing (return null) when the connector registry is not available.
- **set-data-connector-anchor**: Component MUST set a `data-connector-anchor` HTML attribute with the value of the `id` prop.
- **be-aria-hidden**: Component MUST set `aria-hidden="true"` on the rendered element to hide it from assistive technologies.
- **accept-classname**: Component SHOULD accept an optional `className` prop to allow consumers to apply additional CSS classes.
- **support-class-composition**: Component SHOULD concatenate the base class `pc-connector-anchor` with any provided `className` when both are present.
- **unregister-on-unmount**: Component MUST unregister from the connector registry when the component unmounts or when dependencies change. The registry's `register` call always returns a cleanup function, so unregistration is unconditional.
- **re-register-on-id-change**: Component MUST re-register with the connector registry when the `id` prop changes, unregistering the previous `id` before registering the new one.

## Appearance

- **Display**: Invisible; no visual rendering beyond DOM element creation.
- **Element**: Inline `<span>` element with no default width, height, padding, margin, or border.
- **Background**: Transparent (no background color applied).
- **Text content**: None; element is empty.
- **CSS class**: Base class `pc-connector-anchor` is always applied; additional classes from `className` prop are appended.

## States

| State | Appearance change |
|-------|------------------|
| Default | Invisible span with data attribute and aria-hidden. |
| Registry unavailable | Component is not rendered (returns null). |

## Accessibility

Not applicable: This component is explicitly hidden from assistive technologies via `aria-hidden="true"` and serves as an internal layout anchor, not as a user-facing control.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| connector-anchor-001 | render-as-span | Component rendered with id="point-a", registry available | DOM contains a `<span>` element. |
| connector-anchor-002 | accept-id | id="my-anchor", registry available | Rendered span has attribute `data-connector-anchor="my-anchor"`. |
| connector-anchor-003 | register-with-registry | Component mounted with id="test", registry available | Registry's register method called with id="test" and the span's DOM reference. |
| connector-anchor-004 | return-null-if-no-registry | Component mounted, registry unavailable (hook returns null) | Component renders nothing; no DOM elements created. |
| connector-anchor-005 | set-data-connector-anchor | id="anchor-1" | Rendered span has attribute `data-connector-anchor="anchor-1"`. |
| connector-anchor-006 | be-aria-hidden | Component rendered | Rendered span has attribute `aria-hidden="true"`. |
| connector-anchor-007 | accept-classname | id="x", className="custom-class", registry unavailable | Component renders nothing (returns null); no error is thrown. |
| connector-anchor-008 | support-class-composition | className="custom-class" | Rendered span's class attribute is "pc-connector-anchor custom-class". |
| connector-anchor-009 | support-class-composition | className undefined | Rendered span's class attribute is "pc-connector-anchor". |
| connector-anchor-010 | re-register-on-id-change | id changes from "old-id" to "new-id" | Registry's register method is called with "new-id" when the id prop updates. |
| connector-anchor-011 | return-null-if-no-registry, register-with-registry | First render, registry unavailable; then registry becomes available | Component renders nothing on the first render; once the registry becomes available, the component re-renders, registers with the registry, and renders the span. |
| connector-anchor-012 | unregister-on-unmount | Component mounted and registered with id="test", registry available; then unmounted | Registry's returned cleanup function is called; the "test" entry is removed from the registry. |
| connector-anchor-013 | re-register-on-id-change | id changes from "old-id" to "new-id" | The "old-id" entry is unregistered from the registry before "new-id" is registered. |

## Edge Cases

- **No registry available on mount**: Component returns null and renders nothing. No error is thrown.
- **Registry available but ref is not ready**: The effect checks `!ref.current` and returns early; no registration occurs until ref is available.
- **Registry dependency changes while registry is null**: Component re-evaluates effect but continues returning null.
- **id prop is empty string**: Component will register with an empty string id. The behavior of duplicate or empty ids is undefined; the source does not validate id uniqueness or non-emptiness.
- **className is empty string**: Component appends the empty string; class attribute becomes "pc-connector-anchor ".
- **className is whitespace**: Component concatenates whitespace; multiple spaces may appear in the class string.
- **Component unmounts immediately after mount**: If registration provides a cleanup function (via return value of `reg.register()`), that function is called on unmount.
- **Rapid id changes**: Registration is synchronous inside the effect; each id change runs the previous registration's cleanup (unregistering the old id) before registering the new id, so no overlap between registrations occurs.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `id` | string | required | The unique identifier for this anchor point; used to register with and query from the connector registry. |
| `className` | string | optional | Additional CSS classes to append to the base `pc-connector-anchor` class. |

## Deep Linking

Not applicable: ConnectorAnchor is an internal anchor point used for layout calculations and does not correspond to a navigable route or deep-linkable destination.

## Localization

Not applicable: ConnectorAnchor renders no user-visible text and has no localized strings.

## Accessibility Options

Not applicable: ConnectorAnchor is hidden from assistive technologies and does not respond to accessibility display options.

## Feature Flags

Not applicable: The source code contains no feature flag conditionals.

## Analytics

Not applicable: The source code contains no analytics event emission.

## Privacy

Not applicable: ConnectorAnchor does not collect, store, or transmit personal or user data; it is a layout anchor only.

## Logging

Not applicable: The source code contains no logging statements.

## Platform Notes

- **Web (React)**: Implement using the React `<span>` element. Use `useRef` to capture the DOM reference and `useEffect` with dependency array `[id, reg]` to register when both become available. Use optional chaining or conditional checks to guard against null registry. Render nothing (return null) when registry is unavailable. Apply classes by string concatenation; no CSS-in-JS framework is required. The `useConnectorRegistryOptional` hook is exported by the connector registry provider ingredient (adhsdk://recipes/connector-registry) — ensure a `ConnectorRegistryProvider` ancestor is mounted so the hook resolves to a registry.

- **SwiftUI**: Implement as a lightweight view (ZStack or plain View) that registers itself with an environment-injected connector registry on appear. Use an `@Environment` property to access the registry; if unavailable, render `EmptyView()`. Store the view's frame using `GeometryReader` and pass it to the registry's register method. Unregister on disappear or when the `id` changes.

- **Compose**: Implement as a composable that accepts `id` and optional `Modifier`. Use `DisposableEffect(id, registry) { ...; onDispose { /* unregister */ } }` to register with the registry on composition and unregister whenever `id` or `registry` changes, or when the composable leaves composition. Access the registry via `LocalConnectorRegistry.current`; if unavailable, render nothing. Store the composable's position using `onGloballyPositioned` and pass the coordinates to the registry.

- **AppKit / UIKit**: Implement as a view (NSView or UIView subclass) that registers its frame with a shared connector registry in `viewDidMoveToWindow` (NSView) or `didMoveToWindow` (UIView) once the window is non-nil, and unregisters when the window becomes nil. Store the registry as a weak property or access it via a shared singleton. If the registry is unavailable, initialize the view but do not render visibly. Store the view's bounds or center coordinates and pass them to the registry's register method.

- **WinUI 3**: Implement as a XAML-less code-behind control (C#) that inherits from `UserControl` or `FrameworkElement`. Accept an `Id` (string) DependencyProperty. In `OnApplyTemplate` or the `Loaded` event, query `ConnectorRegistry.Current` and call its `Register(id, element)` method, passing the control itself. If the registry is unavailable, the control remains loaded but inactive. Unregister in the `Unloaded` event. Size the control to zero (`Width="0" Height="0"`) while keeping `Visibility="Visible"`, since a collapsed element is removed from layout and would have no position to query.

## Design Decisions

**Decision**: Return `null` when the connector registry is unavailable rather than rendering an empty span.
**Rationale**: This gives optional-provider tolerance — the anchor degrades to a no-op when no `ConnectorRegistryProvider` ancestor is mounted, rather than registering into a registry that does not exist.
**Approved**: pending

**Decision**: Registration is side-effect based, performed in a `useEffect`, rather than declarative.
**Rationale**: Matches React's functional component patterns; the DOM ref is only available after mount, so registration must happen in an effect.
**Approved**: pending

**Decision**: The effect's dependency array is `[id, reg]`.
**Rationale**: Causes the previous `id` to be unregistered and the current `id` to be re-registered whenever `id` or the registry instance changes, matching the source implementation.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The status rests on the source setting `aria-hidden="true"` on the rendered `<span>` and using no other ARIA roles, states, or properties, which is correct markup for a non-interactive layout anchor hidden from assistive technologies. separation-of-concerns passes because `ConnectorAnchor.tsx` delegates all registration behavior to the injected `ConnectorRegistry` contract and its own effect is minimal ref-registration wiring, and unit-test-coverage passes because `ConnectorRegistry.test.tsx` directly renders `ConnectorAnchor` and exercises registration, re-registration on id change, and unregistration on unmount with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; defined the registry contract and made unregister-on-unmount unconditional; reworded the null-return rationale to optional-provider tolerance; reformatted Design Decisions into Decision/Rationale/Approved blocks; added tags and registry-ingredient cross-references; added a Compliance table; replaced untestable vectors, added missing unregister/re-register vectors, and corrected vector-011's reversed outcome; fixed the Compose, AppKit/UIKit, and WinUI 3 platform notes; rewrote the rapid-id-change edge case to describe synchronous cleanup; generalized the Overview wording away from "three-pane". |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
