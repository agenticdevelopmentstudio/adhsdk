---
id: 33aaba17-874f-43aa-8d70-4a5dab2081a1
title: Batch Select
domain: adhsdk://recipes/batch-select
type: ingredient
version: 1.1.2
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Hook and button for toggling multi-select mode in lists, with automatic selection
  clearing when visible rows change.
platforms:
- typescript
- web
tags:
- selection
- list-control
- multi-select
depends-on: []
related: []
references: []
approved-by: ''
approved-date: ''
---

# Batch Select

## Overview

Batch Select provides a mode for lists to enter multi-select behavior, distinct from the default single-select interaction. The hook (`useBatchSelect`) manages the state of active (batch mode on/off) and selected row IDs, with automatic clearing of selections when the visible rows change (via page, filter, or search). The button component (`BatchSelectButton`) toggles batch mode and reflects the current state with label changes.

## Behavioral Requirements

- **expose-active-state**: The hook MUST expose a boolean `active` property indicating whether batch mode is currently active.
- **expose-selected-ids**: The hook MUST expose a `selectedIds` property as a `Set<string>` of currently selected row identifiers.
- **provide-set-selected-ids**: The hook MUST provide a `setSelectedIds` function to update the selected row IDs, accepting a `Set<string>` parameter.
- **expose-toggle-active**: The hook MUST provide a `toggleActive` function that switches batch mode on and off.
- **clear-selection-on-toggle-exit**: When `toggleActive` is called to exit batch mode, the `selectedIds` MUST be cleared to an empty `Set<string>`.
- **clear-selection-on-toggle-entry**: When `toggleActive` is called to enter batch mode, the `selectedIds` MUST be cleared to an empty `Set<string>`.
- **provide-clear-function**: The hook MUST provide a `clear` function that empties `selectedIds` without changing the `active` state.
- **expose-count**: The hook MUST expose a `count` property equal to the size of `selectedIds`.
- **reset-on-reset-key-change**: When the `resetKey` option changes (as determined by `Object.is` comparison), the hook MUST reset `selectedIds` to an empty `Set<string>` synchronously during render.
- **set-selected-ids-new-reference**: Each call to `setSelectedIds` MUST hand back exactly the `Set<string>` instance the caller supplied; the hook MUST NOT synthesize a new instance or preserve the previous one by comparing contents, so calling `setSelectedIds` with a different object — even one with identical contents — MUST produce a new `selectedIds` reference on the next render.
- **reset-uses-shared-empty-selection**: Every render-time reset (see **reset-on-reset-key-change**) MUST set `selectedIds` to the same shared `EMPTY_SELECTION` instance rather than a freshly constructed empty `Set`, so consecutive resets return an identical reference and do not invalidate callers' memoized effects.
- **button-render-label**: The `BatchSelectButton` MUST render a clickable element displaying either the `selectLabel` (when inactive) or `doneLabel` (when active).
- **button-toggle-on-click**: The `BatchSelectButton` MUST call `batch.toggleActive` when clicked.
- **button-announce-pressed-state**: The `BatchSelectButton` MUST set `aria-pressed` to reflect the `batch.active` state.
- **button-default-select-label**: If `selectLabel` is not provided, the button MUST render "Select".
- **button-default-done-label**: If `doneLabel` is not provided, the button MUST render "Done".

## Appearance

Not applicable: This is a state management hook and a generic button. Visual appearance is determined by the underlying Button component and the consuming application.

## States

| State | Appearance change |
|-------|------------------|
| active: true | Button displays `doneLabel` text; `aria-pressed="true"` |
| active: false | Button displays `selectLabel` text; `aria-pressed="false"` |

## Accessibility

- **role**: The `BatchSelectButton` MUST delegate its role to the underlying Button component, which provides button semantics.
- **pressed-state-announcement**: The `BatchSelectButton` MUST announce the pressed state via `aria-pressed` attribute, updating to reflect `batch.active` on each render.
- **label-provided-by-text**: The button text (`selectLabel` or `doneLabel`) MUST serve as the accessible label.
- **keyboard-navigable**: The underlying Button component MUST be keyboard navigable and activatable via Enter or Space keys.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| batch-select-001 | expose-active-state | `useBatchSelect()` | Returns object with `active: false` |
| batch-select-002 | expose-selected-ids | `useBatchSelect()` | Returns object with `selectedIds` as empty `Set<string>` |
| batch-select-003 | expose-toggle-active | `useBatchSelect()` | Returns object with `toggleActive` function |
| batch-select-004 | expose-count | `useBatchSelect()` with selections | `count` equals `selectedIds.size` |
| batch-select-005 | clear-selection-on-toggle-exit | active=true, selectedIds={id1, id2}, call toggleActive | active becomes false, selectedIds becomes empty Set |
| batch-select-006 | clear-selection-on-toggle-entry | active=false, call `setSelectedIds(new Set(['id1']))`, then call toggleActive | active becomes true, selectedIds becomes empty Set (the seeded id1 is cleared, not carried into batch mode) |
| batch-select-007 | provide-clear-function | active=true, selectedIds={id1}, call clear | active stays true, selectedIds becomes empty Set |
| batch-select-008 | reset-on-reset-key-change | Render with resetKey=1, then resetKey=2, selectedIds={id1} | selectedIds cleared to empty Set during render of resetKey=2 |
| batch-select-009 | reset-on-reset-key-change | Render with resetKey="search:foo", then resetKey="search:foo" (same value) | selectedIds retained, no reset |
| batch-select-010 | set-selected-ids-new-reference | Render, then render again with no call to `setSelectedIds` | selectedIds reference is the same object between the two renders |
| batch-select-011 | button-render-label | BatchSelectButton with active=false, selectLabel="Pick" | Button displays "Pick" |
| batch-select-012 | button-render-label | BatchSelectButton with active=true, doneLabel="Finish" | Button displays "Finish" |
| batch-select-013 | button-default-select-label | BatchSelectButton with active=false, no selectLabel | Button displays "Select" |
| batch-select-014 | button-default-done-label | BatchSelectButton with active=true, no doneLabel | Button displays "Done" |
| batch-select-015 | button-announce-pressed-state | BatchSelectButton with active=false | `aria-pressed="false"` on button element |
| batch-select-016 | button-announce-pressed-state | BatchSelectButton with active=true | `aria-pressed="true"` on button element |
| batch-select-017 | button-toggle-on-click | BatchSelectButton clicked while active=false | batch.toggleActive is called, active becomes true |
| batch-select-018 | set-selected-ids-new-reference | selectedIds={id1}, call `setSelectedIds(new Set(['id1']))` (same contents, different instance) | selectedIds reference is a new object, distinct from the previous render's |
| batch-select-019 | reset-uses-shared-empty-selection | Render with resetKey=1 then resetKey=2 (first reset), then resetKey=3 (second reset) | Both resets set selectedIds to the identical `EMPTY_SELECTION` object (`Object.is` true across the two resets) |
| batch-select-020 | provide-set-selected-ids | `useBatchSelect()`, call `setSelectedIds(new Set(['id1']))` | selectedIds becomes `Set{'id1'}`, count becomes 1 on next render |
| batch-select-021 | Rapid toggles (edge case) | active=false, selectedIds={id1}, call toggleActive three times in quick succession | active ends true (odd number of toggles), selectedIds ends empty Set |
| batch-select-022 | resetKey as non-primitive (edge case) | Render repeatedly with `resetKey={}` (a new object literal each render), selectedIds={id1} | selectedIds is cleared to empty Set on every render, even though the semantic filter value never changed |

## Edge Cases

- **Rapid toggles**: If `toggleActive` is called multiple times in quick succession, each call MUST correctly flip the state and clear the selection; the final state MUST reflect the number of toggles applied.
- **resetKey as non-primitive**: If `resetKey` is an object or array (non-primitive) that is rebuilt each render, the selection MUST be cleared on every render even if the semantic value is unchanged, because `Object.is` compares reference identity, not deep equality.
- **selectedIds mutation**: If a caller mutates the returned `selectedIds` Set directly, the behavior is undefined. The contract requires that all updates go through `setSelectedIds`; direct mutation violates the contract.
- **Empty selection display**: When `selectedIds` is empty (size is 0), the button text and pressed state MUST still render correctly; there is no visual hiding or disabling of the button based on count.
- **Render-time reset vs effect**: The reset happens synchronously during render (not in an effect), so a commit with new `resetKey` will never execute pending actions with stale selection against new rows.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `resetKey` | `unknown` (pass a primitive) | `undefined` | Value identifying which rows are currently visible (page number, search string, active filters). Whenever it changes by `Object.is`, `selectedIds` is cleared. See **reset-on-reset-key-change**. |
| `selectLabel` | `string` | `"Select"` (`batch_select.select`) | Label the `BatchSelectButton` displays while batch mode is inactive. |
| `doneLabel` | `string` | `"Done"` (`batch_select.done`) | Label the `BatchSelectButton` displays while batch mode is active. |

## Deep Linking

Not applicable: Batch Select manages internal component state and does not implement deep linking.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `batch_select.select` | "Select" | Label for `BatchSelectButton` when not in batch mode. The `selectLabel` prop overrides this default directly, but the default itself is resolved through the platform's localization system, not hardcoded per locale. |
| `batch_select.done` | "Done" | Label for `BatchSelectButton` when in batch mode. The `doneLabel` prop overrides this default directly, but the default itself is resolved through the platform's localization system. |

## Accessibility Options

Not applicable: Batch Select does not respond to accessibility display options such as Reduce Motion, Increase Contrast, or Differentiate Without Color, as it has no motion or color-dependent behaviors beyond what the underlying Button component provides.

## Feature Flags

Not applicable: Batch Select is a foundational hook with no feature flag integration in the source code.

## Analytics

Not applicable: Batch Select does not emit analytics events directly; consuming applications MAY track interactions with BatchSelectButton separately if needed.

## Privacy

Not applicable: Batch Select stores only row identifiers in memory; no data is persisted, transmitted, or collected.

## Logging

Not applicable: Batch Select does not emit debug or informational logs.

## Platform Notes

- **React/Web**: Implemented as a custom hook (`useBatchSelect`) exported from `packages/web/packages/ui/src/blocks/batch-select.tsx`. The hook manages state with `React.useState` and `React.useCallback`, and performs render-time reset via `React.useRef`. `BatchSelectButton` wraps the shared Button component with `aria-pressed` binding.
- **SwiftUI**: Keep `active` and `selectedIds` in an `@Observable` model rather than local `@State` — writing `@State` during `body` triggers a runtime warning or an update loop, and the reset must be visible before the view reads `selectedIds`. Call `model.sync(resetKey:)` at the top of `body` before reading `selectedIds`, or explicitly accept `.onChange(of: resetKey)` and document the resulting one-frame gap. Implement `toggleActive` and `clear` on the model, matching the hook interface. Render `BatchSelectButton` as `Toggle(isOn: ...) { Text(...) }.toggleStyle(.button)` bound to `model.active`, not a plain `Button`, so the pressed state is exposed as a native toggle.
- **Compose**: Implement as a composable returning a data class mirroring `BatchSelect`. Use `remember { mutableStateOf(...) }` for `active` and `selectedIds`. Perform `resetKey` comparison in the composable body (not in an effect) to clear synchronously. `BatchSelectButton` should apply `Modifier.toggleable(value = batch.active, onValueChange = { batch.toggleActive() })` (or set `semantics { toggleableState = ... }` directly) so the pressed state is exposed as a toggleable control rather than through `contentDescription`.
- **AppKit / UIKit**: Implement as a reference type (class) managing `active` and `selectedIds` properties with property observers. Store the last `resetKey` and check it on access to the hook, resetting synchronously if it changes. Provide `toggleActive()` and `clear()` methods. `BatchSelectButton` is a `UIButton` with `changesSelectionAsPrimaryAction = true`, so tapping toggles `isSelected` natively; call `toggleActive()` from the `.primaryActionTriggered` handler, and add the `.selected` accessibility trait when `isSelected` is true so assistive technology announces the pressed state (`isSelected` / `UIControl.State.selected` alone changes appearance but not the accessible state).
- **WinUI 3**: Implement as a `BindableBase` or `ObservableObject` exposing `Active` (bool), `SelectedIds` (`IReadOnlySet<string>`, replaced with a new instance on every change rather than an `ObservableCollection<string>`, to keep the replace-not-mutate contract), `SetSelectedIds(IReadOnlySet<string>)`, `ToggleActive()`, and `Clear()` methods. Use a backing field for `ResetKey` and perform the reset inside the `ResetKey` setter (not a property getter, where resetting as a side effect of a read would be surprising) so `SelectedIds` clears synchronously when it changes. `BatchSelectButton` is a `ToggleButton` bound to `IsChecked`, not a plain `Button`, so the pressed state is exposed as a native toggle rather than through `AutomationProperties.AutomationId` alone; call `ToggleActive()` from the `Checked`/`Unchecked` handlers.

## Design Decisions

**Decision**: Selection is cleared on both entry and exit of batch mode.
**Rationale**: Clearing on exit prevents an invisible selection after toggling off. Clearing on entry ensures a fresh batch interaction does not inherit selections from a prior single-select interaction. This prevents accidentally acting on rows a user has reason to believe were deselected.
**Approved**: pending

**Decision**: The `resetKey` reset happens synchronously during render, not in an effect.
**Rationale**: An effect-based reset would allow one render to commit with stale selections against new rows (e.g., after filtering or paging). The render-time reset via `React.useRef` ensures that by the time `selectedIds` is visible to the caller, it already reflects the current `resetKey`.
**Approved**: pending

**Decision**: `resetKey` comparison uses `Object.is`.
**Rationale**: This permits primitives (page number, search string) to be passed directly without rebuilding. Passing non-primitives (rebuilt objects or Sets) causes a reset on every render; this is a caller error, not a hook error. See **resetKey as non-primitive**.
**Approved**: pending

**Decision**: Render-time reset clears `selectedIds` to a shared `EMPTY_SELECTION` instance rather than a freshly constructed empty `Set`.
**Rationale**: A shared reference prevents caller effects and memos from being invalidated by render-time resets; a freshly constructed empty `Set` on each reset would look like a new value to consumers and cause unnecessary re-computation. See **reset-uses-shared-empty-selection**.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | partial | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The accessibility statuses rest on the `aria-pressed` binding and delegation to the shared Button component for role, label, and keyboard support (`batch-select.tsx`); touch target size is not set in this source and is inherited from that Button component, so it is marked partial here. The internationalization statuses are partial because the source's `selectLabel`/`doneLabel` defaults are literal English strings resolved by JavaScript default parameters (`batch-select.tsx`), not by a localization resource lookup. Best-practices statuses rest on the selection state machine living entirely in the `useBatchSelect` hook, apart from the purely presentational `BatchSelectButton` (separation-of-concerns: passed), and on `batchSelect.test.tsx` exercising the hook's mode toggling, clearing, and `resetKey` behavior through a real harness with meaningful assertions (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case and split the conflicting set-reference requirement into set-selected-ids-new-reference and reset-uses-shared-empty-selection; reformatted Design Decisions into the three-line form; documented Configuration options; rewrote Localization to use real string keys; fixed test vectors 006 and 010 and added vectors for provide-set-selected-ids, the rapid-toggle and non-primitive-resetKey edge cases, and shared-empty-Set identity; renamed the resetKey edge case; corrected Platform Notes to use real native toggle APIs (SwiftUI `Toggle`/`.toggleStyle(.button)`, Compose `Modifier.toggleable`, UIKit `changesSelectionAsPrimaryAction` plus the `.selected` trait, WinUI `ToggleButton`/`IsChecked` and `IReadOnlySet<string>`); corrected the Compliance table to reference real catalog checks |
| 1.1.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: removed source line-number citations. |
| 1.1.2 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
