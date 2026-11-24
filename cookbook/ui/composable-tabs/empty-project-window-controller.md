---
id: 0a1c6444-0efe-43f0-9d0f-2337203df95f
title: "Empty Project Window Controller"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The window shown while a project window group has no project: project chrome, the shelf and its toggle, the pane backdrop and one quiet line."
platforms:
  - swift
  - macos
tags:
  - component
  - composable-tabs
  - ui
depends-on:
  - 3f6268b8-410d-4d3c-979c-2a9f9f1534f3
  - 0640ca96-95c5-4234-925e-386425cc4435
related: []
references:
  - https://learn.microsoft.com/en-us/windows/apps/develop/title-bar
approved-by: ""
approved-date: ""
---

# Empty Project Window Controller

## Overview

`EmptyProjectWindowController` is the window a project window group shows while it has no project: a new window from File, New Project Window, or the window left behind when the group's last active project was closed. It is a [Single-Instance Window](cookbook:3f6268b8-410d-4d3c-979c-2a9f9f1534f3) controller that looks like a project window in every way that shows: the seamless title bar, the project shelf and its toggle beside the traffic lights, and the project's pane backdrop where the panes would be, with one quiet line of text. Because the chrome matches, choosing a project in the shelf swaps the project's window in without anything visibly moving. The file also declares `ProjectShelfWindow`, the protocol both halves of a project window group conform to (the window of the project on screen, and this empty window), through which the shelf's visibility and width are carried from one window of a group to the next and the shelf's keyboard commands reach whichever window is up. The window's panes are those of [Composable Tabs](cookbook:0640ca96-95c5-4234-925e-386425cc4435) when a project is loaded; here the content is a private blank view controller.

## Behavioral Requirements

- **identify-window-per-group**: `windowID(for:)` MUST return `project.window.empty.` followed by the group's UUID string, so that each group's empty window saves its frame under its own id.
- **title-projects**: The window MUST be titled "Projects", with the title hidden from the title bar.
- **default-size**: The window MUST open at 800 by 500 points when it has no saved frame and no placement template, centered on screen.
- **minimum-size**: The window MUST NOT be resizable below 400 by 300 points.
- **persist-frame**: The window MUST save and restore its frame under its window id.
- **window-style**: The window MUST be titled, closable, resizable, miniaturizable and full-size-content.
- **seamless-titlebar**: The window MUST use a unified toolbar, a transparent title bar, no title bar separator and a hidden title.
- **disallow-tabbing**: The window MUST disallow native window tabbing.
- **backdrop-color**: The window background MUST be the theme palette's project pane backdrop color, and MUST follow the palette when it changes.
- **toolbar-content**: The window toolbar MUST hold the project shelf items (including the shelf toggle) followed by a flexible space.
- **blank-content-message**: The content area MUST show the text "No project — choose one in the Project Browser." centered, in the tertiary text role and body text role, on the pane backdrop color.
- **blank-content-accessibility-id**: The message MUST carry the accessibility identifier `project.empty.message`.
- **message-keeps-margin**: The message MUST keep at least 20 points between its leading edge and the content's leading edge.
- **place-from-template**: When a placement template window is set before the window loads and there is no saved frame to restore, the window MUST take the template's size and be cascaded from the template's top-left corner, and MUST do so before it is shown.
- **default-placement-without-template**: When no placement template is set, the window MUST use the window spec's default placement.
- **toggle-shelf**: `toggleShelf()` MUST toggle the visibility of the project shelf.
- **show-shelf-for-choosing**: `showShelfForChoosing()` MUST show the shelf's browser panel, make the shelf visible, and when it is visible move keyboard focus to the shelf's filter field.
- **expose-shelf-layout**: `shelfLayout` MUST report the shelf's visibility and width, and `adoptShelfLayout(_:)` MUST apply a layout taken from another window of the group.
- **land-shelf-slide**: `landShelfSlide()` MUST complete a shelf slide in flight at its destination and run what waited for it.
- **toggle-shelf-panel**: `toggleShelfPanel(_:)` MUST hide the shelf when it is visible and already showing the given panel; otherwise it MUST show that panel, make the shelf visible and move keyboard focus to the shelf's filter field once the shelf has landed.
- **shelf-toggle-appearance**: The shelf toggle button MUST show a "sidebar.left" symbol, outline and filled the same, disclosed according to the shelf's visibility (accent tint when shown, secondary text tint when hidden), with the tooltip "Show Projects" when the shelf is hidden and "Hide Projects" when it is shown.
- **refresh-toggle-on-change**: The toggle appearance MUST be refreshed when the shelf visibility changes, when the window is shown and when the theme palette changes.
- **toolbar-delegate-retained**: The window MUST keep its own strong reference to the toolbar delegate, because the toolbar's delegate reference is weak.
- **no-coder-init**: The controller MUST NOT be creatable from a decoder; `init(coder:)` is unavailable and traps if called.

## Appearance

- **Corner radius**: Not applicable: the window has the system's window corners and the source sets none.
- **Padding**: The message keeps at least 20 points from the content's leading edge; no other padding is set.
- **Font**: The message uses the body text role of the theme, through the themed label.
- **Background**: The theme palette's project pane backdrop color, on both the window and the blank content view.
- **Foreground/Text**: The tertiary text role of the theme, centered text alignment.
- **Border**: None set by this controller.
- **Shadow**: None set by this controller.
- **Min/Max size**: Minimum 400 by 300 points; default 800 by 500 points; no maximum.

## States

| State | Appearance change |
|-------|------------------|
| Default | Backdrop, message, and the shelf hidden or shown as the adopted layout says. |
| Shelf shown | The shelf slides in beside the content; the toggle shows its disclosed appearance with the tooltip "Hide Projects". |
| Shelf hidden | The content fills the window; the toggle shows its undisclosed appearance with the tooltip "Show Projects". |
| Choosing | After `showShelfForChoosing()`, the shelf shows its browser panel with keyboard focus in the filter field. |
| Pressed | The shelf toggle button is pressed by the system; this controller adds no pressed styling. |
| Disabled | Not applicable: the window and toggle have no disabled state in the source. |
| Loading | Not applicable: the content is a static message with nothing to load. |
| Theme changed | The window and content backgrounds follow the new palette and the toggle appearance is refreshed. |

## Accessibility

- **Role/trait**: The toggle is a standard button in the window toolbar; the message is a themed text label.
- **Label requirements**: The message carries the accessibility identifier `project.empty.message`. The toggle uses the tooltips "Show Projects" and "Hide Projects", set by the shared disclosure appearance helper.
- **Announce state changes**: NEEDS REVIEW: Not implemented in source. The shared disclosure helper keeps the toggle's accessible name stable (the image's accessibility description set from the toolbar item's label) and changes only the tooltip, tint and symbol with the shelf's visibility; neither it nor this controller sets an accessibility value that follows the shelf. A VoiceOver pass over the toggle in both states would settle whether the tooltip change is announced.
- **Minimum tap target**: Not specified by this controller; the toggle's size comes from the shared toolbar builder.

## Conformance Test Vectors

No test beside the source exercises the controller (the test bundles contain no reference to it), so these vectors are derived from the source's behavior.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| empty-project-window-001 | identify-window-per-group | Call `windowID(for:)` with a group whose `uuidString` is `11111111-2222-3333-4444-555555555555` | The result is `project.window.empty.11111111-2222-3333-4444-555555555555` |
| empty-project-window-002 | title-projects, window-style | Create a controller and load its window | The title is "Projects" and the style mask contains titled, closable, resizable, miniaturizable and full-size-content |
| empty-project-window-003 | default-size, persist-frame | Show a window with no saved frame and no template | The window is 800 by 500 points and centered; its frame is saved under its window id |
| empty-project-window-004 | minimum-size | Drag the window to its smallest size | The content size stops at 400 by 300 points |
| empty-project-window-005 | seamless-titlebar, disallow-tabbing | Load the window | The toolbar style is unified, the title bar is transparent, the separator style is none, the title is hidden and tabbing is disallowed |
| empty-project-window-006 | backdrop-color | Load the window, then change the theme palette | The window background equals the new palette's project pane backdrop color |
| empty-project-window-007 | blank-content-message, blank-content-accessibility-id | Show the window | The text "No project — choose one in the Project Browser." is centered and its accessibility identifier is `project.empty.message` |
| empty-project-window-008 | message-keeps-margin | Resize the window to 400 points wide | The message's leading edge stays at least 20 points from the content's leading edge |
| empty-project-window-009 | place-from-template | Set `placementTemplate` to a 1000 by 700 window, then show a window with no saved frame | The window is 1000 by 700 points and its top-left is offset from the template's top-left by one cascade step |
| empty-project-window-010 | default-placement-without-template | Show a window with no saved frame and no template | The window is placed by the spec's default, centered |
| empty-project-window-011 | toggle-shelf, shelf-toggle-appearance | Call `toggleShelf()` on a window with the shelf hidden | The shelf is visible and the toggle tooltip is "Hide Projects" |
| empty-project-window-012 | toggle-shelf, shelf-toggle-appearance | Call `toggleShelf()` again | The shelf is hidden and the toggle tooltip is "Show Projects" |
| empty-project-window-013 | show-shelf-for-choosing | Call `showShelfForChoosing()` with the shelf hidden | The browser panel is showing, the shelf is visible and, once shown, the filter field is first responder |
| empty-project-window-014 | expose-shelf-layout, land-shelf-slide | Call `landShelfSlide()` mid-slide, read `shelfLayout`, and pass it to `adoptShelfLayout(_:)` on another window | The layout holds the final width, not a half-slid width, and the other window shows the same visibility and width |
| empty-project-window-015 | toggle-shelf-panel | Call `toggleShelfPanel(_:)` with a panel while the shelf is hidden, then again with the same panel | The first call shows that panel, makes the shelf visible and focuses the filter; the second hides the shelf |
| empty-project-window-016 | refresh-toggle-on-change | Show the window, then change the shelf visibility | The toggle appearance is refreshed after each of the show and the visibility change |
| empty-project-window-017 | toolbar-content, toolbar-delegate-retained | Load the window and let every other reference to the toolbar delegate go | The toolbar still holds the shelf items followed by a flexible space and still responds to the toggle |
| empty-project-window-018 | no-coder-init | Call `init(coder:)` | The call traps with the message "init(coder:) is not supported" |

## Edge Cases

- **Null and empty input**: With no `placementTemplate` the window MUST use the default placement; a template that has been deallocated (the reference is weak) MUST behave as none.
- **Boundary values**: A template window smaller than 400 by 300 points MUST NOT shrink the window below the 400 by 300 minimum, which the window's minimum size enforces. Repeated New Project Window commands MUST keep the cascaded window on screen, which `cascadeTopLeft(from:)` guarantees.
- **Placement timing**: The template MUST be read when the window loads, so the window is placed before it is shown; a window shown at the default and then moved shrinks and regrows in front of the user.
- **Shelf slide in flight**: A swap MUST land the slide before `shelfLayout` is read, so that a half-slid width is not handed over and the slide does not land later on a window already ordered out.
- **Concurrent access**: Not applicable: the controller and its content are `@MainActor` isolated, so all access is serialized on the main actor.
- **Error states**: Not applicable: the controller calls no dependency that can fail; a missing toggle button is skipped in `refreshShelfToggleAppearance()` by a guard.
- **Offline or disconnected state**: Not applicable: the controller performs no network access.
- **Window not yet loaded**: `showWindow(_:)` MUST load the window first when it is not loaded, then show it and refresh the toggle appearance.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `groupID` | `UUID` | required | The window group the empty window belongs to; names the saved frame. |
| `shelf` | `ProjectShelfViewController` | required | The group's shelf, shared with the project window. |
| `placementTemplate` | `NSWindow?` (weak) | `nil` | The front window the new window is sized and cascaded from. |

## Deep Linking

Not applicable: the controller has no URL routing.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal) | Projects | Window title |
| none (literal) | No project — choose one in the Project Browser. | Message in the content area |
| none (literal) | Show Projects | Toggle tooltip when the shelf is hidden |
| none (literal) | Hide Projects | Toggle tooltip when the shelf is shown |

- **string-externalization**: NEEDS REVIEW: Not implemented in source. The four strings are literals in the controller, with no string table lookup; the owner's localization approach for macOS UI strings would settle whether they move to a table.

## Accessibility Options

Not applicable: the controller sets no animation or contrast behavior of its own; the shelf slide and theme colors are the shared components'.

## Feature Flags

Not applicable: the controller has no feature flag logic.

## Analytics

Not applicable: the controller performs no analytics tracking.

## Privacy

- **Data collected**: None.
- **Storage**: The window frame is saved under the window id, which includes the group's UUID.
- **Transmission**: None.
- **Retention**: The saved frame is kept by the window frame store; this controller sets no expiry.

## Logging

Not applicable: the controller performs no logging.

## Platform Notes

- **SwiftUI**: Start with a `WindowGroup` or `Window` scene using `.windowStyle(.hiddenTitleBar)` and `.windowToolbarStyle(.unified)`, a `NavigationSplitView` whose sidebar is the shelf and whose detail is a `ZStack` of the backdrop color and a centered `Text`. Use `.defaultSize(width: 800, height: 500)` and `.windowResizability(.contentMinSize)` with a `.frame(minWidth: 400, minHeight: 300)`. Differs from the source: scene frame persistence is automatic, cascade placement is the system's, and there is no per-group window id unless a value-based `WindowGroup(for:)` is used.
- **Compose**: Compose Desktop's `Window` with `rememberWindowState(size = DpSize(800.dp, 500.dp), position = WindowPosition(Alignment.Center))` and a content `Row` of the shelf and a `Box` filled with the backdrop color holding a centered `Text`; set the minimum size on the underlying `ComposeWindow`. Differs from the source in having no native unified title bar; `undecorated` with a custom bar is the nearest, and frame persistence is manual.
- **React/Web**: A route with a two-column layout, a collapsible sidebar (the shelf), a main area on the backdrop color and a centered paragraph; persist the sidebar width and visibility in storage. Differs from the source: there is no window chrome, cascade placement or frame saving.
- **AppKit / UIKit**: `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/ComposableTabs/EmptyProjectWindowController.swift` is the implementation: a `SingleWindowController` subclass with a `WindowSpec` (default size, minimum size, `persistsFrame`), the style mask above, a unified `NSToolbar` built by `WindowToolbarBuilder` and kept in a lazy property because `NSToolbar.delegate` is weak, `placeWindowWithoutSavedFrame(_:)` overridden to size and `cascadeTopLeft(from:)` off the template, and a private `BlankProjectContentViewController` holding a `ThemedLabel`. The `ProjectShelfWindow` protocol is declared here and `ComposableTabsWindowController` also conforms to it. UIKit has no window controller; an iPad scene with a `UISplitViewController` would be the nearest.
- **WinUI 3**: Start with a `Window` whose content is a `NavigationView` (`PaneDisplayMode="Left"` or `LeftCompact`, `IsPaneToggleButtonVisible="True"`) for the shelf and toggle, and a `Grid` with `Background` bound to a themed backdrop brush holding a centered `TextBlock` (`TextWrapping="Wrap"`, `HorizontalAlignment="Center"`, `Margin="20,0,0,0"`, `Foreground` bound to a tertiary text brush, `AutomationProperties.AutomationId="project.empty.message"`). For the seamless title bar, call `Window.ExtendsContentIntoTitleBar = true` and `SetTitleBar` with a drag region, or use `AppWindow.TitleBar.ExtendsContentIntoTitleBar` and `AppWindow.TitleBar.ButtonBackgroundColor` set to transparent so the backdrop runs behind the caption buttons. Set size with `AppWindow.Resize(new SizeInt32(800, 500))` and the minimum through `OverlappedPresenter` (there is no `MinWidth` on `Window`, so handle `AppWindow.Changed` or subclass the window proc for the 400 by 300 minimum), centering with `DisplayArea`, and persist the frame yourself in `ApplicationData.Current.LocalSettings` keyed by the group id. Cascade placement is not provided by the platform; offset the new window by a fixed step from the template's `AppWindow.Position`. Differs from the source: the toggle belongs to `NavigationView`, tooltips are set with `ToolTipService.ToolTip` and flipped on `PaneOpening` and `PaneClosing`, and caption buttons sit on the right rather than as traffic lights on the left.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/UI/ViewControllers/ComposableTabs/EmptyProjectWindowController.swift` | confirmed (1.0.0) |
| apple | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

- **Decision**: Make the empty window wear the same chrome as a project window: seamless title bar, shelf and toggle, and the pane backdrop color.
  **Rationale**: The doc comment states it is a project window in every way that shows, so choosing a project in its shelf swaps the project's window in without anything visibly moving.
  **Approved**: pending

- **Decision**: Read the placement template when the window loads, and size and cascade the window before it is shown.
  **Rationale**: The doc comment states a window shown at the default and then moved shrinks and regrows in front of the user.
  **Approved**: pending

- **Decision**: Send `cascadeTopLeft(from:)` to the new window twice, first with the template's top-left corner and then with the point the first call answers.
  **Rationale**: The source comment states the first call puts the window's top-left on the template's and answers the next cascade step, and the second moves it there; the call is sent to the window being placed because it is the one that moves, and it keeps the window on screen however many times New is chosen.
  **Approved**: pending

- **Decision**: Keep a strong reference to the toolbar delegate in a lazy property.
  **Rationale**: The source comment gives the reason: `NSToolbar.delegate` is weak.
  **Approved**: pending

- **Decision**: Land a shelf slide in flight before reading the shelf layout for a swap.
  **Rationale**: The protocol comment states that otherwise the layout handed over would carry a half-slid width and the slide would land later on a window already ordered out.
  **Approved**: pending

- **Decision**: Open the shelf on its browser panel with keyboard focus in the filter when choosing.
  **Rationale**: The doc comment states a new window has nothing in it but the question of which project to load.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | partial | Accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform Compliance |

`separation-of-concerns` passes because the controller composes the shared window, shelf, toolbar builder and split view controller and carries only the empty-window specifics. `unit-test-coverage` fails because no test in the test bundles references the controller. `keyboard-navigable` is partial because the shelf filter is focused on request, but the source does not show the toggle's keyboard path. `screen-reader-support` is partial because the message has an identifier but no accessibility label follows the toggle's state, as the open question on `Announce state changes` records. `no-hardcoded-strings` fails because the title, message and tooltips are literals. `platform-theming` passes because the backdrop color follows the theme palette through the palette observer.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
