---
id: e86eb195-1ec2-4b12-8a24-79f8c03f65ce
title: "Empty State"
type: ingredient
version: 1.1.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A standardized placeholder component displaying centered content with an optional icon, title, description, and action."
platforms:
  - typescript
  - web
tags:
  - placeholder
  - empty-state
  - ui-component
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Empty State

## Overview

The Empty State component renders a standardized "nothing here yet" placeholder — a centered container with a dashed border that displays a title, optional description, optional icon, and optional action. It provides a consistent treatment across panes and views where content is absent, replacing ad-hoc border-dashed boxes with a single blessed component.

## Behavioral Requirements

- **title**: Component MUST render the `title` prop as required content in a centered layout.
- **dashed-border**: Component MUST display a dashed border around the container.
- **non-optional-title**: Component MUST declare `title` as a required, non-optional prop, rejecting a missing value at the type level rather than leaving the runtime behavior undefined.
- **optional-icon**: Component MUST render the `icon` prop when provided, positioned above the title, and MUST NOT render the icon wrapper when `icon` is absent.
- **icon-size**: When `icon` is provided, the icon wrapper MUST constrain it to 24×24px (6×6 units).
- **optional-description**: Component MUST render the `description` prop when provided, positioned below the title, and MUST NOT render the description wrapper when `description` is absent.
- **optional-action**: Component MUST render the `action` prop when provided, positioned below the description, and MUST NOT render the action wrapper when `action` is absent.
- **classname**: Component MUST accept and apply a `className` prop for custom styling via class composition.
- **centered-content**: Component MUST center all content both horizontally and vertically within the container.
- **minimum-height**: Component MUST enforce a minimum height of 160 pixels.

## Appearance

- **Container**: Flex column layout, items centered on both axes, dashed border, rounded corners
- **Padding**: 24px
- **Border**: Dashed, 1px width, color token `apt-border`
- **Border radius**: 8px
- **Minimum height**: 160px
- **Gap between elements**: 8px
- **Icon size**: 24×24px
- **Icon color**: `apt-text-dim`
- **Title font**: 14px (0.875rem), color `apt-text-muted`
- **Description font**: 12px (0.75rem), color `apt-text-dim`, max width ~65ch
- **Action margin**: 4px top

## States

| State | Appearance change |
|-------|-------------------|
| Default | Dashed border, centered content, standard spacing |

Not applicable: Component is a static presentation container with no interactive states.

## Accessibility

- **Role**: The container is a plain `div` with no ARIA landmark or region role; it carries no implicit semantics of its own.
- **Content responsibility**: The `title`, `description`, and `action` are provided as ReactNode by the consumer; component does not wrap them with semantic markup.
- **Minimum height and padding**: Ensure adequate spacing around content for readability.
- **Icon visual only**: Icon is purely presentational; no aria-label is required on the component itself.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| empty-state-001 | title | `title="No items"` | Title text "No items" appears centered in container |
| empty-state-002 | dashed-border | Default props | Container has visible dashed border |
| empty-state-003 | minimum-height | Default props | Container height is at least 160px |
| empty-state-004 | optional-icon, icon-size | `icon={<Icon />}` | Icon is rendered above title and its wrapper constrains it to 24×24px |
| empty-state-005 | optional-description | `description="Try adding an item"` | Description text appears below title |
| empty-state-006 | optional-action | `action={<Button>Create</Button>}` | Action button appears below description |
| empty-state-007 | classname | `className="bg-red-100"` | Custom class is applied to container |
| empty-state-008 | centered-content | `title="Centered"` rendered inside a container constrained to 320px width | Title text is centered horizontally and vertically within the 320px-wide container |
| empty-state-009 | optional-icon, optional-description, optional-action | `title`, no other props | Only title is rendered; description, action, and icon wrappers are absent |
| empty-state-010 | non-optional-title | Omit the `title` prop entirely | TypeScript compiler rejects the call with a type error (`title` is a required, non-optional prop) |

## Edge Cases

- **Null or empty title**: `title` is a required, non-optional prop (see **non-optional-title**); omitting it is a compile-time TypeScript error, so the component never receives a null or undefined title at runtime. A caller passing an empty string or empty fragment renders an empty but valid title area; layout is unaffected.
- **Very long title text**: Component renders title with `text-center` and no truncation constraint; long titles may wrap or overflow depending on container width. Component respects consumer's width context.
- **Long description text**: Description has `max-w-prose` constraint; text wrapping is handled by the prose width, preventing excessive line length.
- **No icon provided**: Icon div is not rendered (conditional render); layout remains centered.
- **All optional props omitted**: Component renders only title and border container, maintaining 160px minimum height.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `title` | ReactNode | (required) | Primary text content displayed in the container |
| `description` | ReactNode | undefined | Optional secondary text displayed below title |
| `action` | ReactNode | undefined | Optional action element (e.g., button) displayed below description |
| `icon` | ReactNode | undefined | Optional icon element displayed above title |
| `className` | string | undefined | Optional CSS class(es) merged with base styles via class composition |

## Deep Linking

Not applicable: Component is a presentational element without route or deep-link semantics. Deep linking is managed by the parent route or view that contains the Empty State.

## Localization

Not applicable: Component does not manage string content; all text is provided by the consumer as props. Localization is the responsibility of the calling code.

## Accessibility Options

- **Reduce Motion**: Not applicable; component is static and has no animations.
- **Increase Contrast**: Component uses design tokens (`apt-border`, `apt-text-muted`, `apt-text-dim`) that are defined at the design system level; contrast adherence is delegated to the token definitions.
- **Differentiate Without Color**: Component relies on design tokens; differentiation without color is the responsibility of the design system and the consuming code providing meaningful text content.

## Feature Flags

Not applicable: Component has no conditional behavior requiring feature flags.

## Analytics

Not applicable: Component does not emit analytics events. Consuming recipes that want to track empty-state visibility or action clicks should emit their own `empty_state.viewed` and `empty_state.action_clicked` events; the component itself has no instrumentation.

## Privacy

- **Data collected**: None — component is a presentational wrapper with no data collection or transmission.
- **Storage**: Not applicable.
- **Transmission**: Not applicable.
- **Retention**: Not applicable.

## Logging

Not applicable: Component performs no operations requiring debug or error logging.

## Platform Notes

- **React/Web**: Implemented as a stateless functional component. Uses Tailwind CSS for styling via the `cn` utility (class-name composition): `rounded-lg border border-dashed border-apt-border p-6` for the container, `text-sm text-apt-text-muted` for the title, `max-w-prose text-xs text-apt-text-dim` for the description, `[&_svg]:size-6` for the icon, and `mt-1` for the action wrapper. Files: `packages/web/packages/ui/src/components/empty-state.tsx`.
- **SwiftUI**: Map to a `VStack` with `alignment: .center`. A `Divider` cannot render a dashed stroke, so draw the border with `.overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 4])))` and `.frame(minHeight: 160)`. Map `apt-border` to `Color(.separator)`, `apt-text-muted` to `Color(.secondaryLabel)`, and `apt-text-dim` to `Color(.tertiaryLabel)`. Padding: 24pt. Icon size: 24×24pt.
- **Compose**: Map to a `Column` with `verticalArrangement = Arrangement.Center` and `horizontalAlignment = Alignment.CenterHorizontally`. Draw the dashed border with `Modifier.drawBehind` using a `Canvas`/`Path` and `PathEffect.dashPathEffect`. Map `apt-border` to `MaterialTheme.colorScheme.outlineVariant`, `apt-text-muted` to `MaterialTheme.colorScheme.onSurfaceVariant`, and `apt-text-dim` to the same `onSurfaceVariant` at reduced alpha. Minimum height: 160dp, padding: 24dp. Icon size: 24×24dp.
- **AppKit / UIKit**: Map to `NSStackView` (macOS) or `UIStackView` (iOS) with vertical axis, center alignment, and center distribution. Render dashed border using `CAShapeLayer` with a dash pattern. Map `apt-border` to `.separator`, `apt-text-muted` to `.secondaryLabelColor` / `.secondaryLabel`, and `apt-text-dim` to `.tertiaryLabelColor` / `.tertiaryLabel`. Minimum height: 160pt, padding: 24pt. Icon size: 24×24pt.
- **WinUI 3**: A `Border` has no `StrokeDashArray`, so use a `Grid` that layers a `Rectangle` (with `StrokeDashArray="4,4"`, `RadiusX="8"`, `RadiusY="8"`) behind a `StackPanel` with `Orientation="Vertical"`, `HorizontalAlignment="Center"`, and `VerticalAlignment="Center"`. Map `apt-border` to `{ThemeResource ControlStrokeColorDefaultBrush}`, `apt-text-muted` to `{ThemeResource TextFillColorSecondaryBrush}`, and `apt-text-dim` to `{ThemeResource TextFillColorTertiaryBrush}`. Set `MinHeight="160"`, padding: 24. Icon size: 24×24.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/empty-state.tsx` | unverified |

## Design Decisions

**Decision**: Use a dashed border as the visual marker for an empty or transitional state.
**Rationale**: This treatment replaces ad-hoc `border-dashed` utility classes scattered across the application, so every empty state signals absence of content the same way.
**Approved**: pending

**Decision**: Position the optional icon above the title rather than requiring it.
**Rationale**: Allows a visual cue (e.g., an empty folder icon) without forcing its inclusion, supporting everything from a minimal title-only state to a rich icon + title + description + action state.
**Approved**: pending

**Decision**: Fix the minimum height at 160px.
**Rationale**: Ensures the placeholder is substantial enough to be noticeable even when the title is brief; padding and gap values are tuned to this minimum.
**Approved**: pending

**Decision**: Accept `action` as an unconstrained `ReactNode` rather than a typed button/link.
**Rationale**: Lets consumers provide buttons, links, or other interactive elements appropriate to their context without the component dictating semantics.
**Approved**: pending

**Decision**: Delegate all color values to design tokens (`apt-border`, `apt-text-muted`, `apt-text-dim`) instead of hard-coded values.
**Rationale**: Keeps the component consistent with the design system and lets it follow theme switching automatically.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | passed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

These statuses rest on the source's rem-based Tailwind font utilities (`text-sm`/`text-xs`) and design-token-delegated colors (`apt-border`, `apt-text-muted`, `apt-text-dim`) whose actual contrast the component cannot itself attest to, its plain `div`/`p` markup with no explicit ARIA roles beyond what a consumer supplies, and its title/description/action content being entirely consumer-supplied `ReactNode` rather than strings hardcoded in the component. `separation-of-concerns` is `passed` because the component is pure presentation over props with no business logic; `unit-test-coverage` is `passed` because `emptyState.test.tsx` renders `EmptyState` directly and asserts its title/description/action/icon rendering.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names and reworded the optional-icon/description/action requirements as explicit MUST render-when-provided/MUST NOT render-when-absent; added non-optional-title and icon-size requirements with matching test vectors and gave vector 008 a concrete container width; rewrote Appearance in exact pixel/token values, leaving Tailwind class names in the React/Web platform note; marked Analytics not applicable and moved the event names to consumer guidance; reformatted Design Decisions into Decision/Rationale/Approved entries; relinked and re-scored the Compliance table against the compliance catalog; clarified the container's accessibility role as having no landmark; fixed the SwiftUI Divider and WinUI Border dashed-border APIs and named the native color mappings for `apt-border`/`apt-text-muted`/`apt-text-dim` across SwiftUI, Compose, AppKit/UIKit, and WinUI 3; renamed the Swift/iOS and Kotlin/Android platform-note labels to SwiftUI and Compose and removed the React-hooks-optional noise; unquoted the `modified` frontmatter field |
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation from web source |
