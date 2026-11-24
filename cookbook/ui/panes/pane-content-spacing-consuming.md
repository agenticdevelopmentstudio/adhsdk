---
id: bdd78ecf-0a90-4a3c-8731-df6999442776
title: "Pane Content Spacing Consuming"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Protocol a pane's content adopts to apply the app-wide pane-content spacing itself, so the pane pins it flush and the gap is applied exactly once."
platforms:
  - swift
  - macos
tags:
  - ui
  - panes
  - spacing
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Pane Content Spacing Consuming

## Overview

`PaneContentSpacingConsuming` is a main-actor, class-bound protocol with one
method, `applyPaneSpacing(_:)`. Pane content adopts it when the content insets
itself. The source gives the example of a terminal, which holds its grid off its
own edges because a theme may override that padding.

The protocol settles who applies the gap between a pane's edge and its content.
The rule in the source is "one gap, not a second padding stacked on the first".
Content that adopts the protocol is handed the app-wide pane-content spacing
(`PaneSpacing.contentSpacing`) and does the insetting, and its pane pins it
flush. Content that does not adopt it has the gap applied for it, by the pane.
Exactly one of the two applies the gap. The choice is made by a conformance, not
by the pane knowing what a terminal is.

The protocol itself draws nothing. The pane that decides between the two paths
is `PaneViewController.applyResolvedSpacing()`, and the two adopters in the
source are the terminal content controllers.

## Behavioral Requirements

- **adopt-to-own-the-gap**: Pane content that insets itself MUST adopt the
  protocol, so that the pane hands it the gap and pins it flush.
- **apply-pane-spacing-method**: A conforming type MUST implement
  `applyPaneSpacing(_ spacing: Spacing)`, the only requirement of the protocol.
- **main-actor-isolated**: The protocol MUST be isolated to the main actor, so
  `applyPaneSpacing(_:)` MUST be called on the main thread.
- **class-bound**: Conformers MUST be classes (the protocol inherits from
  `AnyObject`), because the pane tests the content view controller for
  conformance by a cast.
- **receives-content-spacing**: The `Spacing` the pane passes MUST be the
  app-wide pane-content spacing, `PaneSpacing.contentSpacing` (the four
  pane-content edges, no gutters), and not a spacing carried by the pane or by
  the content.
- **applied-again-on-change**: The pane MUST call `applyPaneSpacing(_:)` again
  whenever a pane-content spacing setting changes (the keys in
  `PaneSpacing.contentSettingKeys`), as well as once when the pane's view loads.
- **pane-pins-flush-for-consumer**: When the content conforms, the pane MUST set
  its own content spacing insets to zero on all four sides, so the content is
  pinned flush to the pane's edges and the gap is applied only by the content.
- **pane-applies-gap-for-non-consumer**: When the content does not conform, the
  pane MUST apply the gap itself, using the spacing's `top`, `leading`, `bottom`
  and `trailing` values as the content's edge constraint constants.
- **applies-once**: The gap MUST be applied exactly once per pane: by the
  content when it conforms, by the pane when it does not, never both.
- **idempotent-assign**: Applying the gap MUST assign, not accumulate, so the
  pane's resolve step is safe to call repeatedly (the source cites
  `idempotency`).
- **no-pane-spacing-of-its-own**: Neither a pane nor its content MAY carry
  spacing of its own; the one source of the gap is the app-wide setting, so every
  pane in every window is spaced alike.
- **consumer-guards-unloaded-view**: The two conformers in the source
  (`PrivateTerminalViewController`, `TerminalSessionContentViewController`)
  MUST return without effect when their view is not loaded, and otherwise MUST
  re-apply their appearance (`reapplyAppearance()`), which is where the
  padding is set.

## Appearance

- **Gap size**: The values come from the app-wide pane-content spacing: four
  per-edge integers in points (top, leading, bottom, trailing), each defaulting to
  10 (`UserSettings.defaultPaneSpacing`), stored under `pane_content_spacing_top`,
  `pane_content_spacing_leading`, `pane_content_spacing_bottom` and
  `pane_content_spacing_trailing`.
- **Corner radius, font, background, border, shadow**: Not applicable — the
  protocol is a contract about who insets and has no visual attributes of its own.
- **Min/Max size**: The source defines no limits on the values; the setting type is
  `Int`.

## States

Not applicable — the protocol is a contract, not a visual component. It has no
visual states: the gap changes only when the spacing settings change, and each
change calls `applyPaneSpacing(_:)` again (see applied-again-on-change).

## Accessibility

Not applicable — the protocol is a spacing contract, not a visual component. It
creates no control and takes no input.

## Conformance Test Vectors

The source of the protocol has no tests beside it. The only test that touches the
spacing settings is `PaneSpacingMigrationTests`, which covers the legacy terminal
padding migration, not this protocol, so these vectors are derived from the
protocol, `PaneViewController.applyResolvedSpacing()` and the two conformers.

| ID | Requirements | Input | Expected |
|---|---|---|---|
| pane-spacing-001 | pane-pins-flush-for-consumer, applies-once | pane whose content conforms; pane-content spacing 10 on every edge | the content's `applyPaneSpacing` is called with the spacing; the pane's `contentSpacingInsets` is zero on all four sides and its content edge constraint constants are 0 |
| pane-spacing-002 | pane-applies-gap-for-non-consumer, applies-once | pane whose content does not conform; top 4, leading 6, bottom 8, trailing 10 | `contentSpacingInsets` is top 4, left 6, bottom 8, right 10 and the four content edge constraint constants take those values |
| pane-spacing-003 | receives-content-spacing | conforming content; settings top 2, leading 3, bottom 4, trailing 5 | `applyPaneSpacing` receives a `Spacing` with top 2, leading 3, bottom 4, trailing 5 and both gutters 0 |
| pane-spacing-004 | applied-again-on-change | conforming content already applied; `pane_content_spacing_top` changes | `applyPaneSpacing` is called a second time |
| pane-spacing-005 | applied-again-on-change | any pane; a setting outside `PaneSpacing.contentSettingKeys` changes (for example a frame spacing key) | no new call to `applyPaneSpacing` and no change to the content constraints |
| pane-spacing-006 | idempotent-assign | non-conforming content; `applyResolvedSpacing()` called three times with the same settings | `contentSpacingInsets` and the constraint constants are the same after the third call as after the first |
| pane-spacing-007 | pane-pins-flush-for-consumer | pane that applied a gap for non-conforming content, then its content is replaced by a conforming one and `applyResolvedSpacing()` runs | the insets and constraint constants return to 0 |
| pane-spacing-008 | consumer-guards-unloaded-view | `TerminalSessionContentViewController` whose view is not loaded | `applyPaneSpacing(_:)` returns with no effect; `reapplyAppearance()` is not called |
| pane-spacing-009 | consumer-guards-unloaded-view | `PrivateTerminalViewController` whose view is loaded | `applyPaneSpacing(_:)` calls `reapplyAppearance()` |

## Edge Cases

- **Spacing of 0 on every edge**: the gap is 0 for both paths (MUST); the
  pane still takes the conforming or non-conforming branch, and the content sits
  flush.
- **Conformance changes after load**: the pane tests conformance at each
  `applyResolvedSpacing()` call, and it takes the gap back off the other path by
  assigning the insets for the current branch (MUST); a pane whose content
  controller is swapped therefore resolves on its next call.
- **Pane with no content**: when the pane's content view controller declined to exist, there are no content edge constraints; `applyResolvedSpacing()` takes the non-conforming branch (the cast fails) and assigns `contentSpacingInsets`, and the constraint assignments do nothing (MUST).
- **Content not yet loaded**: the terminal conformers skip the call when
  `isViewLoaded` is false (MUST); the pane calls again on the next setting change,
  and the pane's own view-load pass calls it once.
- **Negative or very large values**: the source declares the settings as `Int` and
  does no clamping or validation before building the insets (the source leaves
  the range to the settings UI, outside these sources).
- **Spacing argument ignored**: both conformers in the source ignore the
  `spacing` value and re-read their appearance, where the padding is resolved
  (`TerminalAppearance.resolvedPadding` takes `PaneSpacing.contentSpacing` unless the theme's overrides set a side). The
  protocol does not require the conformer to use the value it is given.
- **Legacy terminal padding**: a terminal padding saved before pane-content
  spacing replaced it is carried across by `PaneSpacing.migrateLegacyTerminalPadding`
  (a side already holding a pane-content value keeps it), so a terminal set to 0
  does not jump to 10.
- **Concurrent access**: the protocol and the pane are `@MainActor`, so the
  compiler serializes every call on the main thread.
- **Error states and offline state**: not applicable — no I/O, no dependency that
  could be unavailable, and no operation that can fail.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `applyPaneSpacing(_ spacing:)` | `Spacing` | supplied by the pane | The gap to apply: `top`, `leading`, `bottom`, `trailing` in points (the gutters are present but 0) |
| `pane_content_spacing_top` | `UserSetting<Int>` | 10 | Pane-content inset from the top edge |
| `pane_content_spacing_leading` | `UserSetting<Int>` | 10 | Pane-content inset from the leading edge |
| `pane_content_spacing_bottom` | `UserSetting<Int>` | 10 | Pane-content inset from the bottom edge |
| `pane_content_spacing_trailing` | `UserSetting<Int>` | 10 | Pane-content inset from the trailing edge |

## Deep Linking

Not applicable: the protocol applies an inset and exposes no URL or route.

## Localization

Not applicable: the protocol owns no user-facing strings.

## Accessibility Options

Not applicable: the protocol draws nothing and animates nothing, so Reduce
Motion, Increase Contrast and Differentiate Without Color do not apply.

## Feature Flags

Not applicable: the source reads no feature flag.

## Analytics

Not applicable: the source emits no events.

## Privacy

Not applicable: the protocol stores, transmits and logs nothing; the spacing
values it carries are display preferences.

## Logging

Not applicable: the source contains no log calls.

## Platform Notes

- **SwiftUI**: Swap the conformance for a choice made in one place. A pane view takes the app-wide spacing from an `EnvironmentValues` key and applies `.padding(EdgeInsets(...))` itself for ordinary content; content that insets itself reads the same environment value and the pane applies no padding for it, for example through a content-owns-padding flag on a container. Reading the value from an `@AppStorage` backed model re-renders the view when a setting changes, which stands in for the repeated `applyPaneSpacing(_:)` call.
- **Compose**: Provide the four insets through a `CompositionLocal` (`LocalPaneContentSpacing`) holding a `PaddingValues`. The pane wraps ordinary content in a `Box` with `Modifier.padding(...)`; content that owns its padding declares it, for example by a parameter or a marker interface, and the pane then applies `PaddingValues(0.dp)`. Recomposition on a setting change replaces the repeated call.
- **React/Web**: Expose the four insets as CSS custom properties on the pane (`--pane-content-top` and so on) from a context provider. A pane wrapper applies them as padding to ordinary children; a child that owns its padding opts in with a prop or a data attribute, and the wrapper sets padding to 0. The properties change in place, so no repeated call is needed.
- **AppKit / UIKit**: The source is `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/Panes/PaneContentSpacingConsuming.swift`, a `@MainActor` protocol refining `AnyObject`. The deciding code is `PaneViewController.applyResolvedSpacing()` in the same folder (a cast to the protocol, then either the call or the edge constraint constants), the values come from `PaneSpacing.contentSpacing` in `ComposableTabs/PaneSpacing.swift`, and the adopters are `PrivateTerminalViewController` and `TerminalSessionContentViewController` under `Features/TerminalSession`. UIKit has no pane concept; the nearest tool is `directionalLayoutMargins` and `NSDirectionalEdgeInsets` on the container view, with content that owns its margins setting `insetsLayoutMarginsFromSafeArea` and its own constraints.
- **WinUI 3**: Define an interface `IPaneContentSpacingConsumer` with `void ApplyPaneSpacing(Thickness spacing)`. The pane control (a `UserControl` or a templated `ContentControl`) holds a `ContentPresenter` and tests `Content is IPaneContentSpacingConsumer`: if yes, it sets the presenter's `Margin` (or the template's padding) to `new Thickness(0)` and calls the method; if no, it sets `Padding` to a `Thickness(left, top, right, bottom)` built from the four values, mapping leading and trailing to left and right (swap them under right-to-left `FlowDirection`). Store the four values with `ApplicationData.Current.LocalSettings` or a settings service implementing `INotifyPropertyChanged`, and re-run the resolve step on `PropertyChanged` or in a `DependencyProperty` changed callback so the call repeats on each change, as in the source. Dispatch from `DispatcherQueue` to match the main-actor rule.

## Design Decisions

**Decision**: Choose who applies the gap by a protocol conformance, not by the pane inspecting what kind of content it holds.
**Rationale**: The source comment names this (`explicit-over-implicit`): the pane never learns what a terminal is, and any content that insets itself opts in by adopting the protocol.
**Approved**: pending

**Decision**: Exactly one party applies the gap: the content when it conforms, otherwise the pane, with the pane pinning conforming content flush.
**Rationale**: The source states the rule as "one gap, not a second padding stacked on the first"; letting both apply would double the padding.
**Approved**: pending

**Decision**: The gap is one app-wide setting, not per pane or per content type, and a terminal's padding is that same setting.
**Rationale**: The source says there is one inner margin, not one for terminals and another for everything else, and a window spaced differently from its neighbor reads as a bug. The legacy terminal padding is migrated into it.
**Approved**: pending

**Decision**: The gap is handed over again on every pane-content setting change, and the pane's resolve step assigns rather than accumulates.
**Rationale**: The doc comment says the method is called again whenever the setting changes, and the pane's comment cites idempotency, so repeated calls are safe.
**Approved**: pending

**Decision**: The terminal conformers use the call as a trigger to reapply appearance instead of using the `Spacing` value directly.
**Rationale**: The source says a theme may override the padding, so the terminal resolves the padding inside its appearance step, where the theme and the setting are both read.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

`separation-of-concerns` passes because the protocol carries only the decision of who
insets: the pane owns the setting and the fallback path, and the content owns its own
inset when it adopts the protocol. `unit-test-coverage` fails because no test beside
the source exercises the protocol, `applyResolvedSpacing()` or the two conformers;
the one nearby test, `PaneSpacingMigrationTests`, covers only the legacy padding
migration, so the vectors above are derived from the code.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
