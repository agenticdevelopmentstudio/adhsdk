---
id: e1859aa2-d0c4-4d9a-b926-203dd5fbbca3
title: "AddUsersModal"
domain: adhsdk://recipes/add-users-modal
type: recipe
version: 1.1.1
status: review
language: en
created: 2026-06-26
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A controlled dialog that stages users in a growing DataTable via an inline entry row, then hands the collected rows to an onAdd callback."
platforms:
  - typescript
  - web
tags:
  - modal
  - dialog
  - table
  - users
ingredients:
  - adhsdk://recipes/data-table
  - adhsdk://recipes/alert-and-dialog
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# AddUsersModal

## Overview

A modal in `@adh-sdk/ui` for building a list of users to add. It composes
`Dialog` + `DataTable` + `Input` + `UnsavedChangesAlert` + `Button`. Each "Add" appends
the entry row to a table above; the dialog's final "Add" hands the rows to a
caller callback (`onAdd`).

It is a controlled dialog: a growing `DataTable` of staged users on top, an
inline entry row (name / email / phone / admin note) below it with an **Add**
button, and a footer (Cancel / Add).

## Ingredients

| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| DataTable | adhsdk://recipes/data-table | Growing table of staged `DraftUser` rows | yes | columns Name · Email · Phone · Admin note; selection; empty label |
| AlertAndDialog | adhsdk://recipes/alert-and-dialog | The modal `Dialog` shell (`DialogContent max-w-2xl`) + the discard-confirm `UnsavedChangesAlert` | yes | modal semantics; discard-confirm copy |

Composed shared primitives without their own recipe domains: `Input` and `Field`
(the entry row inputs) and `Button` (entry Add + footer Cancel/Add).

## Integration Requirements

- **add-row-on-enter-or-button**: The AddUsersModal MUST append a `DraftUser`
  to the staged `DataTable`, clear the entry fields, and refocus the Name input
  when Enter is pressed in any entry field or the entry **Add** button is
  activated.
- **ignore-blank-entry**: The AddUsersModal MUST treat an entry with no name,
  email, or phone as fully blank and MUST NOT append a row, even if an admin
  note is present. A note-only entry is a no-op for row-adding purposes, but
  the note field is NOT cleared (only a successful add, or a close that
  resets state, clears the entry fields); a note-only entry still counts as
  dirty for **confirm-cancel-when-dirty** below.
- **tab-order**: The entry row MUST follow DOM order Name → Email → Phone →
  Note → **Add**. The `flex-1` element between Note and Add is layout spacing
  only; it has no effect on tab order.
- **disable-footer-add-when-empty**: The footer **Add** button MUST be
  `disabled` while the staged `DataTable` contains no rows.
- **disable-footer-add-when-busy**: The footer **Add** button MUST be
  `disabled` when `busy` is true.
- **call-onadd-and-close**: Activating the footer **Add** MUST call
  `onAdd(stagedRows)`, then reset internal state (staged rows, selection, and
  entry fields), and call `onClose()` — immediately, regardless of `busy`. The
  modal does not wait for `busy` to clear before calling `onClose()`; the
  caller's `open` prop still governs whether the dialog remains mounted.
- **confirm-cancel-when-dirty**: Cancel or Esc MUST open a discard-confirm
  `UnsavedChangesAlert` when the staged table has rows OR the entry row has
  content (name, email, phone, or note is non-blank); otherwise it MUST close
  immediately. A backdrop click is inert: the shared `Dialog` sets
  `disablePointerDismissal`, so a backdrop click neither closes the dialog nor
  opens the confirm, regardless of dirty state. `busy` does not disable Cancel
  or Esc. State resets on close.

## Layout

```
┌ Add users ─────────────────────────────────────────────────────┐
│  DataTable: Name · Email · Phone · Admin note                   │  staged rows
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Ada     │ ada@x.io   │ +1 555 0100 │ priority             │  │
│  └──────────────────────────────────────────────────────────┘  │
│  [ name ][ email ][ phone ][ admin note ]        ……    [ Add ]  │  entry row
│                                                                 │
│                                       [ Cancel ]   [ Add ]      │  footer
└─────────────────────────────────────────────────────────────────┘
```

- `DialogContent` (`max-w-2xl` — the table needs width); the staged `DataTable`
  above; the entry row a `flex items-end gap-2` of `Field`-wrapped `Input`s + a
  `flex-1` spacer + the Add `Button`. Footer right-justified `[ Cancel ][ Add ]`.
- The staged table supports `DataTable` selection (`selectedIds` /
  `onSelectionChange`); at minimum the table shows what is queued.
- No raw hex; no `!important`.

## Shared State

| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| stagedRows (`DraftUser[]`) | AddUsersModal | DataTable, footer Add (enabled state), `onAdd` | Down / Up | Component state + prop; `onAdd` callback |
| entryFields {name, email, phone, note} | AddUsersModal | Entry `Input`s | Down / Up | Component state + input `onChange` |
| discardConfirm open | AddUsersModal | AlertAndDialog (UnsavedChangesAlert) | Down | Boolean state |
| busy | Caller | Footer Add | Down | Prop |
| open | Caller | Dialog | Down | Prop (`open`); `onClose` callback up |

## Integration Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | add-row-on-enter-or-button | Type a name, press Enter in a field | Row appended to staged table; entry cleared; Name refocused |
| T2 | add-row-on-enter-or-button | Activate the entry **Add** button (click, not Enter) with a valid entry | Row appended to staged table; entry cleared; Name refocused |
| T3 | ignore-blank-entry | Empty entry, press Enter / activate Add | No row added (no-op) |
| T4 | ignore-blank-entry | Entry has only an admin note (name/email/phone blank), press Enter / activate Add | No row added (no-op); note remains in the field, not cleared |
| T5 | disable-footer-add-when-empty | 0 staged rows | Footer Add disabled |
| T6 | disable-footer-add-when-empty | ≥1 staged row | Footer Add enabled |
| T7 | disable-footer-add-when-busy | `busy=true` | Footer Add disabled |
| T8 | call-onadd-and-close | Footer Add with staged rows | `onAdd(stagedRows)` called; internal state resets; `onClose()` called immediately |
| T9 | confirm-cancel-when-dirty | Cancel with staged rows or entry content | Discard-confirm `UnsavedChangesAlert` opens |
| T10 | confirm-cancel-when-dirty | Esc with staged rows or entry content | Discard-confirm `UnsavedChangesAlert` opens |
| T11 | confirm-cancel-when-dirty | Backdrop click with staged rows or entry content | No-op: backdrop click is inert (shared `Dialog`'s `disablePointerDismissal`); dialog stays open, no confirm opens |
| T12 | confirm-cancel-when-dirty | Cancel with empty table and empty entry | Closes immediately, no confirm |
| T13 | confirm-cancel-when-dirty | `busy=true`, Cancel activated with a dirty state | Discard-confirm `UnsavedChangesAlert` opens; `busy` does not disable Cancel |
| T14 | tab-order | Tab from Note | Focus lands on the Add button |
| T15 | confirm-cancel-when-dirty | Add rows, discard via `UnsavedChangesAlert`, then reopen (`open=true` again) | Staged table and entry fields are empty (state was reset on close) |

## Edge Cases

- A fully blank entry (no name, email, or phone) is a no-op for row-adding,
  even with an admin note present; the note field is NOT cleared, and a
  note-only entry still counts as dirty for confirm-cancel-when-dirty.
- Footer Add is disabled at 0 staged rows; an empty staged table shows the
  `DataTable` empty label.
- `busy` disables the footer Add button to prevent multiple submissions;
  Cancel/Esc remain enabled while busy, and still follow the dirty-confirm
  rule.
- Cancel / Esc with a dirty state (rows or entry content, including a
  note-only entry) opens the discard confirm; with a clean state it closes
  immediately. A backdrop click never closes the dialog or opens the confirm
  — it is inert regardless of dirty state, because the shared `Dialog` sets
  `disablePointerDismissal`.
- State resets on close (staged rows, selection, and entry fields), so
  reopening starts with an empty entry row and table.

## Platform Notes

- **SwiftUI**: Start from a modal presentation using `.sheet()` or an overlay container. Compose with a List or LazyVStack for staged rows, TextFields for input, and Buttons for actions. Differs: SwiftUI state binding and @State management patterns; TextField validation and keyboard handling; native modal dismissal semantics with `.interactiveDismissDisabled()` when dirty.
- **Compose**: Start from a Dialog composable with a LazyColumn for the user list, TextField composables for input fields, and Row/Column for layout. Differs: Compose's state hoisting pattern; Material Design 3 theming and elevation; TextField focus and keyboard handling via Compose's Focus API; back-button handling via `BackHandler`.
- **React/Web**: Implementation at `packages/web/packages/ui/src/blocks/add-users-modal.tsx`. Composes Dialog*, DataTable, Input, Field, Button, and UnsavedChangesAlert components. Uses Tailwind for layout and spacing; focus management via useRef and requestAnimationFrame for post-render refocus on entry Name field.
- **AppKit / UIKit**: On iOS, use a sheet presentation controller with UITableViewController for staged rows and UITextFields for input. On macOS, use a sheet or window-modal presentation with `NSTableView` for staged rows and `NSTextField` for input. Differs: UIControl delegate patterns for input handling; platform keyboard lifecycle management; safe area insets and view controller transitions; UITableView cell reuse patterns on iOS vs. `NSTableViewDataSource` on macOS.
- **WinUI 3**: Use `ContentDialog` with a `ListView` for staged rows (the Community Toolkit's `DataGrid` control is not built into WinUI 3) and `TextBox` controls for input fields. Layout with `StackPanel`; use `Button` controls with `Command` bindings. Differs: XAML markup for UI definition; `ItemsSource` binding for the list; `TextBox` `TextChanged` events vs. React `onChange`; `ContentDialog` command patterns.

## Design Decisions

- **Decision**: A row needs at least a name, email, or phone to be added; an
  admin note alone does not cause a row to be appended, so a note-only entry
  is a no-op for row-adding — but the note is not cleared, and it does count
  as dirty for `confirm-cancel-when-dirty`.
  **Rationale**: Avoids staging rows with no usable identity or contact
  information, while still treating a typed note as work the user could lose.
  **Approved**: pending
- **Decision**: Enter-to-add refocuses Name.
  **Rationale**: Enables fast repeated keyboard entry.
  **Approved**: pending
- **Decision**: Explicit DOM tab order ends on Add after Note; the flexible
  spacer between them is layout only and does not itself produce the order.
  **Rationale**: Predictable keyboard flow to the primary entry action.
  **Approved**: pending
- **Decision**: Cancel confirms only when dirty.
  **Rationale**: Avoids nagging the user when there is nothing to lose.
  **Approved**: pending
- **Decision**: `busy` disables the footer Add button only; does not block
  Esc or Cancel. A backdrop click is always inert, independent of `busy`,
  because the shared `Dialog` sets `disablePointerDismissal` (dismissal only
  via an explicit button, per the family's dialog-dismissal policy).
  **Rationale**: Prevents accidental duplicate submissions while allowing
  users to abandon unsaved work via Esc/Cancel if needed.
  **Approved**: pending
- **Decision**: The AddUsersModal validates only presence (name/email/phone
  non-blank), not email or phone format; format validation is the caller's
  responsibility, before or after `onAdd` is invoked.
  **Rationale**: The component stages contact rows for the caller to submit;
  format rules typically depend on the caller's backend and are out of scope
  for the staging UI.
  **Approved**: pending
- **Decision**: Each staged row carries an internally generated id
  (`` `${Date.now()}-${index}` ``) used only for `DataTable` selection
  identity; the id is stripped before rows are passed to `onAdd`, so the
  public `DraftUser` shape has no id field.
  **Rationale**: Two staged rows can have identical name/email/phone/note
  values, so a stable per-row key is needed for selection even though the
  caller-facing type doesn't need one.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | Accessibility |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy and Data |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | partial | Internationalization |
| [platform-theming](agenticdevelopercookbook://compliance/platform-compliance#platform-theming) | passed | Platform Compliance |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Passed statuses rest on the source's explicit `aria-label`s on every input and
button, `Dialog` focus-trap/restore plus the explicit Enter-key and tab-order
handling, the minimal name/email/phone/note field set, and the `text-apt-gold`
theme token (no raw hex). Partial statuses reflect that ARIA roles are
delegated to the `Dialog`/`Field` primitives (not shown in this file), that
React's default output escaping runs without any explicit email/phone format
validation, and that button/column-header/empty-label strings are hardcoded
except for the overridable `title` prop. Best-practices statuses reflect that
`addRow`/`requestCancel`/`commit` embed the draft-row state machine directly
in the component rather than a separated hook (separation-of-concerns:
partial), and that `addUsersModal.test.tsx` exercises entry, cancel-discard,
and the nested-dialog contract with real assertions (unit-test-coverage:
passed).

## API

`@adh-sdk/ui/blocks/add-users-modal`:

```ts
interface DraftUser { name: string; email: string; phone: string; note: string }
interface AddUsersModalProps {
  open: boolean
  onAdd: (users: DraftUser[]) => void
  onClose: () => void
  busy?: boolean
  title?: string        // default "Add users"
}
export function AddUsersModal(props: AddUsersModalProps): React.ReactElement
```

## Accessibility

`Dialog` modal semantics with focus trap and restore; entry inputs are
labeled via `Field`. Tab order follows DOM order: Name → Email → Phone →
Note → Add button; the `flex-1` element between Note and Add is layout
spacing only and has no effect on tab order (see **tab-order**). Esc closes
the dialog (subject to the discard-confirm rule) but is not itself a tab
stop. Enter-to-add keeps focus flowing back to Name for fast repeated entry.
The empty staged table displays the `DataTable` empty label.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.1.1 | 2026-09-25 | Mike Fullerton | Backdrop is inert per disablePointerDismissal (not a confirm trigger); note-only entry counts as dirty but isn't discarded; moved API/Accessibility after Compliance for template order. Added best-practices compliance rows (separation-of-concerns: partial, unit-test-coverage: passed). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case everywhere they're cited; state that footer Add calls `onAdd` then `onClose()` immediately regardless of `busy`; define the blank-entry rule inline and cover note-only entries; add a design decision scoping format validation to the caller; align all `AlertModal` mentions to the source's `UnsavedChangesAlert`; fix tab-order wording and drop the unverified row-removal claim; document the internal staged-row id; add test vectors for Esc/backdrop, state reset on reopen, the entry Add button, and Cancel while busy; reword the busy/dismiss edge case; correct SwiftUI/Compose/WinUI 3/AppKit Platform Notes APIs; approve all Design Decisions with pending status; rebuild Compliance with real catalog checks; fix 1.0.1 row author. |
| 1.0.1 | 2026-09-22 | Mike Fullerton | Restructure Platform Notes with all five platform guidance bullets; correct `busy` behavior to match source; update domain URIs from agenticdeveloperhub to agenticdevelopercookbook; refine requirements for source fidelity. |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial conversion from legacy UI spec. |
