---
id: f361ebe1-69b9-4089-8079-94f4b26a37d3
title: "Conditional"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Renders one of two content branches based on a boolean condition."
platforms:
  - typescript
  - web
tags:
  - conditional
  - branching
  - rendering
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Conditional

## Overview

Conditional renders one of two content branches — `children` when the `when` boolean is `true`, otherwise `fallback` — without adding a layout or container node around whichever branch is shown. It is a simple, stateless branching pattern. On React/Web, where JSX benefits from an explicit component for inline conditional rendering, this is a concrete `Conditional` component; SwiftUI, Compose, AppKit/UIKit, and WinUI 3 need no wrapper type at all — see Platform Notes for the native control-flow equivalent on each.

## Behavioral Requirements

- **render-children-when-true**: Component MUST render the `children` prop when the `when` prop is `true`.
- **render-fallback-when-false**: Component MUST render the `fallback` prop when the `when` prop is `false`.
- **fallback-defaults-to-null**: Component MUST default `fallback` to `null` when the `fallback` prop is not provided.
- **no-wrapper-element**: Component MUST NOT add a layout or container node around the rendered branch (on React/Web this is a fragment — see Platform Notes).
- **null-children-renders-nothing**: Component MUST render nothing when `children` is `null` or `undefined` and `when` is `true`.
- **falsy-children-renders-value**: Component MUST render a falsy `children` value (e.g. `0`, `false`, or an empty string) when `when` is `true`, rather than treating it as no content.
- **mixed-children-render-in-order**: Component MUST render multiple or mixed-type `children` (arrays, strings, elements, fragments) in the order provided when `when` is `true`.
- **inactive-branch-not-mounted**: When the branch selected by `when` changes to an element of a *different* type (or a differently-keyed element) than the one currently rendered, the component MUST unmount the previously rendered branch, discarding its state, and mount the newly selected branch. Because both branches render into a single unkeyed slot, this guarantee holds only across a type/key change: if `children` and `fallback` are elements of the *same* type, React reconciles the existing instance in place instead, and its state survives the toggle (see Edge Cases and Platform Notes).

## Appearance

Not applicable: Conditional is a utility component that does not render any visual styling. It passes through its content unchanged.

## States

Not applicable: Conditional does not have visual states. Its behavior is determined entirely by the boolean value of the `when` prop.

## Accessibility

Conditional does not add any accessibility features or roles itself. Content rendered within Conditional inherits the accessibility properties of the `children` and `fallback` components; because the component adds no wrapper node (**no-wrapper-element**), it MUST NOT alter the accessibility tree structure of whichever branch is rendered. Implementors SHOULD ensure that both branches meet accessibility requirements independently.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| conditional-001 | render-children-when-true | `when={true}`, `children="Hello"`, `fallback="Goodbye"` | Renders "Hello" |
| conditional-002 | render-fallback-when-false | `when={false}`, `children="Hello"`, `fallback="Goodbye"` | Renders "Goodbye" |
| conditional-003 | fallback-defaults-to-null | `when={false}`, `children="Hello"` (no fallback prop) | Renders nothing (null) |
| conditional-004 | inactive-branch-not-mounted | Render with `when={true}`, `children={<Stateful />}` (a component holding local state); re-render with `when={false}` | The `fallback` branch renders; the previous `children` branch is unmounted and its state is discarded |
| conditional-005 | no-wrapper-element | `when={true}`, `children=[<span>A</span>, <span>B</span>]` | Both children render without a parent wrapper |
| conditional-006 | null-children-renders-nothing | `when={true}`, `children={null}` | Renders nothing |
| conditional-007 | falsy-children-renders-value | `when={true}`, `children={0}` | Renders "0" |
| conditional-008 | mixed-children-render-in-order | `when={true}`, `children={["A", <span>B</span>, <>C</>]}` | Renders "A", then `<span>B</span>`, then "C", in that order |

## Edge Cases

- **Null children** (see **null-children-renders-nothing**): When `children` is `null` or `undefined` and `when` is `true`, the component renders nothing.
- **Falsy children values** (see **falsy-children-renders-value**): When `children` is a falsy value such as `0`, `false`, or an empty string and `when` is `true`, the component renders that value as React normally would.
- **Empty fallback** (see **fallback-defaults-to-null**): When `when` is `false` and `fallback` is not provided, the component renders nothing.
- **Mixed and array children** (see **mixed-children-render-in-order** and **no-wrapper-element**): When `children` is an array or contains mixed content (strings, elements, fragments) and `when` is `true`, all content renders in order without an added wrapper.
- **Toggling `when` at runtime** (see **inactive-branch-not-mounted**): Switching `when` unmounts the previous branch and mounts the new one only when the outgoing and incoming branches are elements of different types (or differently keyed). Because both branches render into a single unkeyed slot, toggling between two elements of the *same* type reconciles the existing instance in place instead — its state (and any effects) survive the toggle rather than being discarded.

## Configuration

Not applicable: Conditional accepts no configuration options beyond its three props: `when`, `children`, and `fallback`.

## Deep Linking

Not applicable: Conditional is a utility component and does not define routes or support deep linking.

## Localization

Not applicable: Conditional does not render any user-facing text. Text content is provided by `children` or `fallback` and MUST be localized at the component level by the caller.

## Accessibility Options

Not applicable: Conditional does not implement accessibility display options. Assistive technology handling is delegated to the rendered `children` and `fallback` components.

## Feature Flags

Not applicable: Conditional does not have feature-flag-gated behavior.

## Analytics

Not applicable: Conditional does not emit any analytics events.

## Privacy

Not applicable: Conditional does not collect, store, or transmit data.

## Logging

Not applicable: Conditional does not emit log messages.

## Platform Notes

- **React/Web**: Implemented as a fragment-based ternary — `<>{when ? children : fallback}</>` — in the reference implementation at `packages/web/packages/controls/src/user-settings/components/Conditional.tsx`. This produces no extra DOM nodes and lets sibling elements render at the same nesting level as the parent. Because both branches share one unkeyed fragment slot, React's reconciliation unmounts/remounts only when the outgoing and incoming branches differ in element type (or key); branches of the same type are updated in place and keep their state across a `when` toggle (see **inactive-branch-not-mounted**).
- **SwiftUI**: No wrapper type is needed: use the native `if` statement within the view hierarchy, or a custom `@ViewBuilder` for reuse: `if when { children } else { fallback }`. SwiftUI's view builders naturally avoid wrapper views for conditional content.
- **Compose (Android/Kotlin)**: No wrapper type is needed: use Kotlin's `if` expression directly within a `@Composable` function, naming the boolean parameter something other than `when` since `when` is a reserved keyword in Kotlin (e.g. `condition`): `if (condition) { children() } else { fallback() }`. Pass content as lambdas (composable blocks) for lazy evaluation.
- **AppKit / UIKit**: No wrapper type is needed in view-based code: conditionally add or remove the branch's view (or view controller) from its superview/container to satisfy **inactive-branch-not-mounted** — creating both views and toggling `isHidden` keeps the hidden view and its state alive, so prefer adding/removing over hiding.
- **WinUI 3**: Bind the displayed content to the boolean directly with `x:Bind` (built into WinUI 3, no custom converter needed), or use a `ContentControl` whose `Content` is set based on the boolean to swap the displayed element — either approach satisfies **inactive-branch-not-mounted** by only realizing the active branch. Toggling the `Visibility` of two pre-laid-out, already-realized branches with `VisualStateManager` is a valid alternative only when both branches' state must survive the toggle; that tradeoff means it does not satisfy **inactive-branch-not-mounted**.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/controls/src/user-settings/components/Conditional.tsx` | unverified |

## Design Decisions

**Decision**: `fallback` defaults to `null` when the `fallback` prop is not provided.
**Rationale**: Simplifies the common case where no fallback content is needed; callers can omit the prop when rendering conditionally is sufficient to hide content entirely.
**Approved**: pending

**Decision**: The component renders via a fragment (`<>...</>`) rather than a `<div>` or other wrapper element.
**Rationale**: Avoids introducing an extra DOM node that would affect styling and layout, keeping the component transparent to the surrounding component tree.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The `passed` status rests on the component's fragment-based render (`<>{when ? children : fallback}</>`), which adds no wrapper node and therefore preserves whatever ARIA roles and semantic structure the rendered branch already has. separation-of-concerns passes because `Conditional.tsx` renders via a single ternary inside a fragment with no state or business logic of its own, and unit-test-coverage passes because `components.test.tsx`'s `Conditional` suite exercises the true/false branches, the default-fallback case, and array/mixed children with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: fixed Kotlin reserved-keyword note, added inactive-branch-not-mounted requirement, promoted edge-case MUSTs to named requirements with vectors, neutralized Overview/no-wrapper-element wording, corrected WinUI 3 and AppKit/UIKit platform notes, cited reference implementation, reformatted Design Decisions, added Compliance table |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Scoped inactive-branch-not-mounted requirement/edge case/Platform Note to same-type-vs-different-type reconciliation reality. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |

