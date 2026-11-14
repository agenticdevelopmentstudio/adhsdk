---
id: 447d0e33-c66e-4bf9-8511-e7823bdbcf9b
title: "Persona Chat"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Mode-based routing container that renders inline, three-pane, or mobile chat interfaces with a persona participant and optional user participant."
platforms:
  - typescript
  - web
tags:
  - chat
  - messaging
  - persona
depends-on:
  - 1794948f-2bb2-4f25-b9b5-72b1e6306ea1
  - 2d27892d-a3df-4e7d-ba47-dfd6c45b4c6d
  - f6d46f16-65a6-4d19-80c7-1fc8b4d323fd
related: []
references: []
approved-by: ""
approved-date: ""
---

# Persona Chat

## Overview

PersonaChat is a routing container component that dispatches to one of three chat interface modes based on the `mode` prop: `inline` (embedded chat box with adaptive sizing), `three-pane` (side-by-side conversation and details), or `mobile` (full-screen overlay). It manages communication with a chat backend, displays a persona participant, optionally includes a user participant, and renders an optional welcome message. The component is the entry point for integrating different chat UI layouts into applications.

## Behavioral Requirements

- **accept-mode-prop**: Component MUST accept a `mode` prop with value `'inline'`, `'three-pane'`, or `'mobile'`.
- **route-by-mode**: Component MUST render `InlineChat` when `mode` is `'inline'`, `ThreePaneChat` when `mode` is `'three-pane'`, and `MobileChat` when `mode` is `'mobile'`.
- **accept-backend**: Component MUST accept and forward a `backend` prop (type `ChatBackend`) to the rendered chat layout.
- **accept-persona**: Component MUST accept and forward a `persona` prop (type `ChatParticipant`) to the rendered chat layout.
- **accept-user**: Component SHOULD accept an optional `user` prop (type `ChatParticipant`) and forward it to the rendered chat layout when provided.
- **accept-welcome-message**: Component SHOULD accept an optional `welcomeMessage` prop (type `string`) and forward it to the rendered chat layout when provided.
- **accept-class-name**: Component SHOULD accept an optional `className` prop (type `string`) and forward it to the rendered chat layout when `mode` is `'inline'` or `'three-pane'`. `MobileChat` does not accept a `className` prop, so it is not forwarded in `'mobile'` mode.
- **accept-sizing-inline**: Component SHOULD accept an optional `sizing` prop (type `InlineChatSizing`) for `inline` mode, forwarding it only when `mode` is `'inline'`, controlling active/inactive sizing behavior and transitions.
- **handle-mobile-open**: Component SHOULD accept an optional `open` prop (type `boolean`, default `false`) for `mobile` mode, forwarding it to control overlay visibility.
- **handle-mobile-close**: Component SHOULD accept an optional `onClose` callback (type `() => void`, default no-op) for `mobile` mode, forwarding it to handle overlay dismissal.

## Appearance

Not applicable: PersonaChat is a routing component without direct visual presentation; appearance is delegated entirely to the selected layout component (`InlineChat`, `ThreePaneChat`, or `MobileChat`).

## States

Not applicable: PersonaChat does not define or manage visual or interactive states; state management belongs to the routed layout components.

## Accessibility

Not applicable: PersonaChat has no interactive elements or labels of its own; accessibility concerns are the responsibility of the routed child components.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|----|----|----|
| persona-chat-001 | route-by-mode | `mode='inline'`, backend, persona | Renders `InlineChat` component |
| persona-chat-002 | route-by-mode | `mode='three-pane'`, backend, persona | Renders `ThreePaneChat` component |
| persona-chat-003 | route-by-mode | `mode='mobile'`, backend, persona | Renders `MobileChat` component |
| persona-chat-004 | accept-backend | backend prop provided | Backend forwarded to child component |
| persona-chat-005 | accept-persona | persona prop provided | Persona forwarded to child component |
| persona-chat-006 | accept-user | user prop provided | User forwarded to child component |
| persona-chat-007 | accept-user | user prop omitted | Child component receives undefined user |
| persona-chat-008 | accept-welcome-message | welcomeMessage prop provided | Welcome message forwarded to child component |
| persona-chat-009 | accept-welcome-message | welcomeMessage prop omitted | Child component receives undefined welcomeMessage |
| persona-chat-010 | accept-class-name | `mode='inline'` or `'three-pane'`, className prop provided | className forwarded to child component |
| persona-chat-011 | accept-sizing-inline | `mode='inline'`, sizing prop provided | sizing forwarded to InlineChat component |
| persona-chat-012 | accept-sizing-inline | `mode='three-pane'`, sizing prop provided | sizing prop ignored; not forwarded to ThreePaneChat |
| persona-chat-013 | handle-mobile-open | `mode='mobile'`, open={true} | open={true} forwarded to MobileChat |
| persona-chat-014 | handle-mobile-open | `mode='mobile'`, open prop omitted | open={false} forwarded to MobileChat (default) |
| persona-chat-015 | handle-mobile-close | `mode='mobile'`, onClose callback provided | onClose forwarded to MobileChat component |
| persona-chat-016 | handle-mobile-close | `mode='mobile'`, onClose prop omitted | Default no-op callback forwarded to MobileChat |
| persona-chat-017 | accept-class-name | `mode='mobile'`, className prop provided | className not forwarded to MobileChat |
| persona-chat-018 | accept-sizing-inline | `mode='mobile'`, sizing prop provided | sizing prop ignored; not forwarded to MobileChat |
| persona-chat-019 | handle-mobile-close | `mode='inline'`, onClose callback provided | onClose not forwarded to InlineChat |
| persona-chat-020 | handle-mobile-open | `mode='inline'`, open prop provided | open not forwarded to InlineChat |
| persona-chat-021 | route-by-mode | `mode` set to a value outside `ChatMode` (untyped caller) | No switch case matches; component renders nothing (`undefined`) |

## Edge Cases

- **Invalid mode (untyped callers only)**: `mode` is typed as `ChatMode` (`'inline' | 'three-pane' | 'mobile'`), so a typed caller cannot pass any other value — this case is unreachable under the declared type (**route-by-mode**). An untyped JS caller, or a `mode as any` cast, that passes an unrecognized value falls through the `switch` with no matching case; PersonaChat returns `undefined` and renders nothing, with no warning or error.
- **Missing required props (untyped callers only)**: `backend` and `persona` are typed as required (non-optional) on `PersonaChatProps`, so a typed caller cannot omit them. An untyped JS caller that omits them causes PersonaChat to forward `undefined` to the child component, which is responsible for handling or signaling the error; PersonaChat MUST NOT validate these props itself (**accept-backend**, **accept-persona**).
- **Null/undefined participants**: If `user` is explicitly null or undefined, the component forwards it as-is to the child component, which determines whether this is acceptable (**accept-user**).
- **Sizing prop on non-inline modes**: When `mode` is `'three-pane'` or `'mobile'` and `sizing` is provided, PersonaChat MUST NOT forward the `sizing` prop; the child component does not accept it (**accept-sizing-inline**).
- **`open`/`onClose` on non-mobile modes**: When `mode` is not `'mobile'` and `open` or `onClose` are provided, PersonaChat MUST NOT forward them; `InlineChat` and `ThreePaneChat` do not accept these props. The values are silently dropped (**handle-mobile-open**, **handle-mobile-close**).
- **`className` on mobile mode**: `MobileChat` does not accept a `className` prop. When `mode` is `'mobile'`, PersonaChat MUST NOT forward `className` (**accept-class-name**).

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `mode` | `'inline' \| 'three-pane' \| 'mobile'` | (required) | Determines which chat layout to render |
| `backend` | `ChatBackend` | (required) | Chat backend implementation for message exchange |
| `persona` | `ChatParticipant` | (required) | The persona (non-user) participant in the chat |
| `user` | `ChatParticipant` | undefined | Optional user participant; forwarded to the child layout component, which defines what happens when it is omitted |
| `welcomeMessage` | `string` | undefined | Optional greeting message displayed on chat initialization |
| `className` | `string` | undefined | Optional CSS class name; forwarded to the child layout component when `mode` is `'inline'` or `'three-pane'` (`MobileChat` does not accept it) |
| `sizing` | `InlineChatSizing` | undefined | Inline mode only; configures active/inactive sizing and transitions |
| `open` | `boolean` | `false` | Mobile mode only; controls whether the overlay is visible |
| `onClose` | `() => void` | `() => {}` | Mobile mode only; callback when user dismisses the overlay |

## Deep Linking

Not applicable: PersonaChat does not define deep linking behavior; routing and deep link handling are delegated to the containing application and the selected layout component.

## Localization

Not applicable: PersonaChat contains no user-facing strings of its own; localization is the responsibility of the child layout components and the `welcomeMessage` prop passed by the caller.

## Accessibility Options

Not applicable: PersonaChat has no interactive elements that respond to accessibility display options; accessibility concerns (Reduce Motion, Increase Contrast, etc.) are delegated to child layout components.

## Feature Flags

Not applicable: The source code contains no feature flag logic; mode selection is controlled by the caller and can be made conditional by wrapper logic.

## Analytics

Not applicable: PersonaChat does not emit analytics events directly; event tracking is the responsibility of the selected layout component (`InlineChat`, `ThreePaneChat`, or `MobileChat`).

## Privacy

Not applicable: PersonaChat handles no data collection, storage, or transmission directly; privacy concerns are delegated to the backend implementation and child layout components.

## Logging

Not applicable: The source code contains no logging; debugging and diagnostic output are the responsibility of the backend implementation and child layout components.

## Platform Notes

- **Web**: `PersonaChat.tsx` is a React component in `packages/web/packages/chat/src/modes/` that uses a switch statement to dispatch to one of three layout components. Props are passed conditionally based on mode; `sizing`, `open`, and `onClose` are mode-specific, and `className` is forwarded to `InlineChat`/`ThreePaneChat` but not to `MobileChat`.
- **SwiftUI**: Implement as a view that receives `mode: ChatMode` as an input (an `enum` parameter or binding supplied by the caller, not internal `@State`, since mode selection is caller-determined) and uses a `switch`/`@ViewBuilder` to dispatch between three distinct chat UI compositions. Pass `backend` and `persona` as parameters, or via `@Environment`/a custom environment key, to the selected composition.
- **Compose**: Implement as a composable function using `when` to branch on `mode`, passing `backend` and `persona` through `CompositionLocal` or function parameters to the selected layout composable.
- **AppKit / UIKit**: Implement as a view controller that holds a reference to the currently active child view controller (one of three, selected by `mode`) and forwards mode-specific props (`sizing`, `open`, `onClose`) only to the child that accepts them. Perform the initial selection and prop forwarding in `init`; if `mode` can change after creation, remove the current child (`removeFromParent`, view removed from hierarchy) and install the replacement using standard child-view-controller containment (`addChild` plus adding its view) rather than mutating the existing child in place.
- **WinUI 3**: Implement as a XAML UserControl with a `Mode` dependency property (`enum` with `Inline`, `ThreePane`, `Mobile` values). Swap the displayed content with a code-behind `switch` on `Mode` (or a `DataTemplateSelector` if the compositions are defined as data templates), forwarding `Backend`, `Persona`, and the mode-specific properties (`Sizing`, `Open`, `OnClose`) directly to the selected child control in that switch, rather than a value converter plus attached properties.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/chat/src/modes/PersonaChat.tsx` | unverified |

## Design Decisions

**Decision**: Dispatch to child layout components (`InlineChat`, `ThreePaneChat`, `MobileChat`) via a plain `switch` statement on `mode`, rather than a polymorphic factory pattern.
**Rationale**: The three modes represent fundamentally different UI layouts (embedded box, side-by-side panes, full-screen overlay), not interchangeable implementations of the same interface, and each has distinct prop requirements (`sizing` for inline; `open`/`onClose` for mobile), making a unified prop interface unwieldy. The component remains thin and transparent — a presentation-level router with no business logic beyond routing.
**Approved**: pending

**Decision**: Mode is a caller-supplied prop (`mode: ChatMode`), not state PersonaChat tracks internally.
**Rationale**: Mode selection is caller-determined, allowing parent components to choose layout based on viewport, user preference, device type, or application state.
**Approved**: pending

**Decision**: An unrecognized `mode` value falls through the `switch` and `PersonaChat` returns `undefined` (renders nothing), rather than throwing, warning, or logging.
**Rationale**: `mode` is typed as `ChatMode` (`'inline' | 'three-pane' | 'mobile'`), so TypeScript already rejects any other value at typed call sites — this case is unreachable under the declared type (**route-by-mode**) and only occurs for an untyped JS caller or an explicit type-assertion cast. See the "Invalid mode" edge case for what the untyped-caller path actually does.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

The `passed` status rests on the `switch` returning the selected child component (`InlineChat`, `ThreePaneChat`, or `MobileChat`) directly with no wrapper element, so whatever ARIA roles and semantic structure the chosen child renders pass through unchanged; `PersonaChat.tsx` is a pure mode-keyed dispatch switch with no business logic (separation-of-concerns: passed), while `personaChatRecipe.test.ts`, `personaChatConformance.test.ts`, and `PersonaChatCoordinatorTests.swift` extensively exercise the underlying session/backend/coordinator behavior the recipe composes but no test renders `PersonaChat` itself to verify the mode-based dispatch (unit-test-coverage: partial).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case everywhere they're cited; scope className/sizing/open/onClose forwarding rules to the modes that actually accept them and add the missing conformance vectors (mobile className, mobile sizing, non-mobile open/onClose, invalid mode); reword the invalid-mode edge case and Design Decision to state what the type system already enforces instead of an unverified "signals a configuration error" claim; replace the Compliance table's non-catalog rows with a real accessibility check; reformat Design Decisions into the three-line Decision/Rationale/Approved form; correct the SwiftUI, WinUI 3, and AppKit/UIKit platform notes; populate depends-on/related with the three composed layout recipes and the persona-chat coordinator ingredient; and align modified-date quoting with the other recipes |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: partial). |
