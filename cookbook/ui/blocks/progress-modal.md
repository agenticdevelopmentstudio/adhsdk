---
id: d9b07d1e-b53c-4efa-86f1-82a31ad9f02f
title: "Progress Modal"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Modal dialog displaying real-time progress of a batch operation with error handling and decision points."
platforms:
  - typescript
  - web
tags:
  - modal
  - progress
  - batch-operations
depends-on:
  - 972be0d0-a9f5-45cd-a23b-c8329410b3d1
  - b3a92adc-a28e-4a33-8120-c33f8f0abdf6
related: []
references: []
approved-by: ""
approved-date: ""
---

# Progress Modal

## Overview

A modal dialog that displays the real-time progress of a batch operation. It shows a progress bar, the current item being processed, a log of completed items, and handles error states by halting the operation and offering the user a choice to continue or stop. The modal does not close itself—the host owns the operation loop and decides when to dismiss. The modal cannot be dismissed mid-run, preventing accidental loss of visibility into background operations.

| Prop | Type | Required | Default |
|------|------|----------|---------|
| `open` | `boolean` | required | — |
| `title` | `React.ReactNode` | required | — |
| `description` | `React.ReactNode` | optional | — |
| `done` | `number` | required | — |
| `total` | `number` | required | — |
| `currentLabel` | `React.ReactNode` | optional | — |
| `error` | `ProgressError \| null` | optional | `null` |
| `finished` | `boolean` | optional | `false` |
| `onContinue` | `() => void` | optional | — |
| `onStop` | `() => void` | optional | — |
| `onClose` | `() => void` | optional | — |
| `results` | `ReadonlyArray<ProgressResult>` | optional | `[]` |
| `okLabel` | `React.ReactNode` | optional | `"done"` |
| `failedLabel` | `React.ReactNode` | optional | `"failed"` |

## Behavioral Requirements

- **render-as-dialog**: Component MUST render as a modal dialog that can be opened and closed via the `open` prop.
- **show-progress-bar**: Component MUST display a progress bar whose value is calculated as `(done / total) * 100` when total is greater than zero, or zero when total is zero.
- **display-completion-count**: Component MUST display the count as "done of total" in monospace font.
- **display-status-or-current-label**: Component MUST display `currentLabel` when provided. When `currentLabel` is omitted and the run is finished, MUST display "Finished". When omitted and the run is halted (error set and not finished), MUST display "Paused". When omitted and the run is in progress (no error, not finished), MUST display "Working…".
- **halt-on-error**: When `error` is set and `finished` is false (halted), the component MUST render the error block and, instead of the in-progress button state, show the Continue/Stop buttons (see **show-continue-and-stop-when-halted**). The progress bar continues to reflect `done`/`total` exactly as supplied by the host — the component does not itself pause any operation.
- **show-error-block-when-halted**: When halted, component MUST render an error block containing the error message. If `error.itemLabel` is present, it MUST appear above the error message.
- **show-results-log-when-provided**: When `results` array has items, component MUST render them as a scrollable list with maximum height constraint, regardless of whether the run is running, halted, or finished.
- **render-result-label-and-status**: Each result item MUST display the result's label followed by a status indicator. For failed results, MUST display the result message or `failedLabel` in red. For successful results, MUST display the result message or `okLabel` in muted text.
- **show-continue-and-stop-when-halted**: When halted (error set and not finished), component MUST display Continue and Stop buttons if their respective callbacks are provided.
- **show-close-when-finished**: When finished is true, component MUST display a Close button if `onClose` callback is provided.
- **finished-overrides-halt**: When `finished` is true, the component MUST NOT render the error block or the Continue/Stop buttons, even if `error` is still set; only the Close button (per **show-close-when-finished**) may render.
- **hide-buttons-during-progress**: When the run is in progress (no error and not finished), component MUST not display any action buttons.
- **prevent-dismiss-mid-run**: When `finished` is false, the component MUST swallow Escape and close-button dismiss requests internally and MUST NOT call `onClose`. When `finished` is true, the component MUST call `onClose` in response to Escape or the close button.
- **calculate-percentage-safely**: Component MUST handle zero total by setting percentage to zero instead of NaN.

## Appearance

Spacing values below use the Tailwind spacing scale (1 unit = 0.25rem).

- **Container**: Dialog with maximum width of 32rem (512px).
- **Progress bar**: Full width, default height per Progress component spec.
- **Status section**: Flex row with baseline alignment, gap of 3 units (0.75rem).
- **Status text**: Extra-small font size, muted text color. Item label truncated on overflow.
- **Count text**: Monospace font, extra-small size, muted text color, no shrink.
- **Error box**: Rounded border, `apt-red` border color at 40% opacity, `apt-red` background at 5% opacity, padding 2 units (0.5rem), text extra-small.
- **Error item label**: Medium font weight, normal text color.
- **Error message**: `apt-red` text color.
- **Results list**: Scrollable container with maximum height 12rem (192px), rounded border, `apt-border` border color, padding 2 units (0.5rem), vertical gap 1 unit (0.25rem).
- **Result row**: Extra-small font size.
- **Result label**: Medium font weight, normal text color.
- **Result status**: Muted or `apt-red` text depending on status, separated by " — " from label.
- **Dialog header**: Displays title and optional description via DialogHeader, DialogTitle, and DialogDescription components.
- **Dialog footer**: Contains action buttons with small size variant.

## States

| State | Appearance change | Behavior |
|-------|-------------------|----------|
| Running | Progress bar reflects `done`/`total`; status shows `currentLabel` if provided, otherwise "Working…"; no action buttons visible | Modal is open; Escape/× dismiss requests are swallowed internally (no `onClose` call); `done` updates as the host advances the batch |
| Halted | Progress bar unchanged from the last render; status shows `currentLabel` if provided, otherwise "Paused"; error block visible; Continue and Stop buttons visible | Modal remains open; Escape/× dismiss requests are swallowed internally (no `onClose` call); awaiting a Continue/Stop decision |
| Finished | Progress bar reflects `done`/`total` as provided — not necessarily 100%, since a Stop can finish the run early; status shows `currentLabel` if provided, otherwise "Finished"; error block and halted buttons are hidden even if `error` is still set; Close button visible if `onClose` is provided | Modal is open; Escape, ×, or the Close button all call `onClose` |
| Closed | — | Modal is not rendered (`open` prop is false) |

The results log renders whenever `results` has items, independent of the state above — it is not exclusive to Finished.

## Accessibility

Accessibility is delegated to the composed `Dialog` and `Progress` components. `Dialog` (Base UI primitives — see [adhsdk.ingredient.ui.components.overlays.dialog](cookbook:972be0d0-a9f5-45cd-a23b-c8329410b3d1)) provides the ARIA dialog role, backdrop, and keyboard handling (Escape, focus trapped while open). `Progress` (see [adhsdk.ingredient.progress](cookbook:b3a92adc-a28e-4a33-8120-c33f8f0abdf6)) is a self-contained element with `role="progressbar"` and `aria-valuemin`/`aria-valuemax`/`aria-valuenow`. Neither component announces state changes via a live region in the current source: there is no `aria-live` region on the status text, no `role="alert"` on the error block, and no explicit focus movement when the run halts or finishes — focus stays wherever the user last left it inside the trapped dialog.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| progress-001 | show-progress-bar | `open={true}, done={3}, total={10}` | Progress bar shows 30% width |
| progress-002 | calculate-percentage-safely | `open={true}, done={0}, total={0}` | Progress bar shows 0%, no NaN displayed |
| progress-003 | display-completion-count | `open={true}, done={5}, total={20}` | Text displays "5 of 20" in monospace |
| progress-004 | display-status-or-current-label | `open={true}, currentLabel={"Uploading file.txt"}, finished={false}, error={null}` | Status text shows "Uploading file.txt" |
| progress-005 | display-status-or-current-label | `open={true}, currentLabel={undefined}, finished={true}` | Status text shows "Finished" |
| progress-006 | display-status-or-current-label | `open={true}, currentLabel={undefined}, finished={false}, error={…}` | Status text shows "Paused" |
| progress-007 | display-status-or-current-label | `open={true}, currentLabel={undefined}, finished={false}, error={null}` | Status text shows "Working…" |
| progress-008 | halt-on-error, show-error-block-when-halted | `open={true}, error={message: "Upload failed"}, finished={false}` | Error block visible with message "Upload failed" |
| progress-009 | show-error-block-when-halted | `open={true}, error={message: "Failed", itemLabel: "photo.jpg"}, finished={false}` | Error block shows "photo.jpg" above "Failed" message |
| progress-010 | show-results-log-when-provided | `open={true}, results=[{id: "1", label: "file1.txt", status: "ok"}]` | Results list renders with one item |
| progress-011 | render-result-label-and-status | `open={true}, results=[{id: "1", label: "file.txt", status: "ok", message: "moved"}]` | Result shows "file.txt — moved" in muted text |
| progress-012 | render-result-label-and-status | `open={true}, results=[{id: "1", label: "file.txt", status: "failed", message: "Not found"}]` | Result shows "file.txt — Not found" in red text |
| progress-013 | render-result-label-and-status | `open={true}, results=[{id: "1", label: "file.txt", status: "ok"}], okLabel={"synced"}` | Result shows "file.txt — synced" (no message provided, uses okLabel) |
| progress-014 | show-continue-and-stop-when-halted | `open={true}, error={…}, finished={false}, onContinue={fn}, onStop={fn}` | Continue and Stop buttons are visible and clickable |
| progress-015 | show-close-when-finished | `open={true}, finished={true}, onClose={fn}` | Close button is visible and clickable |
| progress-016 | hide-buttons-during-progress | `open={true}, finished={false}, error={null}` | No action buttons are visible |
| progress-017 | prevent-dismiss-mid-run | `open={true}, finished={false}` triggered by Escape | `onClose` is NOT called; modal remains open |
| progress-018 | prevent-dismiss-mid-run | `open={true}, finished={true}, onClose={fn}` triggered by Escape | `onClose` IS called |
| progress-019 | finished-overrides-halt | `open={true}, error={message: "Upload failed"}, finished={true}, onClose={fn}` | Error block and Continue/Stop buttons are NOT rendered; only Close is visible |

## Edge Cases

- **Empty batch**: When `total` is zero, percentage calculation produces zero instead of NaN. Progress bar renders at 0%.
- **No results**: When `results` array is empty or undefined, results log section does not render.
- **No error**: When `error` prop is null or undefined, error block does not render.
- **Missing itemLabel in error**: When `error.itemLabel` is null or undefined, only the error message renders in the error block.
- **Missing message in result**: When a result has no `message` property, the component uses `okLabel` (for "ok" status) or `failedLabel` (for "failed" status) as the displayed text.
- **Error present at finish**: When `error` is set and `finished` is also true, `finished` takes precedence — the error block and Continue/Stop buttons do not render; only Close renders (see **finished-overrides-halt**).
- **Stop action while processing**: When `onStop` is invoked, the host owns the batch loop and decides when to set `finished={true}`. The modal does not stop the underlying operation.
- **Continue after error**: When `onContinue` is invoked, the host resumes the batch loop. The `error` prop is expected to be cleared by the host in the next render.
- **Dismiss attempt mid-run**: Pressing Escape or clicking the close button while `finished={false}` is swallowed internally — the component does not call `onClose` and the modal remains open. `ProgressModal` has no host-facing `onOpenChange` prop; the swallowing happens inside the component's own wiring to the underlying `Dialog`.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `okLabel` | `React.ReactNode` | `"done"` | Text shown for a result with `status: "ok"` and no `message`. |
| `failedLabel` | `React.ReactNode` | `"failed"` | Text shown for a result with `status: "failed"` and no `message`. |

## Deep Linking

Not applicable: This component is a modal overlay managed by its host and is not independently deep-linkable.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `status.working` | "Working…" | Displayed when run is in progress and no `currentLabel` is provided. Hardcoded in the component; not exposed as a prop. |
| `status.paused` | "Paused" | Displayed when run is halted on error and no `currentLabel` is provided. Hardcoded; not exposed as a prop. |
| `status.finished` | "Finished" | Displayed when run is complete and no `currentLabel` is provided. Hardcoded; not exposed as a prop. |
| `action.continue` | "Continue" | Button label when halted. Hardcoded; not exposed as a prop. |
| `action.stop` | "Stop" | Button label when halted. Hardcoded; not exposed as a prop. |
| `action.close` | "Close" | Button label when finished. Hardcoded; not exposed as a prop. |
| `progress.count` | "{done} of {total}" | Count text. Word order is locale-dependent — a translation MUST be able to reorder the `{done}`/`{total}` placeholders, not just substitute the numbers. Hardcoded; not exposed as a prop. |
| `result.ok` | "done" | Default status text when result status is "ok" and no message provided (overridable via `okLabel` prop). |
| `result.failed` | "failed" | Default status text when result status is "failed" and no message provided (overridable via `failedLabel` prop). |

Only `result.ok` and `result.failed` are host-overridable (`okLabel`/`failedLabel`); every other string above is a hardcoded JSX literal in the component.

## Accessibility Options

Not applicable: This component does not respond to platform-level accessibility display options. Its accessibility behavior is delegated to the Dialog and Progress child components.

## Feature Flags

Not applicable: This component does not check feature flags. Feature gating of the batch operation itself is the responsibility of the host.

## Analytics

Not applicable: This component does not emit analytics events. The host is responsible for tracking batch operation metrics if needed.

## Privacy

Not applicable: This component does not collect, store, or transmit any user data. The `currentLabel`, `results`, and error `message` content is provided by the host and may contain user-facing or sensitive data, which the host is responsible for handling.

## Logging

Not applicable: This component does not perform logging. Debug information about batch progress and errors is the responsibility of the host operation loop.

## Platform Notes

- **React/Web**: Implemented using the shared `Dialog` (Base UI primitives, [adhsdk.ingredient.ui.components.overlays.dialog](cookbook:972be0d0-a9f5-45cd-a23b-c8329410b3d1)) and `Progress` (self-contained `role="progressbar"` element, [adhsdk.ingredient.progress](cookbook:b3a92adc-a28e-4a33-8120-c33f8f0abdf6)) components. `Dialog`'s `onOpenChange` swallows Escape/× internally and only calls `onClose` once `finished` is true. Progress percentage is calculated client-side (`Math.round((done / total) * 100)`, or `0` when `total` is `0`). Results are rendered as a flex column with overflow constraints.
- **SwiftUI**: Present with `.sheet()` or `.fullScreenCover()` bound to the `open` state. Use the determinate initializer `ProgressView(value: Double(done), total: Double(total))` — the bare `ProgressView()` initializer is indeterminate and would not reflect `done`/`total`. Block mid-run dismissal with `.interactiveDismissDisabled(!finished)`. Render the error block conditionally on `error != nil && !finished`. Use a `List` or `ScrollView` with a frame height constraint for the results log.
- **Compose**: Build on `AlertDialog` or `Dialog`. Use `LinearProgressIndicator(progress = { done / total.toFloat() })` for a determinate bar. Set `onDismissRequest` to a callback that only closes if `finished` is true. Render the error and results sections conditionally on the same `error`/`finished` state used on other platforms. Use `LazyColumn` for the scrollable results list.
- **AppKit / UIKit**: `NSAlert` (macOS) and `UIAlertController` (iOS) cannot host a progress bar plus a scrollable results list, so use a custom window or view controller instead. Add `NSProgressIndicator` (style `.bar`, `isIndeterminate = false`) on macOS or `UIProgressView` on iOS as a subview, driven by `done`/`total`. Prevent dismissal by disabling or intercepting the window/controller's close action until `finished` is true. Render the error and results sections in custom subviews.
- **WinUI 3**: Use `ContentDialog` as the container and a `ProgressBar` for the progress display. To *hide* the action buttons during progress (not merely disable them), leave `PrimaryButtonText`/`SecondaryButtonText` empty — an empty button text hides that button — and set them only once halted or finished. Use a `ScrollViewer` containing an `ItemsControl` or `ListView` for the results log. Prevent dismissal by handling the `Closing` event and only letting the close proceed once `finished` is true.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/progress-modal.tsx` | unverified |

## Design Decisions

1. **Decision**: Halt the batch on the first error and require the user to decide whether to continue or stop, rather than completing all items and presenting a summary at the end.
**Rationale**: Assumes that a failure in one item often indicates a systemic cause (e.g., a wrong destination path) that will recur for the remaining items, so continuing unattended risks repeating a preventable failure across the rest of the batch. This is a heuristic the host applies by setting `error`, not a guarantee the component enforces.
**Approved**: pending

2. **Decision**: The component does not dismiss itself on completion. Instead, it swaps the action buttons for a Close button, making the user responsible for dismissal.
**Rationale**: This preserves the record of what happened—the completed results are visible until the user explicitly closes the dialog.
**Approved**: pending

3. **Decision**: Progress is tracked as an item count (`done` / `total`), not elapsed time or bytes transferred.
**Rationale**: The host controls the loop and reports completion for each discrete operation, so an item count is an accurate fact rather than a throughput-based guess.
**Approved**: pending

4. **Decision**: The component is transport-agnostic — it renders state and emits decisions (Continue, Stop, Close) without knowing whether the batch is uploading, deleting, moving, or any other operation.
**Rationale**: Any host can drive it without specialized knowledge of the underlying operation.
**Approved**: pending

5. **Decision**: `okLabel` and `failedLabel` default to deliberately generic values ("done", "failed").
**Rationale**: The component runs any batch, so a hardcoded verb like "moved" would be a lie in a delete run. A host with domain-specific knowledge can pass a better verb.
**Approved**: pending

6. **Decision**: Escape and the × button are swallowed until the run ends (`finished` is true).
**Rationale**: Closing the dialog does not stop the background requests; a dialog that vanished on a stray keystroke would leave the batch running invisibly, losing visibility into the operation.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | partial | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | failed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source: `Progress` sets an explicit `role="progressbar"` with `aria-valuemin`/`max`/`now`, `Dialog` (Base UI) renders native ARIA dialog semantics and traps focus, and Continue/Stop/Close buttons carry their own text as their accessible name — but nothing in the source moves focus on halt/finish, defines `apt-*` token contrast values, or sizes the `sm` buttons, and every visible string except `okLabel`/`failedLabel` is a hardcoded English JSX literal with no locale-aware formatting or confirmed RTL handling. `ProgressModal` is transport-agnostic — it renders state and emits decisions, and the host owns the batch loop and any network calls (separation-of-concerns passed); `progressModal.test.tsx` exercises the percentage calculation, the halted/finished/healthy button states, Continue/Stop/Close handlers, and the running log directly (unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to drop `must-` prefix; correct the Accessibility section's false live-region claim to match Base UI Dialog/self-contained Progress; add a props table; unify the dismiss contract across the requirement, vectors, and edge case (no host-facing `onOpenChange`); add the finished-overrides-halted-error requirement and vector; fix the Finished/Halted rows in States and the results-log condition; reword halt-on-error as an observable outcome; replace literal "red"/"units" with token names and a spacing-scale note; add a `progress.count` localization key and mark which strings are hardcoded vs. overridable; fill in Configuration and Compliance tables; correct Platform Notes for AppKit/UIKit, SwiftUI, and WinUI 3; reframe design decision 1 as an assumption; add `depends-on` for Dialog and Progress; note the Change History author discrepancy is a generator attribution, not a frontmatter conflict. |
| 1.1.0 | 2026-09-22 | Claude Haiku 4.5 | Revise accessibility section: document delegation to composed components rather than mark as unimplemented |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source code analysis |

Earlier rows were generated by Claude Haiku 4.5; frontmatter `author` reflects the accountable human author, not the generator.
