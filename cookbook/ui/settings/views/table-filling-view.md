---
id: 0ce0cf31-d8a7-4e46-afa4-e488b49266f4
title: "Table Filling View"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A container that pins an editable table card to its top, full width, and gives the table all the remaining height as the window resizes."
platforms:
  - swift
  - macos
tags:
  - ui
  - settings
  - table
  - layout
depends-on: []
related:
  - 9016cb03-9682-404f-b787-c271039f25b3
  - a1d787e2-2e3f-4742-a30b-120a8607c518
references: []
approved-by: ""
approved-date: ""
---

# Table Filling View

## Overview

The table filling view holds one editable table card at the top, as wide as
itself, and gives the card's table whatever height is left. The table then
grows and shrinks with the window and never draws empty rows below a short
card. The card keeps a fixed height by design; telling it the height is this
view's job. See
[adhsdk.ingredient.ui.settings.views.editable-table-card](cookbook:9016cb03-9682-404f-b787-c271039f25b3)
for the card.

It is used wherever a settings panel or editor is mostly one table: the excluded
files panel, the privacy words editor, the browser engine panels and the Safari
extensions panel.

## Behavioral Requirements

- **main-actor-confined**: The view MUST be confined to the main actor.
- **holds-one-card**: The view MUST hold exactly the card it was given and MUST expose it as `card`.
- **card-pinned-top**: The card MUST be pinned to the view's top, leading and trailing edges, so it is full width and starts at the top.
- **card-height-not-pinned**: The view MUST NOT pin the card's bottom or give it a fixed height; the card's own table height constraint sets the card's height.
- **table-fills-slack**: After each layout, the view MUST set the card's `tableHeight` to its current value plus the difference between the view's height and the card's height.
- **slack-threshold**: The view MUST change `tableHeight` only when that difference is more than half a point either way, so rounding noise does not start a layout loop.
- **shrinks-with-view**: A negative difference MUST shrink the table, so the card follows the view down as well as up.
- **minimum-height**: The view MUST ask its container for at least `minimumHeight` points, default 120, and no more than that; it MUST NOT hold the card's current height as a minimum, so the difference can go negative.
- **card-floor**: The shrinking MUST stop at the card's own floor of one row; the view MUST NOT set a smaller height itself.
- **no-coder-init**: The view MUST NOT be creatable from a decoder.
- **card-autolayout**: The view MUST turn off the card's autoresizing-mask constraints.

## Appearance

- **Corner radius**: Not set; the card draws its own.
- **Padding**: None; the card touches the top, leading and trailing edges and any spacing is the owner's.
- **Font**: Not applicable: the view draws no text.
- **Background**: None; the view draws nothing of its own.
- **Foreground/Text**: Not applicable.
- **Border**: None.
- **Shadow**: None.
- **Min/Max size**: Minimum height 120 points by default, set by the initializer; no maximum.

## States

| State | Appearance change |
|-------|------------------|
| Default | The card at the top; its table as tall as the view allows |
| Grown | The window gets taller: the table gets the added height |
| Shrunk | The window gets shorter: the table gets shorter, down to the card's one-row floor |
| At minimum | The view is `minimumHeight` tall; the card is as short as it can be inside it |
| Pressed | Not applicable: the view has no interaction of its own |
| Disabled | Not applicable: the view has no enabled state |
| Focused | Not applicable: focus belongs to the card's controls |
| Loading | Not applicable: no loading state |

## Accessibility

- Role/trait: None of its own; the view is a plain container, and the card is the accessible element.
- Label requirements: None; the card labels its table.
- Announce state changes: Not applicable: resizing the table changes no content.
- Minimum tap target: Not applicable: the view has no controls.

## Conformance Test Vectors

No test beside the source exercises this view. These vectors are derived from
the source and untested.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| table-filling-001 | holds-one-card, card-pinned-top | Build with a card and lay out at 600 by 400 | `card` is the given card; its frame starts at the top edge and spans 600 points |
| table-filling-002 | table-fills-slack | A card 250 points tall in a view 400 tall | After layout the card's `tableHeight` is 150 points greater and the card's height is 400 |
| table-filling-003 | shrinks-with-view | The view goes from 400 to 300 points tall | `tableHeight` drops by 100 points |
| table-filling-004 | slack-threshold | A view 0.4 points taller than the card | `tableHeight` is unchanged |
| table-filling-005 | slack-threshold | A view 0.6 points taller than the card | `tableHeight` grows by 0.6 |
| table-filling-006 | minimum-height | Default initializer; read the view's fitting height | At least 120 points |
| table-filling-007 | minimum-height | `minimumHeight` of 200 | At least 200 points |
| table-filling-008 | card-floor | The view is much shorter than one row plus header | The card's `tableHeight` is one row, not less, and the view's minimum height still holds |
| table-filling-009 | card-autolayout | After building | The card does not translate autoresizing masks into constraints |

## Edge Cases

- **View shorter than the card's floor** (MUST): The card stops at one row; the owner's window should keep the view at least `minimumHeight` tall.
- **Rounding noise** (MUST): Differences of half a point or less are ignored, so a layout that settles at a fractional height does not loop.
- **Card whose rows fit all** (SHOULD): A card with `fitsAllRows` on sets its own table height from its rows, which this view then overrides on the next layout; owners SHOULD NOT combine the two.
- **Layout before the card is sized** (MUST): The first layout sets the table to fill the view; no earlier height is assumed.
- **Concurrent access** (MUST): Confined to the main actor.
- **Decoding or restoring**: Not applicable: it is built only in code.
- **Network or offline state**: Not applicable.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| card | EditableTableCard | none (required) | The card held at the top |
| minimumHeight | CGFloat | 120 | The least height the view asks of its container |

## Deep Linking

Not applicable: the view has no address or route.

## Localization

Not applicable: the view has no text.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the view adds no animation. |
| Increase Contrast | Not applicable: the view draws nothing. |
| Differentiate Without Color | Not applicable: the view draws nothing. |

## Feature Flags

Not applicable: the source reads no feature flag.

## Analytics

Not applicable: the source emits no analytics event.

## Privacy

- **Data collected**: None.
- **Storage**: None.
- **Transmission**: None.
- **Retention**: Not applicable.

## Logging

Not applicable: the source writes no log entry.

## Platform Notes

- **SwiftUI**: The source is `packages/apple/AgenticDeveloperHubSDK/macOS/SystemIntegration/ComposableSettingsWindow/Views/TableFillingView.swift`, an AppKit `NSView`. In SwiftUI, put a `Table` in a `VStack` with `.frame(maxHeight: .infinity)`; SwiftUI sizes the table to the space left, so no height pass is needed.
- **Compose**: A `Column` with the card at the top and a `LazyColumn` given `Modifier.weight(1f)` so it takes the remaining height; set `fillMaxWidth()` on both.
- **React/Web**: A flex column container with `min-height: 120px`; the table wrapper takes `flex: 1 1 auto; min-height: 0; overflow: auto`.
- **AppKit / UIKit**: In AppKit the view pins the card's top, leading and trailing anchors and overrides `layout()` to add the slack to `tableHeight`. A height anchor at or above the minimum lets the view shrink below the card's current height. On UIKit, give the table view a `heightAnchor` equal to the container's remaining height, or use a `UIStackView` with the table set to low content-hugging priority.
- **WinUI 3**: A `Grid` with two rows: `RowDefinition Height="Auto"` for any card header and `Height="*"` for a `ListView` or `DataGrid`, with `MinHeight="120"` on the Grid; the star row fills the rest with no code-behind.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/SystemIntegration/ComposableSettingsWindow/Views/TableFillingView.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The view tells the card its height after layout, rather than pinning the card's bottom.
**Rationale**: The card owns a height constraint on its table, so a pinned bottom would fight it; setting the table height keeps the card's own sizing in charge.
**Approved**: pending

**Decision**: The view asks only for a minimum height, not the card's current height.
**Rationale**: A minimum equal to the card's height would let the view grow but never shrink, because the slack could never go negative.
**Approved**: pending

**Decision**: Differences of half a point or less are ignored.
**Rationale**: Fractional frames would otherwise change the height, trigger layout and change it again.
**Approved**: pending

**Decision**: The view is a separate container, not a mode of the card.
**Rationale**: Only owners whose card fills a resizable window need it; the card stays reusable in a scrolling pane.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |

The view does one job, sizing the table to the space left, and leaves the
table's content to the card, so separation of concerns passes. No test covers
the view, so unit test coverage fails. It is a plain `NSView` with Auto Layout,
so native controls preference passes.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
