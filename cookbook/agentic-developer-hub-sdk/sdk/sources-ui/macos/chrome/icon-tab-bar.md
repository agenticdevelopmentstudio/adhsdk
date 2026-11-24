---
id: 3ea29850-3693-4a77-b6fa-c39666bb3582
title: "Icon Tab Bar"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A themed row of icon segments that picks one of several panels, reports clicks and leaves the choice with the caller."
platforms:
  - swift
  - macos
tags:
  - chrome
  - navigation
  - segmented-control
  - theming
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# Icon Tab Bar

## Overview

A row of icons that picks one of several panels, drawn the way Xcode's navigator selector is: AppKit's own segmented control, a capsule track with the chosen icon on a rounded accent selection. The bar is themed from the semantic palette and sized to its icons rather than to the space it sits in. It shows a choice and reports a click; what is chosen lives with the caller, which sets `selectedID` back. A click does not move the keyboard, because the control refuses first responder, so a caller whose panel has a list to type into moves the keyboard there itself.

The source's one caller is the project shelf, which builds one item per shelf panel and gives the bar the accessibility identifier `project-shelf.panels`.

## Behavioral Requirements

- **one-segment-per-item**: The component MUST render exactly one segment for each item it is given, in the order given.
- **symbol-image**: The component MUST draw each segment as the system symbol named by the item's `symbol`, with the item's `title` as the image's accessibility description.
- **missing-symbol-blank**: When an item's `symbol` names no system symbol, the component MUST draw that segment with an empty image rather than fail.
- **select-one-tracking**: The component MUST allow at most one segment to be drawn as selected at a time.
- **segment-width**: The component MUST give every segment a width of 32 points.
- **equal-distribution**: The component MUST distribute its segments with equal widths.
- **hug-icons**: The component MUST size itself to exactly its control, and MUST resist horizontal stretching with required content-hugging priority, so a caller that centres it gets a bar that hugs its icons.
- **tooltip-title**: The component MUST show the item's `title` as the tooltip of its segment.
- **selected-id-display**: When `selectedID` is set to the `id` of an item, the component MUST draw that item's segment as selected.
- **selected-id-none**: When `selectedID` is `nil` or matches no item, the component MUST draw no segment as selected.
- **selected-id-unchanged**: Setting `selectedID` to the value it already holds MUST NOT redraw the selection.
- **report-click**: When the user clicks a segment, the component MUST call `onSelect` once with that item's `id`.
- **caller-owns-choice**: When the user clicks a segment, the component MUST redraw the selection from `selectedID` before calling `onSelect`, so a pick the caller refuses does not stay drawn.
- **ignore-out-of-range**: The component MUST NOT call `onSelect` when the control reports a selected segment outside the item list.
- **no-keyboard-capture**: The component MUST NOT take keyboard focus when clicked, and MUST NOT draw a focus ring.
- **accessibility-identifier**: The component MUST set the `accessibilityID` it is initialised with as the accessibility identifier of its control.
- **theme-track-appearance**: The component MUST draw its track with the dark appearance when the palette's window background has a brightness component below 0.5, and with the light appearance otherwise, whatever the system appearance is.
- **theme-accent-selection**: The component MUST colour the selected segment's bezel with the palette's accent colour.
- **theme-initial-apply**: The component MUST apply the current palette when it is created.
- **theme-follow-changes**: The component SHOULD re-apply the palette each time its theme observer reports a new palette, so the track and selection follow a theme change without the caller's help.
- **no-coder-init**: The component MUST NOT support creation from an archive; `init(coder:)` is unavailable and traps.
- **main-actor**: The component MUST be used on the main actor.

## Appearance

- **Corner radius**: Not set by the component; the capsule track and the rounded selection are drawn by AppKit's segmented control.
- **Padding**: None; the view's top, bottom, leading and trailing edges are pinned to the control's.
- **Font**: Not applicable: segments carry images only, no text.
- **Background**: The control's own capsule track, drawn in the dark or light appearance chosen from the palette's window background (see **theme-track-appearance**).
- **Foreground/Text**: The system symbol images as AppKit draws them in a segmented control.
- **Border**: None set by the component; the focus ring is turned off.
- **Shadow**: None set by the component.
- **Min/Max size**: Each segment is 32 points wide, so the bar is as wide as its segments at the control's default segment spacing; height is the control's intrinsic height. The bar does not grow to fill its container.

## States

| State | Appearance change |
|-------|------------------|
| Default | Segments in the track; none selected until `selectedID` names an item |
| Selected | The chosen segment's bezel is the palette's accent colour |
| No selection | `selectedID` is `nil` or unknown; no segment drawn as selected |
| Pressed | Drawn by AppKit's segmented control; the component adds nothing |
| Dark theme | Track drawn in the dark appearance when the window background brightness is below 0.5 |
| Light theme | Track drawn in the light appearance otherwise |
| Disabled | Not applicable: the component never sets the control's enabled state, so it has no disabled appearance of its own |
| Focused | Not applicable: the control refuses first responder and its focus ring is off, so it never shows focus |
| Loading | Not applicable: the bar is static and has no asynchronous work |

## Accessibility

- **role**: The control's segments are radio buttons, described by their items' titles (the initialiser's documentation states this; the titles reach assistive technology as each segment image's accessibility description).
- **identifier**: The control carries the caller's `accessibilityID` as its accessibility identifier.
- **labels**: Every segment has a title as its accessibility description and as its tooltip.
- **state-announcement**: The selected segment is the control's selected segment, so assistive technology reads selection from AppKit's own control; the component adds no announcement.
- **keyboard-access**: NEEDS REVIEW: Not implemented in source. The control sets `refusesFirstResponder` and turns the focus ring off, so no keyboard path reaches the segments; evidence that would settle it is whether the caller offers another keyboard route to switch panels or whether Full Keyboard Access is expected to cover it.
- **target-size**: NEEDS REVIEW: Not implemented in source. Segments are 32 points wide and the height is the control's intrinsic height; whether that meets the project's pointer target size is a design decision this source cannot make, and a measured intrinsic height would settle it.
- **contrast**: NEEDS REVIEW: Not implemented in source. The selection colour is the theme's accent and the track is a system shade; whether the symbol on the accent meets contrast for every built-in theme can only be settled by measuring each theme's accent against the control's symbol colour.

## Conformance Test Vectors

No test file exists beside the source (a search of the repo found none naming `IconTabBar`), so these vectors are derived from the source's behaviour.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| icon-tab-bar-001 | one-segment-per-item | Three items created in the order a, b, c | Control has three segments in that order |
| icon-tab-bar-002 | one-segment-per-item | An empty item list | Control has no segments; no crash |
| icon-tab-bar-003 | symbol-image, tooltip-title | Item with symbol `folder` and title `Projects` | Segment image is the `folder` symbol with accessibility description `Projects`; tooltip is `Projects` |
| icon-tab-bar-004 | missing-symbol-blank | Item whose symbol names no system symbol | Segment is drawn with an empty image; creation succeeds |
| icon-tab-bar-005 | segment-width, equal-distribution | Any item list | Each segment width is 32 and widths are equal |
| icon-tab-bar-006 | hug-icons | Bar placed in a container much wider than its icons | Bar stays its icon width; it does not stretch |
| icon-tab-bar-007 | selected-id-display, select-one-tracking | Set `selectedID` to the second item's id | Second segment selected; no other segment selected |
| icon-tab-bar-008 | selected-id-none | Set `selectedID` to an id no item has | No segment selected |
| icon-tab-bar-009 | selected-id-none | Set `selectedID` to `nil` after an item was selected | No segment selected |
| icon-tab-bar-010 | selected-id-unchanged | Set `selectedID` to the value it already holds | Selection is not redrawn |
| icon-tab-bar-011 | report-click | Click the third segment | `onSelect` is called once with the third item's id |
| icon-tab-bar-012 | caller-owns-choice | `selectedID` is the first item's id; click the second segment; caller does not update `selectedID` | `onSelect` receives the second id; first segment is drawn selected again |
| icon-tab-bar-013 | caller-owns-choice | As above, but caller sets `selectedID` to the second id inside `onSelect` | Second segment ends up selected |
| icon-tab-bar-014 | ignore-out-of-range | Control reports selected segment -1 or one beyond the last | `onSelect` is not called |
| icon-tab-bar-015 | report-click | `onSelect` is `nil`; click a segment | No crash; selection is redrawn from `selectedID` |
| icon-tab-bar-016 | no-keyboard-capture | Click a segment while a text field holds the keyboard | The text field keeps the keyboard; no focus ring appears |
| icon-tab-bar-017 | accessibility-identifier | Created with `project-shelf.panels` | Control's accessibility identifier is `project-shelf.panels` |
| icon-tab-bar-018 | theme-track-appearance | Palette window background with brightness 0.2 while the system is in light appearance | Control appearance is the dark one |
| icon-tab-bar-019 | theme-track-appearance | Palette window background with brightness 0.9 while the system is in dark appearance | Control appearance is the light one |
| icon-tab-bar-020 | theme-accent-selection, theme-initial-apply | Create the bar under a theme whose accent is a known colour | Selected segment bezel colour equals the palette's accent, with no change of theme needed |
| icon-tab-bar-021 | theme-follow-changes | Switch the active theme from a light one to a dark one | Track appearance and selection colour update to the new palette |
| icon-tab-bar-022 | no-coder-init | Decode the view from an archive | The unavailable initialiser traps with `init(coder:) is not supported` |
| icon-tab-bar-023 | main-actor | Use the bar from a background thread | Not permitted; the type is main-actor isolated and the compiler refuses |

## Edge Cases

- **Empty item list (MUST)**: The component creates a control with no segments; `selectedID` always draws no selection and no click can occur.
- **Duplicate item ids (SHOULD NOT)**: Selection resolves to the first item with a matching id; the later duplicate can be clicked and reports its own id but is never drawn selected through `selectedID`.
- **Unknown or nil `selectedID` (MUST)**: No segment is selected, never an error.
- **Refused pick (MUST)**: A click the caller does not echo back through `selectedID` is undone on screen at once, before `onSelect` runs.
- **Missing symbol (MUST)**: A segment with an unresolvable symbol is drawn blank but keeps its width, tooltip and clickability.
- **Unchanged `selectedID` (MUST)**: Re-setting the same value does nothing.
- **Concurrent access**: Not applicable: the type is main-actor isolated, so all access is serialised on the main thread.
- **Error states and offline**: Not applicable: the component has no network, file or other dependency that can fail; a palette is always supplied by the theme observer.
- **Palette colour not convertible to sRGB (MUST)**: The brightness test treats a window background that cannot be converted as bright (1), so the track takes the light appearance.
- **Items fixed at creation**: The item list is a constant of the instance; to change panels a caller builds a new bar.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `items` | `[IconTabBar.Item]` | none, required at init | One segment each; an item is an `id`, a `symbol` name and a `title` |
| `accessibilityID` | `String` | none, required at init | The control's accessibility identifier |
| `selectedID` | `String?` | `nil` | The item drawn as chosen; `nil` for none |
| `onSelect` | `((String) -> Void)?` | `nil` | Called with the clicked item's `id` |

## Deep Linking

Not applicable: the bar only reports a click to its caller and holds no route or location of its own; navigation belongs to the caller.

## Localization

Not applicable to the component's own text: it has no string literal. The only user-visible text is each item's `title`, supplied by the caller as tooltip and accessibility description, so localisation of those strings is the caller's.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the component adds no animation of its own. |
| Increase Contrast | Not applicable to the component's code: it reads no contrast setting; the track and symbols are drawn by AppKit and the selection is the palette's accent. |
| Differentiate Without Color | The selection is shown by a filled rounded segment against the capsule track, not by hue alone, and the segment is also the control's selected segment for assistive technology. |

## Feature Flags

Not applicable: the component reads no flag; it is always enabled when created.

## Analytics

Not applicable: the component emits no events; a caller that wants to count panel switches does so in `onSelect`.

## Privacy

- **Data collected**: None.
- **Storage**: None; the selection lives with the caller.
- **Transmission**: None.
- **Retention**: Not applicable: nothing is kept.

## Logging

Not applicable: the component logs nothing.

## Platform Notes

- **SwiftUI**: Wrap `IconTabBar` in an `NSViewRepresentable` that takes the items, a binding for the selected id and the `accessibilityID`, writes the binding into `selectedID` in `updateNSView`, and forwards `onSelect` into the binding. A native SwiftUI port is a `Picker` with `.pickerStyle(.segmented)` over image labels, given a fixed width so it hugs its icons; SwiftUI offers no accent-coloured selection bezel, so that needs a custom style.
- **Compose**: Start from Material 3 `SingleChoiceSegmentedButtonRow` with `SegmentedButton` and an `Icon` in each, or `PrimaryTabRow` with icon-only `Tab`s. Keep it stateless: take `selectedId` and an `onSelect` callback, and let the caller own the choice. Give each button a `contentDescription` from the title and a tooltip through `TooltipBox`. Colours come from the theme's primary role, and the row is sized by `Modifier.width` rather than filling its parent.
- **React/Web**: Render a `role="radiogroup"` container of `button` or `input type="radio"` elements, each with an SVG icon, an `aria-label` and `title` from the item title, and `aria-checked` for the selected one. Keep the selection as a prop and emit the id through a callback; use CSS custom properties for the accent bezel and `width: fit-content` with 32px segments. Unlike the source, a web version should be reachable by keyboard (arrow keys within the group).
- **AppKit / UIKit**: The source is `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chrome/IconTabBar.swift`: an `NSView` that is exactly its `NSSegmentedControl` (select-one tracking, equal distribution, 32-point segments, `refusesFirstResponder`, no focus ring, `selectedSegmentBezelColor` from the accent) and conforms to `Themeable`, re-applying through `ThemePaletteObserver`. On UIKit use `UISegmentedControl` with `UIImage(systemName:)` segments; it offers `setWidth` per segment but no selection bezel colour (use `selectedSegmentTintColor`), and it has its own focus behaviour on iPadOS.
- **WinUI 3**: Start from a `RadioButtons` control with `MaxColumns` set to the item count and a custom `ItemTemplate`, or a `ListView` with `SelectionMode="Single"` and a horizontal `ItemsStackPanel`. Each item is a `ToggleButton` or `RadioButton` styled with a `FontIcon` (a Segoe Fluent Icons glyph in place of the SF Symbol) at `Width="32"`, with `ToolTipService.ToolTip` and `AutomationProperties.Name` from the title, and `AutomationProperties.AutomationId` for the identifier. Draw the selection through the `Checked` visual state, setting the checked background to `AccentFillColorDefaultBrush` and the track to `ControlFillColorDefaultBrush` in a `Border` with a capsule `CornerRadius`. Keep the choice with the caller: bind `SelectedItem` one way and raise an event on `SelectionChanged` that the view model answers, resetting the selection if the caller refuses. Unlike the source, WinUI controls take keyboard focus by default; set `IsTabStop="False"` to match the source, or keep the focus visuals and arrow-key navigation to give the bar a keyboard path.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/SDK/SourcesUI/macOS/Chrome/IconTabBar.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Use AppKit's own `NSSegmentedControl` rather than drawing a custom bar.
**Rationale**: The source's comment cites `native-controls`: the control gives Xcode's navigator-selector look, hit testing and accessibility for free.
**Approved**: pending

**Decision**: The caller owns the choice. After every click the bar puts back whatever `selectedID` last said, then calls `onSelect`.
**Rationale**: The source comment says the bar puts back what the caller last said until it answers, so a refused pick does not stay drawn.
**Approved**: pending

**Decision**: The control refuses first responder and shows no focus ring, so a click leaves the keyboard where it was.
**Rationale**: A panel with a list to type into keeps the keyboard; the caller moves it there itself. The cost, noted in the open question on `keyboard-access`, is that the bar has no keyboard path of its own.
**Approved**: pending

**Decision**: The track appearance follows the palette's window background brightness (below 0.5 is dark), not the system appearance.
**Rationale**: The source comment says a dark theme gets the dark track whatever the system is set to. A background that cannot be converted to sRGB counts as bright, so it falls to the light track.
**Approved**: pending

**Decision**: Segments are a fixed 32 points wide, and the bar is exactly its control with required horizontal hugging.
**Rationale**: The source comment says a caller that centres the view gets a bar that hugs its icons, sized to them rather than to the space it sits in.
**Approved**: pending

**Decision**: A symbol that cannot be resolved becomes an empty image instead of an error.
**Rationale**: The initialiser falls back to a blank image so a bad symbol name never prevents the bar from being built. Technical debt: the failure is silent, so a mistyped symbol shows as a blank segment with only its tooltip.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | best-practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | failed | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | accessibility |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | platform-compliance |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | internationalization |

Separation of concerns passes because the bar only shows a choice and reports a click, as its own documentation says, with the choice held by the caller. Unit-test coverage fails because no test file naming the component exists in the repo. Keyboard navigation fails because the control refuses first responder and hides its focus ring, so the bar has no keyboard path of its own. Screen-reader support passes because each segment's image carries its title as an accessibility description, the control has an identifier and its segments are radio buttons. Native controls and platform theming pass because the bar is an `NSSegmentedControl` themed from the semantic palette. The hard-coded-strings check passes because the component holds no string literal that reaches the user; titles come from the caller.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
