---
id: dcf1a793-0a47-466b-8b09-0bcf091fd55a
title: "Topics Pane"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A pane displaying a list of selectable topics with active state indication and visibility control."
platforms:
  - typescript
  - web
tags:
  - ui-container
  - list
  - navigation
depends-on:
  - 8d76adce-493b-4e44-9b15-826c4899d3cd
related: []
references: []
approved-by: ""
approved-date: ""
---

# Topics Pane

## Overview

The Topics Pane is a container component that displays a list of topic items as selectable buttons within a labeled pane. It provides visibility toggling and active state selection, used in multi-pane layouts to navigate between topics or discussion threads. Each topic is rendered with its title and an associated connector anchor for visual linking in complex layouts.

## Behavioral Requirements

- **render-header**: Component MUST render a header section displaying the text "Topics".
- **render-topic-list**: Component MUST render all topics provided in the topics array as a list of button elements.
- **display-topic-title**: Component MUST display the `title` property of each topic within its button.
- **topic-selection-callback**: Component MUST invoke `onSelectTopic(index)` when a topic button is clicked, passing the zero-based index of that topic within the `topics` array.
- **indicate-active-topic**: Component MUST visually indicate which topic is currently active by comparing its index to the `activeIndex` prop and applying an "active" class when they match.
- **respect-visibility-state**: Component MUST apply a visibility class that changes between "pc-pane-visible" and "pc-pane-hidden" based on the `visible` prop.
- **render-connector-anchor**: Component MUST render a `ConnectorAnchor` child element within each topic button, with `id` set to `topic-<messageIndex>` (the literal string `"topic-"` concatenated with the topic's `messageIndex`, e.g. `topic-5`) and `className="pc-connector-anchor-out"`.

## Appearance

- **Container**: Full-width pane with CSS classes `pc-topics-pane` and visibility modifier class
- **Header**: Styled section with CSS class `pc-panel-header` containing the text "Topics"
- **List**: Unordered list with CSS class `pc-topic-list` containing list items
- **Topic Item**: Button element with CSS class `pc-topic-item` and optional "active" class modifier
- **Connector Anchor**: Child component within each button with CSS class `pc-connector-anchor-out`
- **Active State**: Visually distinguished via "active" class when topic index matches `activeIndex`

## States

| State | Appearance Change |
|-------|------------------|
| Visible | Container displays with "pc-pane-visible" class applied |
| Hidden | Container displays with "pc-pane-hidden" class applied |
| Topic Default | Button rendered without "active" class |
| Topic Active | Button rendered with "active" class modifier |

## Accessibility

- Role: Container with a header and list of buttons for topic selection
- Label: The "Topics" header text serves as the pane label
- Button elements: Each topic button SHOULD have an accessible label from its `title` text
- Active state: The "active" class on the selected topic button SHOULD be announced to screen readers or conveyed through semantic HTML attributes
- Keyboard navigation: Topic buttons SHOULD be keyboard accessible and focusable in tab order
- Minimum tap target: Topic buttons SHOULD maintain at least 24×24 CSS pixels (WCAG 2.5.8 Target Size Minimum) for this web component

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| topics-001 | render-header | topics=[], visible=true | Header element displays "Topics" text |
| topics-002 | render-topic-list | topics=[{title: "Topic 1", messageIndex: 1}], visible=true | Single list item with button containing "Topic 1" |
| topics-003 | display-topic-title | topics=[{title: "First", messageIndex: 1}, {title: "Second", messageIndex: 2}], visible=true | Both topic titles displayed in respective buttons |
| topics-004 | topic-selection-callback | topics=[{title: "Topic", messageIndex: 1}], user clicks button | onSelectTopic callback invoked with index 0 |
| topics-005 | indicate-active-topic | topics=[{title: "A", messageIndex: 1}, {title: "B", messageIndex: 2}], activeIndex=1, visible=true | Second button has "active" class; first button does not |
| topics-006 | respect-visibility-state | topics=[], visible=true | Root div has "pc-pane-visible" class |
| topics-007 | respect-visibility-state | topics=[], visible=false | Root div has "pc-pane-hidden" class |
| topics-008 | render-connector-anchor | topics=[{title: "Topic", messageIndex: 5}] | ConnectorAnchor component rendered with id="topic-5" and className="pc-connector-anchor-out" |
| topics-009 | indicate-active-topic | topics=[{title: "First", messageIndex: 1}], activeIndex=0 | Button contains "active" class |
| topics-010 | topic-selection-callback | topics=[{title: "A", messageIndex: 1}, {title: "B", messageIndex: 2}, {title: "C", messageIndex: 3}], user clicks second button | onSelectTopic callback invoked with index 1 |

## Edge Cases

- **Empty topics array**: Component renders header and empty list when `topics` is an empty array. No buttons are rendered.
- **Negative or out-of-bounds activeIndex**: Component renders all topics without active class when `activeIndex` does not match any valid array index (e.g., activeIndex = -1 or activeIndex >= topics.length).
- **Large topic list**: Component renders all topics provided; no pagination or virtualization is implemented. Scrolling is handled by CSS/container layout.
- **Missing or undefined title**: `TopicData.title` is typed as a required `string` (see the `TopicData` interface), so a well-typed caller cannot omit it. If the type system is bypassed and `title` is `undefined` at runtime, React renders no text for that child, leaving the button visually empty; the component does not guard against this itself.
- **Visibility toggle**: Switching `visible` between true and false updates only the CSS class; underlying DOM elements remain in the tree, affecting accessibility and layout reflow.
- **Rapid selection changes**: Multiple rapid calls to `onSelectTopic` are processed sequentially; no debouncing or race condition handling is present in the component.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| topics | TopicData[] | required | Array of topic objects to display; each has `title` and `messageIndex`, plus other `TopicData` fields |
| activeIndex | number | required | Zero-based index of the currently active/selected topic, supplied and owned by the parent |
| onSelectTopic | (index: number) => void | required | Callback fired when a topic button is clicked with the selected topic's index |
| visible | boolean | required | Controls visibility state; true applies "pc-pane-visible", false applies "pc-pane-hidden" |

## Deep Linking

| Platform | Applicable |
|----------|-----------|
| Apple | Not applicable: selection state (`activeIndex`) is owned by the parent; deep-linking to a topic is the parent's routing responsibility |
| Android | Not applicable: selection state (`activeIndex`) is owned by the parent; deep-linking to a topic is the parent's routing responsibility |
| Web | Deep linking is not implemented in the component; URL routing is handled by the consuming application |

## Localization

The header text is currently a hardcoded string literal in `TopicsPane.tsx` (see **render-header**), not read from a resource file. The key below is the recommended externalization target, not a key the current source reads.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| pane.header.topics | "Topics" | Header text for the topics pane |

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not implemented in source. Component does not respond to prefers-reduced-motion; CSS transitions applied by stylesheet may still animate |
| Increase Contrast | Not implemented in source. No adaptive color contrast logic in component |
| Differentiate Without Color | Not implemented in source. Active state is conveyed via "active" class; implementation details left to stylesheet |

## Feature Flags

Recommended for future rollout control; the current source contains no feature-flag check — `topics_pane.enabled` is not read anywhere in `TopicsPane.tsx`.

| Flag Key | Default | Description |
|----------|---------|-------------|
| topics_pane.enabled | true | Feature flag to enable/disable the topics pane component |

## Analytics

Recommended instrumentation; the current source emits no analytics events.

| Event | Properties | When |
|-------|-----------|------|
| topics_pane.displayed | { visible: boolean } | Component renders with visible state |
| topics_pane.topic_selected | { topicIndex: number } | User clicks a topic button |

## Privacy

- **Data collected**: Topic title text and selection index. No personal data is collected by the component itself.
- **Storage**: No data is persisted by the component; selections are passed to parent via callback.
- **Transmission**: Selections are passed to parent component; data transmission depends on parent implementation.
- **Retention**: No data is retained by the component.

## Logging

Recommended log points; the current source contains no logging calls.

Subsystem: `chat.topics-pane` | Category: `TopicsPane`

| Event | Level | Message |
|-------|-------|---------|
| Component render | debug | `TopicsPane: rendered with ${topics.length} topics, activeIndex=${activeIndex}, visible=${visible}` |
| Topic selected | debug | `TopicsPane: topic selected, index=${index}` |

## Platform Notes

- **Web**: Source implementation uses React functional component with CSS class-based styling. Topics rendered as semantic `<button>` elements within `<ul><li>` structure. Visibility toggled via CSS classes `pc-pane-visible` and `pc-pane-hidden`.
- **SwiftUI**: Implement as a ScrollView containing a VStack of Button elements. Selection is parent-controlled: bind the active index to a value the parent owns (e.g. a passed-in parameter or `Binding<Int?>`) rather than local `@State`, mirroring the source's `activeIndex`/`onSelectTopic` props. Apply opacity or a visibility modifier based on the `visible` prop. Render a Text header above the list.
- **Compose**: Use a Column containing a Text header and a LazyColumn of Button composables. Selection is parent-controlled: hoist the active index to a parameter/callback pair supplied by the caller rather than local `mutableStateOf`, mirroring the source's `activeIndex`/`onSelectTopic` props. Apply alpha or visibility based on the `visible` prop.
- **AppKit / UIKit**: Implement as an NSView or UIView containing an NSTableView/UITableView or NSCollectionView/UICollectionView displaying topics as cells. Apply NSView.isHidden or UIView.alpha based on visible prop. Highlight the selected row from a parent-owned index rather than internally tracked selection state.
- **WinUI 3**: Implement as a Grid or StackPanel containing a TextBlock header and an ItemsControl or ListView displaying topics as Button elements. Use the `Visibility` property (`Visible`/`Collapsed`) for the visibility state, mirroring the source's `pc-pane-visible`/`pc-pane-hidden` classes — not `IsEnabled`, which governs interactability rather than visibility. Apply visual state or highlight to the selected item via `ItemContainerStyle`, driven by a parent-owned selected index.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/chat/src/modes/three-pane/TopicsPane.tsx` | unverified |

## Design Decisions

**Decision**: Apply visibility and active state via CSS classes (`pc-pane-visible`/`pc-pane-hidden`, `active`) rather than inline styles.
**Rationale**: Delegates appearance control to stylesheets, supporting theme switching and design system consistency.
**Approved**: pending

**Decision**: Identify the active topic by its array index rather than by object identity or a unique key property.
**Rationale**: Keeps selection state simple and couples it directly to list order.
**Approved**: pending

**Decision**: Render a `ConnectorAnchor` child inside each topic button.
**Rationale**: Indicates this component participates in a visual linking/diagramming system where topics connect to other pane elements.
**Approved**: pending

**Decision**: Leave `activeIndex` allowed to be `undefined` or out-of-bounds, with no default active selection.
**Rationale**: Leaves the choice of a default selection to the parent component's own logic.
**Approved**: pending

**Decision**: Accept the connascence-of-position risk of index-based selection (`activeIndex`, `onSelectTopic(index)`) rather than keying selection to a stable identifier such as `messageIndex`.
**Rationale**: Matches the source's array-index selection model described above; reordering or inserting topics can silently shift which topic `activeIndex` points at. This is recorded as known debt rather than fixed here, since the source does not implement stable-key selection.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

Passed rows rest on the source's use of semantic `<button>`, `<ul>`, and `<li>` elements whose accessible names come from topic title text content; partial rows reflect that touch-target sizing, color contrast, and font scaling are defined in an external stylesheet this component's source does not show; the failed rows reflect the "Topics" header being a hardcoded string literal in `TopicsPane.tsx` rather than a resource lookup. `separation-of-concerns` passes because `TopicsPane.tsx` is pure presentation over its props with no business logic of its own, while `unit-test-coverage` fails because no test exercises it.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; clarified the connector-anchor id format and reworded the selection-callback requirement; corrected Configuration to reflect that all props are required with no defaults; fixed the WinUI visibility API and made SwiftUI/Compose selection parent-controlled; rebuilt Compliance with valid checks and links; reformatted Design Decisions and recorded index-based selection as known debt; marked Feature Flags/Analytics/Logging as recommendations rather than observed behavior; corrected the web tap-target guidance to WCAG 2.5.8; resolved the Deep Linking/Platform Notes contradiction; clarified the Localization key as a recommended externalization target; and added connector-anchor to depends-on |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source code analysis |
