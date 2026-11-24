---
id: deac5bd8-5e5f-43cf-bdfa-3a83b2298639
title: "Git Merge View"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-15
modified: 2026-11-15
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The git window's 3-way merge view: a conflicted file's ours and theirs side by side, aligned with filler rows and scroll-locked, over the result; Previous and Next step through the conflicts, Ours, Theirs, Both and Base choose each, and Save sends the resolved text to the delegate."
platforms:
  - swift
  - macos
tags:
  - git
  - ui
  - merge
  - conflicts
depends-on:
  - b28294a3-4eba-4c42-a7e9-d50821ed8f75
  - 5f9e0c63-382d-4803-bd50-a8fb90ea9e4d
  - 6708bfd4-5b29-4bf9-b180-05904873906e
related:
  - bdd3a72d-8810-439b-bad7-ec16233cb2a3
  - 6a830cf8-0b95-4ffd-b175-f5cf481490c4
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/GitMergeViewController.swift (adhsdk)
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/GitMergeLineModels.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Git Merge View
## Overview

The git window's 3-way merge view (`GitMergeViewController`): one conflicted file, parsed into a [conflict document](cookbook:b28294a3-4eba-4c42-a7e9-d50821ed8f75), shown as its two sides side by side over the result the choices made so far give. Ours (the checked-out side, `<<<<<<<`) and theirs (`>>>>>>>`) are two [line viewers](cookbook:5f9e0c63-382d-4803-bd50-a8fb90ea9e4d), row for row: the common text on both, each conflict's two sides padded with filler rows to the same height, and their scrolling locked together. The result pane sits below. A controls row steps through the conflicts and chooses each one: Ours, Theirs, Both (ours then theirs) or Base (when the conflict recorded one, a `diff3` or `zdiff3` merge). Save is enabled once every conflict has a choice and sends the resolved text to the delegate; the view writes nothing. Its rows are built by `GitMergeLayout`, a pure function of the document, the choices and the syntax colours, so they are tested without a window. The window's session opens it from the working copy's Conflicts list and writes and stages what it saves (recipe [git window](cookbook:6a830cf8-0b95-4ffd-b175-f5cf481490c4)).
## Behavioral Requirements

### Rows

- **merge-side-rows**: Ours and theirs MUST be aligned row for row: each common line is one plain row on both; each conflict is its ours lines on the ours side and its theirs lines on the theirs side, the shorter side padded with `filler` rows (no text, no gutter number) to the longer's height.
- **merge-gutter-numbers**: Each side's gutter MUST number its rows with that side's own line numbers (the common lines with that side's conflict lines), fillers unnumbered; the result is numbered 1 to its row count. The gutter is one column, at least three digits wide.
- **merge-backgrounds**: An unchosen conflict's rows MUST be `emphasis` on both sides. Once chosen, the chosen side's rows are `added` and the other's plain: Ours marks ours, Theirs marks theirs, Both (either order) marks both, Base marks neither. Fillers stay `filler` throughout.
- **merge-result-rows**: The result pane MUST be the common lines (plain) with each chosen conflict's lines in place, `added`: Ours its ours lines, Theirs its theirs lines, Both ours then theirs (or theirs then ours), Base its base lines. An unchosen conflict is one empty `emphasis` row. With every conflict chosen, the result has exactly one row per line of `GitConflictDocument.resolved(_:)`.
- **merge-starts**: The layout MUST record each conflict's first row on the sides (`sideStarts`) and in the result (`resultStarts`), by conflict index.
- **merge-syntax**: The three texts (ours, theirs and base, each the common lines with that side's conflict lines, joined by newlines) MUST be coloured by the file's language through `GitSyntaxColoring`, off the main thread; each row takes its own line's runs in its side's text, the result's rows those of the text they came from. Rows show uncoloured until the colours land, and a later `show` drops an earlier one's colours.

### Controls

- **merge-show**: `show(path:document:)` MUST show the document with no choices made and the first conflict current, label the sides with the first conflict's marker labels (`Ours` and `Theirs` when a label is empty) and scroll to the first conflict. The scroll MUST happen whether `show` runs before or after the view is loaded: one the panes cannot take yet (no view, or no height) stays pending until the view is next laid out.
- **merge-navigation**: `Previous` and `Next` MUST move `currentConflict` by one, never past the first or the last, and scroll ours (and theirs with it) to `sideStarts[current]` and the result to `resultStarts[current]`. Previous is enabled while there is an earlier conflict, Next while there is a later one. The position label reads `<n> of <total>` (1-based).
- **merge-choose**: `Ours`, `Theirs` and `Both` MUST set the current conflict's choice to `.ours`, `.theirs` and `.oursThenTheirs`, and redraw all three panes. `Base` MUST set `.base` and is enabled only when the current conflict recorded a base.
- **merge-save**: `Save` MUST be enabled exactly while `resolved(choices)` is non-nil, and send `.save(path:text:)` with that exact text. `Cancel` MUST send `.cancel`.
- **merge-intents-only**: The view MUST NOT write the file or run git; saving, staging and closing are the delegate's.
- **merge-ui-thread**: The view MUST be used on the UI thread.
## Appearance

A controls row (small push buttons: `Previous`, `Next`, the position label in the secondary caption style, `Ours`, `Theirs`, `Both`, `Base`, a flexible space, `Cancel`, `Save`) over a horizontal `ThemedSplitView`: on top a vertical `ThemedSplitView` of the ours and theirs panes at equal width, below the result pane. Each pane is a semibold secondary caption (the side's marker label, or `Result`) over a line viewer with one gutter column. Backgrounds are the line viewer's: `emphasis` for an unchosen conflict, `added` for chosen lines, `filler` for padding.
## States

- **Nothing shown**: before the first `show`, the panes are empty and every control is disabled.
- **Unresolved**: some conflicts have no choice; Save is disabled and their result rows are empty emphasis rows.
- **Resolved**: every conflict has a choice; Save is enabled.
- **Uncoloured**: rows show in the theme's foreground until the colouring lands, or for good when no language matches or colouring is off.
## Accessibility

The root view carries `git.merge`; the controls row `git.merge.controls`; its controls `git.merge.previous`, `git.merge.next`, `git.merge.position`, `git.merge.useOurs`, `git.merge.useTheirs`, `git.merge.useBoth`, `git.merge.useBase`, `git.merge.cancel` and `git.merge.save`. The split views carry `git.merge.split` and `git.merge.sides`; the panes `git.merge.oursPane`, `git.merge.theirsPane` and `git.merge.resultPane`, their labels `git.merge.oursLabel`, `git.merge.theirsLabel` and `git.merge.resultLabel`, and the line viewers `git.merge.ours`, `git.merge.theirs` and `git.merge.result`. Every control is a standard `NSButton`, so it answers an accessibility press.
## Conformance Test Vectors

The fixture is `top`, a conflict `HEAD` (`ours one`, `ours two`) against `side` (`theirs one`), `middle`, a conflict with a base (`x`, base `y`, `z`), `bottom`, ending with a newline.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-merge-view-001 | merge-side-rows, merge-gutter-numbers, merge-starts | the fixture, no choices | ours `top`, `ours one`, `ours two`, `middle`, `x`, `bottom`; theirs `top`, `theirs one`, a filler, `middle`, `z`, `bottom`; gutters 1-6 and 1, 2, none, 3, 4, 5; sideStarts `[1, 4]`; width 3 |
| git-merge-view-002 | merge-backgrounds, merge-result-rows | the fixture, no choices | conflict rows emphasis on both sides; result `top`, empty emphasis, `middle`, empty emphasis, `bottom`; resultStarts `[1, 3]` |
| git-merge-view-003 | merge-backgrounds, merge-result-rows | theirs, then ours | first conflict added on theirs only, second added on ours only; result `top`, `theirs one`, `middle`, `x`, `bottom`, numbered 1-5 |
| git-merge-view-004 | merge-backgrounds, merge-result-rows | Both, then Base | both sides added on the first; neither on the second; result `top`, `ours one`, `ours two`, `theirs one`, `middle`, `y`, `bottom` |
| git-merge-view-005 | merge-result-rows | four complete sets of choices | result row count equals the resolved text's line count, row texts its lines |
| git-merge-view-006 | merge-syntax | colours per side | each side's rows carry their side's runs; a filler none; result rows the runs of the text they came from |
| git-merge-view-007 | merge-navigation | a long file with two conflicts; Next, Next, Previous | current 1 (`2 of 2`), the sides scrolled to sideStarts[1] and the result to resultStarts[1]; Next stays; back to 0 and its rows |
| git-merge-view-008 | merge-choose | Ours, Theirs, Next, Both | choices `[0: .theirs, 1: .oursThenTheirs]`, rows redrawn |
| git-merge-view-009 | merge-choose | Base on the first conflict, then on the second | disabled and nothing set; then enabled and `[1: .base]` |
| git-merge-view-010 | merge-save | Ours only; Save; then Next, Base, Save | disabled, nothing sent; then `.save(path: "f.txt", text: "top\nours one\nours two\nmiddle\ny\nbottom\n")` |
| git-merge-view-011 | merge-show | choose and move, then `show` again | no choices, conflict 0, the new path |
| git-merge-view-012 | merge-syntax | a Swift conflict with the TextMate fixture | both sides' rows carry coloured runs once the colouring lands |
| git-merge-view-013 | merge-show | `show` the long fixture (first conflict at row 40) before the view is loaded, then load and lay it out at 900×600 | ours and theirs scrolled to `sideStarts[0] × rowHeight`, the result to `resultStarts[0] × rowHeight`; `1 of 2`; Previous disabled, Next enabled |
## Edge Cases

- **Null / empty input**: A document with no conflicts never reaches the view (`parse` returns nil); the session shows the diff instead.
- **Boundary values**: A conflict with one side empty (lines deleted on that side) is all filler on that side; choosing it removes the lines from the result.
- **Base missing**: A conflict without a recorded base has Base disabled; `resolved` would refuse `.base` there anyway.
- **No final newline**: The resolved text ends with a newline exactly when the conflicted file did.
- **Concurrent access**: UI thread only; colouring runs in a task and is dropped when a later `show` supersedes it.
- **Error states**: A colouring failure leaves the rows uncoloured.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `coloring` | `GitSyntaxColoring?` | none | Colours the three texts; nil shows them uncoloured. |
| `delegate` | `GitMergeViewDelegate?` | nil | Told `.save(path:text:)` and `.cancel`. |
## Deep Linking

Not applicable: the view defines no URL scheme, route or navigation destination.
## Localization

The control titles (`Previous`, `Next`, `Ours`, `Theirs`, `Both`, `Base`, `Cancel`, `Save`), the fallback side labels (`Ours`, `Theirs`), `Result` and the position text `<n> of <total>` are English literals today; file text and marker labels are shown verbatim.
## Accessibility Options

The line viewers' fonts and colours follow the theme; a chosen conflict is marked by its background on the side and in the result, and the position label states where the controls act.
## Feature Flags

Not applicable: the view contains no feature-flag reference.
## Analytics

Not applicable: the view contains no analytics call.
## Privacy

The view shows a local file's text only and sends nothing anywhere.
## Logging

The view logs nothing; `GitSyntaxColoring` logs a highlighter error by its type.
## Platform Notes

- **SwiftUI**: Two synchronized `ScrollView`s of lazy rows would serve; this toolkit's views are AppKit.
- **Compose**: Two `LazyColumn`s sharing one scroll offset.
- **React/Web**: Two virtualized lists with a shared scroll handler.
- **AppKit / UIKit**: AppKit: `@MainActor public final class GitMergeViewController: NSViewController` and `public struct GitMergeLayout` in `AgenticDeveloperHubSDKMacOS`, over three `LineViewerViewController`s with a `LineViewerScrollSync` on the two sides; `GitConflictDocument` in `AgenticDeveloperHubSDKCore`.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/GitMergeLineModels.swift` | confirmed (1.0.0) |
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/GitMergeViewController.swift` | confirmed (1.0.0) |

## Design Decisions

**Decision**: The rows are a pure function, `GitMergeLayout.make(document:choices:colours:)`, rebuilt on every choice.
**Rationale**: The alignment, backgrounds and numbering are the whole of the view's logic; as a function of its inputs they are tested without a window, and a conflicted file is small enough that rebuilding is free.
**Approved**: pending

**Decision**: Only ours and theirs are scroll-locked; the result scrolls on its own and is moved by Previous and Next.
**Rationale**: The result's rows are not aligned with the sides (an unchosen conflict is one row, a chosen one the chosen lines), so locking offsets would point the panes at different text.
**Approved**: pending

**Decision**: The view sends the resolved text to its delegate instead of writing it.
**Rationale**: The resolved text is the one file the window writes itself; keeping the write in the model (`writeResolution`, atomic, off the main thread) leaves the view a pure editor of choices and the window's one funnel in charge of side effects.
**Approved**: pending

**Decision**: A Cancel button sends `.cancel`.
**Rationale**: The intent needs a control; without one the only way back to the diff would be selecting another file.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because the view edits choices and reports intents; the file write and the staging are the session's and the model's. `unit-test-coverage` passes: `GitMergeLineModelsTests` covers alignment, fillers, gutters, backgrounds before and after each choice, the result against `resolved` and the colours; `GitMergeViewControllerTests` covers identifiers, navigation and scrolling, the side and base buttons, Save and Cancel, a second show and colouring.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-15 | Mike Fullerton | show scrolls to the first conflict whether it runs before or after the view loads (git-merge-view-013) |
| 1.0.0 | 2026-11-15 | Mike Fullerton | Initial creation: ours and theirs aligned with fillers and scroll-locked over the result; Previous, Next, Ours, Theirs, Both, Base, Cancel and Save; vectors 001-012 |
