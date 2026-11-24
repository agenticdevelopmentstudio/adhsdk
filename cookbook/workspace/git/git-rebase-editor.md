---
id: 241d5e8b-3395-4093-ad77-1e138b7fe3a1
title: "Git Rebase Editor"
type: ingredient
version: 1.0.3
status: review
language: en
created: 2026-11-16
modified: 2026-11-16
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The git window's interactive rebase editor: a rebase plan's entries, oldest at the top, each with an action pop-up, its short sha and its subject (an editable message for a reword), dragged to reorder; Start Rebase is enabled only while the plan is valid, the reason it is not as its tooltip, and the edited plan or nil goes to the caller."
platforms:
  - swift
  - macos
tags:
  - git
  - ui
  - rebase
depends-on:
  - 779ac6ea-9ef5-4fb0-8ed9-dc6b9d617344
related:
  - bdd3a72d-8810-439b-bad7-ec16233cb2a3
  - 6a830cf8-0b95-4ffd-b175-f5cf481490c4
references:
  - packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/GitRebaseEditorViewController.swift (adhsdk)
approved-by: ""
approved-date: ""
---

# Git Rebase Editor
## Overview

The git window's interactive rebase editor (`GitRebaseEditorViewController`): one [rebase plan](cookbook:779ac6ea-9ef5-4fb0-8ed9-dc6b9d617344) (`GitRebasePlan`) as a table, one row per entry, oldest at the top as git lists them. Each row is an action pop-up (pick, reword, edit, squash, fixup, drop), the commit's short sha and its subject; a reword's subject is an editable field holding its new message. Rows are dragged to reorder. Start Rebase is enabled only while the plan's `validationError` is nil, and that reason is its tooltip. The editor runs nothing: it hands the edited plan, or nil for Cancel, to `onFinish`. The window shows it as a sheet through its presenter and runs what it returns (recipe [git window](cookbook:6a830cf8-0b95-4ffd-b175-f5cf481490c4)).
## Behavioral Requirements

### Rows

- **rebase-rows**: The table MUST show one row per plan entry in the plan's order, oldest at the top, in three columns: `action`, a pop-up of the six actions by name (`pick`, `reword`, `edit`, `squash`, `fixup`, `drop`) with the entry's selected; `sha`, the commit's first 8 characters; `subject`, the entry's subject.
- **rebase-reword-field**: For a `reword` entry the subject cell MUST be an editable text field holding the entry's message (its whole message, body included), and every keystroke and the end of editing MUST set that message in `plan`. The field MUST wrap and show every line of the message, and the row MUST be as tall as the message's lines, and as the text measured at the field's width (the frame the table lays the subject cell out in, `frameOfCell`) when a line wraps, growing and shrinking as lines are added or removed and as the column is resized. Return and Enter in the field MUST insert a newline into the message and never end the edit, so they never reach `Start Rebase`. Every other action shows the subject as a label; the message is not shown for them.
- **rebase-action-change**: Choosing an action in a row's pop-up MUST set that entry's action in `plan` and redraw the row. Switching to `reword` an entry with no message MUST fill the message with its subject, so the field never starts empty.
- **rebase-reorder**: Rows MUST be draggable to a new place, drop-above as the table names it: the entry moves to sit above the row it was dropped on (after the last for the end), and the moved row is selected. A drop onto its own place moves nothing. The drag MUST carry the row's index on a pasteboard type local to the table (`com.agenticdeveloperhub.git.rebase.row`), and the table MUST accept only drags it started.
- **rebase-move-buttons**: `Move Up` (`git.rebase.moveUp`, ⌥⌘↑) and `Move Down` (`git.rebase.moveDown`, ⌥⌘↓) MUST move the selected row one place up or down, as a drop would, keeping it selected; a reword field being edited MUST stay in its edit, with its selection, after the move. A move made before the view loads MUST reorder `plan` without loading the view. Each MUST be disabled while there is no selection or the selected row is already at that end, so reordering never needs a drag.

### Buttons

- **rebase-start-enablement**: `Start Rebase` MUST be enabled exactly while `plan.validationError` is nil, re-checked after every change, and carry that reason as its tooltip while it is not (no tooltip otherwise). The reason is never shown as inline text.
- **rebase-finish**: `Start Rebase` MUST end any field editing and call `onFinish` with `plan`; `Cancel` MUST call `onFinish` with nil. Either clears `onFinish` first, so it is called at most once. Return is Start's key equivalent and Escape Cancel's, except inside a reword's field, which takes Return as a newline (**rebase-reword-field**).
- **rebase-runs-nothing**: The editor MUST NOT run git; running the plan is the caller's.
- **rebase-ui-thread**: The editor MUST be used on the UI thread.
## Appearance

A themed table with a header (`Action`, `SHA`, `Subject`; 110, 80 and 420 points wide), rows 26 points high, the action pop-up in the small control size, the sha in the secondary code style and the subject in the primary body style. Under it, right-aligned, two push buttons, `Cancel` then `Start Rebase`. The preferred size is 680 × 380, at least 660 × 320, with 16-point margins.
## States

- **Valid**: the plan can run; Start Rebase is enabled with no tooltip.
- **Invalid**: every entry dropped, the first kept entry a squash or fixup, or a reword with an empty message; Start Rebase is disabled with the reason as its tooltip.
- **Finished**: after Start Rebase or Cancel, `onFinish` is gone and the buttons do nothing more.
## Accessibility

The root view carries `git.rebase`, the scroll view `git.rebase.scroll`, the table `git.rebase.table`, each action pop-up `git.rebase.action`, each sha `git.rebase.sha`, each subject `git.rebase.subject`, each reword field `git.rebase.message` (accessibility label `Message`), the button row `git.rebase.buttons` and the buttons `git.rebase.cancel` and `git.rebase.start`. The pop-ups and buttons are standard controls, so they answer accessibility presses.
## Conformance Test Vectors

The fixture is a plan of three entries `commit 0`, `commit 1`, `commit 2`, all pick, each with the message `commit <n>`, a blank line, `body <n>`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| git-rebase-editor-001 | rebase-rows | the fixture | three rows in order; columns `action`, `sha`, `subject`; each pop-up `pick` of the six names; shas the first 8 characters; subjects `commit 0` to `commit 2`, labels |
| git-rebase-editor-002 | rebase-action-change | choose `drop` in row 1's pop-up | actions `pick`, `drop`, `pick` |
| git-rebase-editor-003 | rebase-reword-field | reword row 0; type `renamed` | an editable field `git.rebase.message` holding `commit 0\n\nbody 0`; then the message `renamed` |
| git-rebase-editor-004 | rebase-action-change | row 2 with no message; reword it | its message `commit 2`; Start enabled |
| git-rebase-editor-005 | rebase-reorder | move 0 to 3; 2 to 0; 1 to 1 and 1 to 2; 2 to 1 | `1, 2, 0`; back to `0, 1, 2`; unchanged; `0, 2, 1` with row 1 selected |
| git-rebase-editor-006 | rebase-reorder | row 2's pasteboard writer | the local type carries `2`, read back as 2 |
| git-rebase-editor-007 | rebase-start-enablement | squash row 0; then pick it | disabled with the validation reason as tooltip; enabled, no tooltip |
| git-rebase-editor-008 | rebase-start-enablement | reword row 1; message `   `; then `fine` | enabled; disabled with the reason; enabled |
| git-rebase-editor-009 | rebase-finish | Cancel, twice | `onFinish(nil)` once |
| git-rebase-editor-010 | rebase-finish | fixup row 0 and Start; then pick row 0, drop row 2, move 1 to 0, Start | nothing; then `onFinish` once with the plan, actions `pick`, `pick`, `drop` |
| git-rebase-editor-011 | rebase-reword-field, rebase-finish | reword row 0; `insertNewline:` then `insertLineBreak:` in its field at the end of `subject` | both handled; the text is `subject\n\n`; `onFinish` not called; `cancelOperation:` not handled. |
| git-rebase-editor-012 | rebase-reword-field | reword row 0 (`commit 0\n\nbody 0`); then five lines; then `one` | taller than a plain row; taller still; a plain row again. |
| git-rebase-editor-013 | rebase-move-buttons | nothing selected; select row 0; Move Down twice; Move Up twice | both disabled; Up disabled; order 1 0 2 then 1 2 0 with Down disabled; order 0 1 2, row 0 selected, Up disabled. |
| git-rebase-editor-014 | rebase-reword-field | reword row 0 with one line long enough to wrap; then double the subject column's width | `subjectWidth` equals the cell frame's width; taller than a plain row and at least the field's cell height at that width; shorter after the resize. |
| git-rebase-editor-015 | rebase-move-buttons, rebase-reword-field | reword row 0 editing with the caret at 3; ⌥⌘↓ | the row moved to 1; its field still editing with the caret at 3 and the text `commit 0\n\nbody 0`. |
| git-rebase-editor-016 | rebase-move-buttons | an editor whose view is not loaded; `moveEntry(from: 0, to: 3)` | order 1 2 0; the view still not loaded. |
## Edge Cases

- **Null / empty input**: an empty plan shows no rows and Start disabled (`validationError` reports it); the window never builds one, since the plan verb refuses an empty range.
- **Boundary values**: one entry can only be picked, reworded, edited or dropped usefully; a lone squash or fixup disables Start.
- **A reword switched away and back**: the message typed is kept on the entry, since only the action changed.
- **Field still being edited at Start**: every keystroke has already reached `plan`, so ending editing adds nothing and loses nothing.
- **A drag from elsewhere**: refused; only the table's own rows move.
- **Concurrent access**: UI thread only.
## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `plan` | `GitRebasePlan` | none | The plan to edit, from `init(plan:)`; read back as edited. |
| `onFinish` | `((GitRebasePlan?) -> Void)?` | nil | Called once with the plan for Start Rebase, or nil for Cancel. |
## Deep Linking

Not applicable: the editor defines no URL scheme, route or navigation destination.
## Localization

The column titles (`Action`, `SHA`, `Subject`), the button titles (`Cancel`, `Start Rebase`) and the field's accessibility label `Message` are English literals today; the action names are git's own todo verbs and are shown as git spells them; subjects and messages are shown verbatim. The validation reasons come from `GitRebasePlan`.
## Accessibility Options

The table, pop-ups and fields follow the theme's fonts and colours; every control is a standard one, so keyboard navigation and VoiceOver work as for any table.
## Feature Flags

Not applicable: the editor contains no feature-flag reference.
## Analytics

Not applicable: the editor contains no analytics call.
## Privacy

The editor shows local commit subjects and messages only and sends nothing anywhere.
## Logging

The editor logs nothing.
## Platform Notes

- **SwiftUI**: a `List` with `.onMove` and a `Picker` per row would serve; this toolkit's views are AppKit.
- **Compose**: a reorderable `LazyColumn` with a dropdown per row.
- **React/Web**: a sortable list with a `<select>` per row.
- **AppKit / UIKit**: AppKit: `@MainActor public final class GitRebaseEditorViewController: NSViewController` in `AgenticDeveloperHubSDKMacOS`, over a `ThemedTableView` with a local pasteboard type; `GitRebasePlan` and `GitRebaseEntry` in `AgenticDeveloperHubSDKCore`. The window's `GitAlertPresenter.editRebase(_:)` shows it as a sheet.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Views/GitRebaseEditorViewController.swift` | confirmed (1.0.3) |
| apple | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Git/Window/GitActionPresenting.swift` | confirmed (1.0.3) |

## Design Decisions

**Decision**: The editor edits a `GitRebasePlan` value and hands it back; it never runs git.
**Rationale**: The plan's validation and the todo it becomes are the client's, tested without a window; the editor stays a pure editor and the window's one funnel runs the result.
**Approved**: pending

**Decision**: Every reword's message is filled before the editor opens, from one `log` call for the whole range.
**Rationale**: A reword starts from the commit's real message, body included, and switching an action costs no git call on the main thread.
**Approved**: pending

**Decision**: A reword's message is edited in the subject cell itself, not in a separate pane.
**Rationale**: The row is where the user decided to reword; a field in place keeps the table the whole editor, and the message is shown only where it will be used.
**Approved**: pending

**Decision**: Start's reason for being disabled is its tooltip, not text under the table.
**Rationale**: The window shows no instruction text; the tooltip is there when the user asks why.
**Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`separation-of-concerns` passes because the editor edits a value and reports it; validation is the plan's and running it is the session's. `unit-test-coverage` passes: `GitRebaseEditorViewControllerTests` covers the rows, identifiers, the pop-up, the reword field, reordering and its pasteboard, Start's enablement and tooltip, Start and Cancel; `GitAlertPresenterTests` covers the sheet.
## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.3 | 2026-11-16 | Mike Fullerton | A reword row is measured at the field's width; a move before the view loads leaves it unloaded (vectors 014, 016) |
| 1.0.2 | 2026-11-16 | Mike Fullerton | A wrapped reword row is as tall as its text measured at the column's width; a move keeps the reword field's edit (vectors 014-015) |
| 1.0.1 | 2026-11-16 | Mike Fullerton | Final review: word-emphasis budget, selection kept across reloads, non-ancestor rebase rows; reword field newlines, row heights, Move Up/Down; selectRows; merge view cap |
| 1.0.0 | 2026-11-16 | Mike Fullerton | Initial creation: action pop-ups, drag to reorder, a reword's message in place, Start enabled only for a valid plan with the reason as tooltip, Cancel; vectors 001-010 |
