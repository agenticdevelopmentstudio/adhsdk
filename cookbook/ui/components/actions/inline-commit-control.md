---
id: 26df832c-a7f7-4cf6-b3f5-240c61e8bd68
title: "InlineCommitControl"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-07-07
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Trailing-aligned inline ✓/✕ commit pair for in-place row editing, with a hover-revealed trash that arms a strikethrough pending delete."
platforms:
  - typescript
  - web
tags:
  - editing
  - inline-edit
  - commit
  - delete
  - table
depends-on: []
related:
  - d04eef56-2dbf-4148-964b-c095f242227f
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
  - e26e765d-2caa-40f8-a668-661ed2b0632c
  - 81db83fc-b30c-4ba3-b4d5-572dc8b4e335
references: []
approved-by: ""
approved-date: ""
---

# InlineCommitControl

## Overview

The inline commit control lives trailing-aligned inside (or adjacent to) an
editable element — canonically the last cell of a DataTable row. While the
element's data is clean it stays out of the way (at most a hover-revealed
trash affordance); the moment the data goes dirty it shows a ✓ (commit) / ✕
(cancel) icon-button pair that persists until the edits are saved or
discarded. It also owns the inline delete grammar: the trash arms a *pending*
delete — the consumer dims and strikes the content — and the same ✓ then
commits the removal.

Five cooperating exports form the pattern, all from
`@adh-sdk/ui/components/inline-commit-control` (plus the sibling
`unsaved-changes-guard`):

- `InlineCommitControl` — the stateless control itself.
- `InlineEditableText` — click-to-edit text (the shared `Input` with its field
  shell suppressed until hover/focus) whose edits make the row dirty. A
  `variant` (`mono` / `muted`) applies the two typography treatments consumers
  were overriding by hand (keys/identifiers vs. secondary text).
- `inlineCommitDeletingClass` — the class the consumer applies to content
  while its delete is armed (dim + strikethrough).
- `UnsavedChangesGuard` — page-level guard: while anything is dirty,
  navigation raises a confirm dialog (in-app links via the platform
  AlertModal, hard navigation via `beforeunload`, Back/Forward via a
  history sentinel, and opted-in programmatic navigation via the
  navigation-guard registry).
- `useInlineDrafts` (`@adh-sdk/ui/hooks/useInlineDrafts`) — the
  optional per-row state machine consumers were copy-pasting: PATCH-based
  drafts (only touched fields, so a commit never clobbers a field a
  background refetch changed), per-row in-flight gating, per-row errors, and
  `settle` (keeps keystrokes typed while a commit was in flight).

The consumer owns the data — draft values, dirty computation, the armed
delete — mirroring ButtonBar's contract; the control just renders it. The
`useInlineDrafts` hook is the shared implementation of that state, not a
requirement (any data layer plugs in).

## Behavioral Requirements

- **hide-when-clean**: The control MUST render nothing while the data is
  clean, except the delete affordance when the data is deletable.
- **reveal-trash-on-hover**: When clean and deletable, the control MUST
  reveal a trash icon button on hover of its enclosing hover scope
  (`inlineCommitHoverScopeClass`; DataTable rows provide it) and on keyboard
  focus.
- **show-pair-when-dirty**: The control MUST show the ✓/✕ pair whenever
  the data is dirty, and keep showing it until the edits are committed or
  cancelled.
- **commit-on-ok**: Clicking ✓ MUST invoke the consumer's commit action
  (save to the backing store); the consumer hides the control by clearing the
  dirty state on success.
- **cancel-on-x**: Clicking ✕ MUST invoke the consumer's cancel action,
  reverting the draft to the committed data.
- **arm-delete**: Clicking the idle trash MUST arm a pending delete
  rather than deleting immediately.
- **render-armed-delete**: While a delete is armed the control MUST show
  ✓ ✕ followed by a red trash as the right-most button, and the consumer MUST
  dim and strike the affected content (`inlineCommitDeletingClass`).
- **commit-armed-delete**: Clicking ✓ while a delete is armed MUST invoke
  the consumer's commit action, which performs the delete.
- **disarm-delete**: Clicking ✕ (or the armed red trash) while a delete
  is armed MUST disarm it, restoring the content's normal rendering without
  deleting.
- **disable-while-busy**: While a commit is in flight the control MUST
  neutralize its buttons (ignore clicks) and indicate progress in place of the
  ✓. It MUST use `aria-disabled` rather than the `disabled` attribute, so the
  button keeps keyboard focus across the in-flight transition.
- **edit-in-place**: Editable text using `InlineEditableText` MUST become
  editable with a single click in place, and edits MUST make the row dirty.
- **guard-navigation-when-dirty**: While any attached data is dirty, the
  page MUST prevent navigation without a confirmation dialog
  (`UnsavedChangesGuard`): in-app link clicks raise the platform AlertModal
  confirm; reload/close raises the browser's native leave prompt; Back/Forward
  raises the AlertModal (via a same-URL history sentinel); and chrome that
  navigates programmatically (menus, choosers, logout) raises it too when it
  awaits `confirmNavigation()` from the navigation-guard registry.
- **route-keyboard**: `InlineEditableText` SHOULD route Enter to the
  row's commit action and Escape to its cancel action; a consumer-supplied
  `onKeyDown` runs FIRST and may `preventDefault()` to suppress that routing.
- **preserve-focus**: The control SHOULD keep keyboard focus coherent
  across state changes — arming a delete focuses the ✓ (confirming is one
  keypress); committing/cancelling re-anchors focus on the idle trash.

## Appearance

- The control is trailing-aligned in the row/element it annotates, composed
  entirely from the shared `Button` (`ghost` / `destructive-ghost`,
  `icon-sm`) — no bespoke buttons.
- ✓ uses the gold primary accent (`apt-gold`), ✕ the muted text tone
  (`apt-text-muted`), the armed trash the destructive red tone.
- The idle trash is invisible (`opacity-0`) until the hover scope is hovered
  or the button is focused; the reveal is an opacity transition.
- Armed-delete content is dimmed to 50% opacity with a strikethrough
  (`inlineCommitDeletingClass = "opacity-50 line-through"`).
- `InlineEditableText` renders as plain text (transparent field shell) that
  regains the field border on hover and the standard gold focus ring while
  editing.

## States

| State | Appearance change |
|---|---|
| clean, not deletable | Nothing rendered |
| clean, deletable | Trash button, hidden until row hover / focus |
| dirty | ✓ (gold) + ✕ (muted) pair, always visible |
| delete armed | ✓ ✕ + red trash (right-most, `aria-pressed`); content dimmed + struck |
| busy | Pair soft-disabled (`aria-disabled`, clicks ignored, focus kept); ✓ replaced by a spinner; group `aria-busy` |

## Accessibility

- Every button has an `aria-label`/`title`, suffixed with the consumer's
  `subject` (e.g. "Save changes flag beta") so rows are distinguishable to
  screen readers.
- The pending pair is wrapped in `role="group"` with a state-describing label
  ("Commit changes …" / "Confirm deleting …") and `aria-busy` while a commit
  is in flight.
- The armed trash carries `aria-pressed` to expose the armed state.
- The hover-hidden trash becomes visible on keyboard focus
  (`focus-visible:opacity-100`), so delete is keyboard-operable; while hidden
  it is also `pointer-events-none`, so a blind touch tap (no hover) can't arm
  a delete.
- Focus is preserved across state transitions: arming focuses the ✓;
  committing/cancelling re-anchors on the idle trash. Because busy uses
  `aria-disabled` (not `disabled`), an in-flight commit never drops focus.
- `InlineEditableText` requires an `aria-label` (its shell is invisible at
  rest, so there is no visible label) and supports Enter/Escape.
- The navigation guard's dialog is the platform AlertModal (focus trap,
  destructive keyboard policy).

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | hide-when-clean | `dirty=false`, `deletable=false` | Renders nothing |
| T2 | arm-delete | `dirty=false`, `deletable`, click trash | `onDelete` fired once; nothing deleted |
| T2b | reveal-trash-on-hover | `dirty=false`, `deletable`, hover the enclosing `inlineCommitHoverScopeClass` scope | Trash button `opacity-100`, `pointer-events-auto` |
| T2c | reveal-trash-on-hover | `dirty=false`, `deletable`, trash receives keyboard focus (no hover) | Trash button `focus-visible:opacity-100`, `pointer-events-auto` |
| T3 | show-pair-when-dirty, commit-on-ok, cancel-on-x | `dirty`, click ✓ then ✕ | `onCommit` ×1, `onCancel` ×1 |
| T4 | render-armed-delete, commit-armed-delete | `deleting`, click ✓ | Red trash rendered `aria-pressed`; `onCommit` ×1 |
| T4b | disarm-delete | `deleting`, click ✕ | `onCancel` ×1; delete disarmed without deleting |
| T4c | disarm-delete | `deleting`, click the armed red trash | `onDelete` ×1; delete disarmed without deleting |
| T5 | disable-while-busy | `dirty`, `busy`, click ✓/✕ | ✓/✕ `aria-disabled`, still focusable; clicks ignored (`onCommit`/`onCancel` not called); group `aria-busy` |
| T6 | edit-in-place, route-keyboard | type in `InlineEditableText`, press Enter, press Escape | `onChange` per edit; `onCommitEdit` ×1; `onCancelEdit` ×1 |
| T6b | route-keyboard | consumer `onKeyDown` calls `preventDefault`, press Enter | `onKeyDown` ×1; `onCommitEdit` NOT called (suppressed) |
| T7 | guard-navigation-when-dirty | guard `when`, click same-origin link | Click default-prevented; confirm dialog shown; Discard navigates (via `onNavigate`), Stay does not |
| T7b | guard-navigation-when-dirty | guard mounted, `confirmNavigation()` called | Confirm dialog shown; Discard resolves `true`, Stay resolves `false`; with no guard mounted it resolves `true` |
| T7c | guard-navigation-when-dirty | guard `when`, dispatch `popstate` | Confirm dialog shown |
| T8 | (useInlineDrafts) patch drafts | `edit(id,{enabled:true})`, base `description` changes | `changesOf` = `{enabled:true}` only (untouched `description` never sent) |
| T9 | (useInlineDrafts) settle | commit `{description:"a"}` while a newer `"ab"` is typed | after `settle(id,{description:"a"})` the row stays dirty with `"ab"` |
| T10 | (useInlineDrafts) runCommit gate + errors | re-enter `runCommit` for an in-flight row; a rejecting commit | second call no-ops; failure stores the row's error, keeps the draft |
| T11 | preserve-focus | `dirty=false`, `deletable`, click idle trash (arms delete) | The ✓ (commit) button receives focus |
| T12 | preserve-focus | pending group has focus, click ✓ (or ✕) to collapse the pair | The idle trash button regains focus |
| T13 | render-armed-delete | apply `inlineCommitDeletingClass` to the affected content while `deleting` | Content class list includes `opacity-50` and `line-through` |

`@adh-sdk/ui` `src/__tests__/inlineCommitControl.test.tsx`,
`src/__tests__/unsavedChangesGuard.test.tsx`, and
`src/__tests__/useInlineDrafts.test.tsx` implement these vectors.

## Edge Cases

- **Dirty and armed simultaneously** — `deleting` wins the label/grammar: the
  pair reads "Confirm delete", and ✓ commits the delete (the consumer decides
  what happens to the pending edits).
- **Modified clicks** (cmd/ctrl/shift/alt, middle-click) and `target="_blank"`
  links are not intercepted by the guard — they don't leave the page.
- **Cross-origin links** are left to the `beforeunload` prompt (the dialog
  cannot defer a cross-origin unload reliably).
- **Same-page hops** (identical pathname + search, hash-only, `href="#"`) are
  allowed through the guard — they destroy no state.
- **Self-navigating anchors** that consult `confirmNavigation()` in their own
  handler mark themselves `data-guarded-nav` so the guard's click interceptor
  skips them (no double prompt).
- **Commit failure** — the consumer keeps the dirty state, so the pair stays
  visible for retry; the control has no error rendering of its own.
  `useInlineDrafts` captures the failure into that row's error slot without
  disturbing other rows.
- **Keystrokes during a commit** — with `useInlineDrafts`, edits typed while a
  field commit is in flight survive as a still-dirty draft (`settle` drops only
  the committed values), so an in-flight save never discards later typing.
- **Busy cancel** — ✕ is soft-disabled (`aria-disabled`) during flight and
  ignores clicks, but keeps focus; a commit cannot be cancelled mid-request
  from the control.
- **Back-button sentinel cost** — after the page goes clean again, the
  consumed-or-not history sentinel may leave one extra same-URL entry (a
  second Back press); this is the only reliable way to interpose on `popstate`
  without desyncing the app router.

## Configuration

`InlineCommitControl` props:

| Prop | Type | Meaning |
|---|---|---|
| `dirty` | `boolean` | Uncommitted edits exist — show the pair |
| `deleting` | `boolean?` | Delete armed — ✓ ✕ + red trash |
| `deletable` | `boolean?` | Offer the hover trash when clean |
| `busy` | `boolean?` | Commit in flight — soft-disable (`aria-disabled`, focus kept) + spinner |
| `onCommit` | `() => void` | Save edits / commit the armed delete |
| `onCancel` | `() => void` | Discard edits / disarm the delete |
| `onDelete` | `(() => void)?` | Arm (idle trash) or disarm (armed trash) |
| `subject` | `string?` | Accessible subject for button labels |

`InlineEditableText`: `value`, `onChange(value)`, optional
`onCommitEdit`/`onCancelEdit`, optional `variant` (`"default" | "mono" |
"muted"`), required `aria-label`, plus native input props.

`UnsavedChangesGuard`: `when` (guard active) and optional `onNavigate(href)`
(defaults to a full `location.assign`; pass the router's `push` to keep the
navigation client-side). The confirm copy is fixed ("Discard unsaved
changes?" / "Discard" / "Stay") — the guard is the platform's single
unsaved-changes prompt, not a per-page message.

`useInlineDrafts<Id, Draft>(describeError)` returns per-row helpers:
`draftOf(id, base)`, `isDirty(id, base)`, `changesOf(id, base)`, `edit(id,
patch)`, `clear(id)`, `isArmed(id)`, `toggleArmed(id)`, `isBusy(id)`,
`errorOf(id)`, `errors`, `runCommit(id, fn)`, and `settle(id, committed)`.

## Deep Linking

Not applicable: The control is not a standalone page and has no deep linking entry points.

## Localization

The control and its sibling `UnsavedChangesGuard` compose their labels from
fixed English strings plus the consumer-supplied `subject`; none are
externalized today. The `subject` value itself is the consumer's data and is
out of scope here.

| String Key | Default (en) | Context |
|---|---|---|
| `inlineCommitControl.delete` | "Delete{subject}" | Idle trash `aria-label`/`title` |
| `inlineCommitControl.saveChanges` | "Save changes{subject}" | Commit button `aria-label`/`title` when dirty |
| `inlineCommitControl.discardChanges` | "Discard changes{subject}" | Cancel button `aria-label`/`title` when dirty |
| `inlineCommitControl.confirmDelete` | "Confirm delete{subject}" | Commit button `aria-label`/`title` when a delete is armed |
| `inlineCommitControl.cancelDelete` | "Cancel delete{subject}" | Cancel button `aria-label`/`title` when a delete is armed |
| `inlineCommitControl.deleteArmed` | "Delete armed{subject} — click to keep" | Armed red trash `aria-label`/`title` |
| `inlineCommitControl.commitChangesGroup` | "Commit changes{subject}" | `role="group"` label when dirty |
| `inlineCommitControl.confirmDeletingGroup` | "Confirm deleting{subject}" | `role="group"` label when a delete is armed |
| `unsavedChangesGuard.title` | "Discard unsaved changes?" | Navigation-guard confirm dialog title |
| `unsavedChangesGuard.discard` | "Discard" | Navigation-guard confirm action |
| `unsavedChangesGuard.stay` | "Stay" | Navigation-guard cancel action |

Layout is trailing-aligned (logical, following the writing direction), not
literally right-aligned, so it flips correctly under `dir="rtl"`; the
control's own flex-row markup carries no `right`-specific CSS, but the
recipe's earlier "right-justified" phrasing described the LTR case only.

## Accessibility Options

| Option | Behavior |
|---|---|
| Reduce Motion | Not honored: the idle-trash reveal is the control's own `transition-opacity` on its `Button` classes (not something `Button` itself handles), and it carries no `motion-reduce:` variant, so the fade plays regardless of the system preference. |
| Increase Contrast | Not handled directly: foreground/background pairs come from `apt-gold` / `apt-text-muted` / destructive-red design tokens; any high-contrast adaptation is whatever those tokens resolve to, not logic in this control. |
| Differentiate Without Color | Handled: the armed state is also carried by icon shape (trash vs. ✓/✕) and `aria-pressed`, and armed-delete content is also struck through, not color-coded alone. |

## Feature Flags

Not applicable: The control is not gated by feature flags.

## Analytics

Not applicable: The control emits no analytics events; consumers log through their own mutation layer.

## Privacy

Not applicable: The control does not collect, store, or transmit any personal data.

## Logging

None. The control emits no telemetry; consumers log through their own
mutation layer.

## Platform Notes

- **React/Web**: The component ships in `@adh-sdk/ui` from `components/inline-commit-control` and `components/unsaved-changes-guard` (TypeScript, React 19, Base UI components, Tailwind v4). DataTable rows already carry the hover scope; other containers opt in with `inlineCommitHoverScopeClass`. The guard intercepts document-capture clicks before Next.js `<Link>` handlers run; programmatic navigation is covered by a registry callback.
- **SwiftUI**: Start from an `HStack` of icon buttons composed from the shared `Button` component. Drive `dirty`/`deleting`/`busy` from an `@Observable` model (or plain `@State` in the row view); focus uses `@FocusState` to move focus onto the ✓ button when arming a delete and back onto the idle trash when the pair collapses. The optional `useInlineDrafts` equivalent is an `@Observable` store, keyed by row id, holding each row's PATCH draft.
- **Compose**: Start from a `Row` of `IconButton` composables. State uses Compose `State`/`MutableState`; focus uses `FocusRequester` (`requestFocus()` on arm/collapse) together with `Modifier.hoverable`/`onFocusChanged` for the hover-or-focus trash reveal — Compose has no `keyboardInteractionModifier`. The PATCH draft pattern maps to a ViewModel holding the row's draft map.
- **AppKit / UIKit**: Use `NSStackView` / `UIStackView` with `NSButton` / `UIButton` (icon style). State is held in the owning view controller (or an observable object it references), not a SwiftUI view. Focus navigation uses the responder chain and `becomeFirstResponder()`. The draft state machine maps to `@Published` properties in an observable object.
- **WinUI 3**: Use a `StackPanel` of icon `Button` controls — not a `Flyout`, which is a popup control rather than a button style. Bind `dirty`, `deleting`, and `busy` states to XAML via `INotifyPropertyChanged`. Focus management uses `UIElement.Focus()` and `PointerEntered`/`GotFocus` for hover/focus reveal. The PATCH draft state maps to a ViewModel holding a `Dictionary<Id, Draft>` — not an `ObservableCollection<DraftChange>`, which models a list of changes rather than a per-row draft map.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/inline-commit-control.tsx` | unverified |

## Design Decisions

- **Decision**: The control renders `dirty`/`deleting`/`busy` and reports
  intent via callbacks; it never holds draft data itself (ButtonBar
  precedent).
  **Rationale**: Any data layer (react-query, local state) plugs in. The
  optional `useInlineDrafts` hook is the shared implementation of that state.
  **Approved**: pending
- **Decision**: `useInlineDrafts` stores a draft as only the fields the user
  touched, and `settle` drops only the committed keys.
  **Rationale**: A commit then sends — and can clobber — nothing else, even
  after a background refetch changes a sibling field, and keystrokes typed
  mid-flight survive.
  **Approved**: pending
- **Decision**: Busy buttons use `aria-disabled` rather than `disabled`.
  **Rationale**: The buttons stay in the tab order and keep focus across the
  in-flight transition (a `disabled` button loses focus to `<body>`), so
  keyboard commit → busy → done is seamless.
  **Approved**: pending
- **Decision**: Programmatic navigators opt in to the guard through a
  registry callback (`await confirmNavigation()`) instead of an anchor-click
  interceptor.
  **Rationale**: A click interceptor can't see a `router.push`; a tiny
  registry lets every menu/logout share one confirm instead of
  reimplementing it.
  **Approved**: pending
- **Decision**: A delete is staged (armed) and confirmed by the same ✓
  grammar as edits, rather than deleted instantly.
  **Rationale**: One commit vocabulary covers the whole row instead of a
  separate modal per delete.
  **Approved**: pending
- **Decision**: Clicking the armed red trash disarms it.
  **Rationale**: A small reversible action doesn't need a second
  confirmation.
  **Approved**: pending
- **Decision**: `InlineEditableText` is a transparent `Input`, not a
  text-node/edit-mode swap.
  **Rationale**: One fewer state machine — the field is always the real
  input (simplicity, native-controls).
  **Approved**: pending
- **Decision**: The navigation guard raises the platform `AlertModal` for
  in-app links instead of the native `confirm()`; native `beforeunload`
  remains for hard unloads.
  **Rationale**: Consistent with the platform's dialog policy; `beforeunload`
  is kept because custom UI can't intercept a hard unload.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | Platform |
| [adc.check.platform-compliance.platform-theming](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d2b685fd-b481-5d38-bd70-403bd202b5c6) | passed | Platform |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | failed | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | partial | Security |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |

Statuses rest on `inline-commit-control.tsx`: Button-only composition and
`apt-*`/token-only classNames (native-controls-preference, platform-theming);
the documented `aria-label`/`role="group"`/focus-management logic
(keyboard-navigable, focus-management); the unconditional
`transition-opacity` reveal with no `motion-reduce:` variant
(reduced-motion); the hardcoded English button/group labels with no
resource-file indirection and no `dir`-aware positioning (no-hardcoded-strings,
string-externalization, rtl-layout-support); `InlineEditableText`'s passthrough
of the raw input value with no validation of its own (input-sanitization); and
the vector-to-test mapping across the three `__tests__` files cited above
(unit-test-coverage, vectors T1–T13); and the source's own note that "the
consumer owns all state — draft values, dirty computation, the armed set … —
the control just renders it," with no data access or business rule of its own
beyond the focus-management effect (separation-of-concerns).

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab-case; correct Platform Notes to real native APIs; fix Overview export count and trailing-alignment phrasing; reformat Design Decisions and Compliance to convention; fill Localization and Accessibility Options with real content; fix `related` and `tags`; fix `onDelete` type; split/add Conformance Test Vectors for hover/focus reveal, disarm-via-✕, focus preservation, and armed-delete content styling. |
| 1.1.0 | 2026-09-22 | Claude Haiku 4.5 | Promote to review; add missing sections and cross-platform Platform Notes |
| 1.0.0 | 2026-07-07 | Mike Fullerton | Initial draft |
