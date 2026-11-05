---
id: 4c3c4287-95bd-47f5-9a07-2382e0db523b
title: PanelStack
domain: adhsdk://recipes/panel-stack
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Container component that renders a collection of detail panes for visible
  topics.
platforms:
- typescript
- web
tags:
- layout
- container
depends-on:
- adhsdk://recipes/detail-pane
related: []
references: []
approved-by: ''
approved-date: ''
---

# PanelStack

## Overview

PanelStack is a container component that renders multiple DetailPane components based on a set of visible topic indexes. It serves as a layout wrapper for displaying detail views in a multi-pane interface. The component forwards a ref to its root div element to allow parent components to interact with the container directly. The `topics` array element type, `TopicData`, is the Topic data model defined by [detail-pane](adhsdk://recipes/detail-pane) — see `depends-on`.

## Behavioral Requirements

- **render-visible-panes**: Component MUST render a DetailPane for each index in the `visibleTopicIndexes` array.
- **pass-topic-data**: Component MUST pass the topic object from the `topics` array to each rendered DetailPane.
- **pass-image-load-callback**: Component MUST pass the `onImageLoad` callback to each DetailPane instance.
- **skip-missing-topics**: Component MUST skip rendering when a topic index does not exist in the topics array.
- **mark-visible-state**: Component MUST pass `visible={true}` to each DetailPane it renders. Per DetailPane's `visibility-state` requirement (adhsdk://recipes/detail-pane), `visible` controls whether the child applies `pc-pane-visible` or `pc-pane-hidden` while staying mounted either way. PanelStack has no model for a hidden-but-mounted pane: an index is either present in `visibleTopicIndexes` (its DetailPane renders with `visible={true}`) or absent (no DetailPane exists for it at all) — `visible={false}` never occurs here.
- **use-message-index-as-key**: Component MUST use the topic's `messageIndex` as the React key when rendering each DetailPane. This preserves each DetailPane's instance identity across reorders of `visibleTopicIndexes` as long as the indexes it lists resolve to distinct `messageIndex` values — see the **duplicate-indexes** edge case for what happens when they don't.
- **forward-ref**: Component MUST forward a ref to the root div element.
- **apply-class-name**: Component MUST apply the CSS class name `pc-panel-stack` to the root div.

## Appearance

- **Container**: Renders as a `div` element with class `pc-panel-stack`
- **Layout**: The component itself applies no inline or direct layout styles; the vertical arrangement described below comes entirely from the `pc-panel-stack` CSS class (`display: flex; flex-direction: column`), not from the component
- **Rendering model**: Vertical stack of DetailPane components, top-to-bottom in `visibleTopicIndexes` order

## States

| State | Appearance change |
|-------|------------------|
| Default | All visible panes rendered as DetailPane components |
| Empty | Empty div element when visibleTopicIndexes is empty or contains no valid indexes |

## Accessibility

The root `div` carries no ARIA role: PanelStack does not identify the stack as a landmark or a group to assistive technology, and it delegates all content semantics to the DetailPane children it renders (see Compliance: `semantic-markup`). PanelStack does not manage focus — it neither traps, moves, nor restores focus when `visibleTopicIndexes` changes and panes mount or unmount; the browser's default focus handling applies as elements enter and leave the DOM.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| panel-stack-001 | render-visible-panes | `topics=[{messageIndex: 0}, {messageIndex: 1}]`, `visibleTopicIndexes=[0, 1]` | Two DetailPane components rendered in order |
| panel-stack-002 | pass-topic-data | `topics=[{messageIndex: 5, title: "Test"}]`, `visibleTopicIndexes=[0]` | DetailPane receives topic prop with messageIndex: 5 and title: "Test" |
| panel-stack-003 | pass-image-load-callback | `onImageLoad={mockFn}`, any visible panes | Each DetailPane receives onImageLoad callback |
| panel-stack-004 | skip-missing-topics | `topics=[{messageIndex: 0}]`, `visibleTopicIndexes=[0, 5, 10]` | Only first DetailPane renders; indexes 5 and 10 render nothing |
| panel-stack-005 | use-message-index-as-key | `topics=[{messageIndex: 3}, {messageIndex: 7}]`; render with `visibleTopicIndexes=[0, 1]` and capture the DOM node of the DetailPane whose topic has `messageIndex: 7`; then re-render with `visibleTopicIndexes=[1, 0]` (same topics) | The DetailPane whose topic has `messageIndex: 7` is the same DOM node instance (`===`) before and after the reorder, confirming instance identity follows `messageIndex` rather than array position |
| panel-stack-006 | forward-ref | forwardRef attached to component | Ref resolves to root div element |
| panel-stack-007 | apply-class-name | any valid props | Root div has className `pc-panel-stack` |
| panel-stack-008 | skip-missing-topics | `topics=[{messageIndex: 0}]`, `visibleTopicIndexes=[5]` | Component renders empty div (no DetailPane rendered) |
| panel-stack-009 | mark-visible-state | `topics=[{messageIndex: 0}]`, `visibleTopicIndexes=[0]` | Rendered DetailPane receives `visible={true}` |

## Edge Cases

- **Empty topics array**: When `topics` is empty and `visibleTopicIndexes` contains indexes, component MUST render the root div with no DetailPane children.
- **Empty visibleTopicIndexes array**: When `visibleTopicIndexes` is empty, component MUST render only the div container with no child DetailPane components.
- **Out-of-bounds indexes**: When `visibleTopicIndexes` contains indexes greater than or equal to `topics.length`, component MUST skip those indexes and render nothing for them.
- **Negative or non-integer indexes**: `topics[idx]` resolves to `undefined` for a negative or non-integer `idx`, since JavaScript array indexing has no entry for such a key. Component MUST skip those indexes the same way as out-of-bounds indexes.
- **Undefined topic**: When a topic at a given index is undefined or null, component MUST render nothing (null return from map function).
- **Duplicate indexes**: When `visibleTopicIndexes` contains the same index multiple times, component MUST render multiple DetailPane instances for that topic (one per appearance in the array). Because each instance is keyed on the same `messageIndex` (see **use-message-index-as-key**), this violates React's key-uniqueness expectation: React logs a duplicate-key warning, and which sibling instance keeps its mounted identity across a subsequent reorder is left to React's reconciliation, not guaranteed by this component.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `topics` | `TopicData[]` | Required | Array of topic objects to be rendered. Each topic is passed to a DetailPane component; the `TopicData` shape is the Topic data model defined by [detail-pane](adhsdk://recipes/detail-pane). |
| `visibleTopicIndexes` | `number[]` | Required | Array of indexes into the `topics` array indicating which topics should be rendered. |
| `onImageLoad` | `() => void` | Required | Callback function invoked when images in DetailPane components complete loading. |
| `ref` | `React.Ref<HTMLDivElement>` | Optional | Ref object forwarded to the root div element. |

## Deep Linking

Not applicable: Component is a layout container without a navigable destination. Deep linking is handled by the DetailPane components it renders.

## Localization

Not applicable: Component renders no user-facing text or labels.

## Accessibility Options

Not applicable: Component is a non-interactive container. Accessibility options (reduce motion, increase contrast, differentiate without color) are handled by DetailPane components and content.

## Feature Flags

Not applicable: Component is a simple container with no conditional behavior or optional features.

## Analytics

Not applicable: Component is a container with no interactive behavior or state changes to track.

## Privacy

Not applicable: Component processes no user data and collects no information.

## Logging

Not applicable: Component has no lifecycle events, errors, or state transitions requiring logging.

## Platform Notes

- **SwiftUI**: Use `ForEach(visible, id: \.messageIndex)` inside a `VStack` to render the DetailPane equivalent for each visible topic. For the measure/scroll access the ref is meant to provide, use `ScrollViewReader` with `.id(topic.messageIndex)` on each subview, or `GeometryReader` to read the container's frame.
- **Compose**: Use a `Column` (or `LazyColumn` for large lists) composable that iterates over `visibleTopicIndexes`, conditionally rendering the DetailPane equivalent for each valid index. Use the topic's unique identifier as a key parameter.
- **React/Web**: Forward a ref to the root `div` element with `forwardRef`. The component is defined in `packages/web/packages/chat/src/modes/three-pane/PanelStack.tsx`. Map over `visibleTopicIndexes` and render a DetailPane for each valid index, using `messageIndex` as the React key.
- **AppKit / UIKit**: Use a vertical `NSStackView` (AppKit) or `UIStackView` (UIKit) as the container (native-controls), diffing its arranged subviews against the visible topics keyed on `messageIndex` so views are added, removed, or reordered without losing the internal state of views that persist across an update.
- **WinUI 3**: Use an `ItemsRepeater` (or `ItemsControl`) with a vertical `StackLayout`, binding `ItemsSource` to the resolved visible topics (the topics selected by `visibleTopicIndexes`) with a `DataTemplate` rendering the DetailPane equivalent for each item. `StackPanel.Children` cannot be data-bound directly, so avoid it here.

## Design Decisions

**Decision**: Use `messageIndex` as the React key instead of the array index.
**Rationale**: Keying on `messageIndex` preserves each DetailPane instance's identity across reorders of `visibleTopicIndexes` when the indexes resolve to distinct `messageIndex` values, maintaining focus and internal state; array-index keys would remount panes whenever the order changes. This guarantee does not extend to the **duplicate-indexes** edge case, where repeated `messageIndex` keys leave React's reconciliation to decide which instance survives a reorder.
**Approved**: pending

**Decision**: When a topic does not exist at a given index, render nothing (null) rather than an error placeholder.
**Rationale**: This allows parent components to control error handling and prevents cascading errors if index arrays become stale.
**Approved**: pending

**Decision**: Forward the root div ref via `forwardRef`.
**Rationale**: Allows parent components to measure, scroll, or manipulate the container directly.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The root `div` renders with only a class name and no ARIA role or landmark; the source does not indicate whether a group role would be appropriate for the stack, so `semantic-markup` is scored partial rather than passed or failed; `PanelStack.tsx` only maps `visibleTopicIndexes` to `DetailPane` children with no state or data logic of its own (separation-of-concerns: passed), and `PanelStack.test.tsx` renders the component and asserts the rendered panel order matches `visibleTopicIndexes` (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case everywhere they're cited, added the DetailPane dependency and linked TopicData to its definition, resolved the duplicate-indexes/use-message-index-as-key conflict and the vertical-layout/no-direct-styles wording, clarified the always-true visible prop, added the negative/non-integer index edge case, rewrote test vector 005 as an observable behavioral check and added one for visible state, corrected the SwiftUI/AppKit-UIKit/WinUI 3 platform notes, reformatted Design Decisions into Decision/Rationale/Approved form, and replaced the placeholder Compliance row with an applicable accessibility check |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source analysis (model: Claude Haiku 4.5) |
