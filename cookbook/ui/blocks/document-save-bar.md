---
id: c54698ea-490c-41e2-ad8f-762f257839ca
title: "Document Save Bar"
type: ingredient
version: 1.0.0
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The standard Cancel/Save editing bar for a versioned document, with inline notices and a Reload theirs or Overwrite warning on a save conflict."
platforms:
  - typescript
  - web
tags:
  - toolbar
  - editing-actions
  - block
depends-on: []
related:
  - 81db83fc-b30c-4ba3-b4d5-572dc8b4e335
references: []
approved-by: ""
approved-date: ""
---

# Document Save Bar

## Overview

The Document Save Bar is the editing button bar for a document managed by `useVersionedDocument`. It renders the platform's standard Button Bar with only Cancel and Save, so a document reads the same as every other editing surface. Cancel drops the draft and Save stores it. Notices sit at the bar's leading edge: the document vanished, the stored document changed underneath the draft, or a save failed. When someone else saved first, a warning below the bar offers "Reload theirs" or "Overwrite". The component holds no state of its own; every behavior is driven by the document object passed in.

## Behavioral Requirements

- **render-button-bar**: The component MUST render the standard Button Bar with the New and Delete buttons hidden, leaving Cancel and Save as the only buttons.
- **wrapper-slot**: The component MUST render a wrapper element carrying `data-slot="document-save-bar"` that holds the bar and the conflict warning.
- **accept-class-name**: The component MUST apply the `className` prop to the wrapper element.
- **cancel-enabled-by-dirty**: Cancel MUST be enabled only while the document is dirty and not saving.
- **save-enabled-by-dirty**: Save MUST be enabled only while the document is dirty and not saving.
- **cancel-reverts**: Activating Cancel MUST call the document's `revert`.
- **save-saves**: Activating Save MUST call the document's `save`.
- **saving-state**: While the document is saving, the Save button MUST read "Saving…" and be disabled, and Cancel MUST be disabled.
- **gone-notice**: When `gone` is true the component MUST show an error line reading the `gone` message, or `This {noun} no longer exists.` by default.
- **changed-notice**: When `changedElsewhere` is true and `conflict` is null the component MUST show a line in the orange warning color reading the `changedElsewhere` message, or `This {noun} changed since it was opened.` by default.
- **changed-notice-hidden-on-conflict**: When `conflict` is set the component MUST NOT show the changed-elsewhere notice, because the conflict warning replaces it.
- **save-error-notice**: When `saveError` is set the component MUST show an error line reading `Save failed: ` followed by the error text.
- **notices-leading**: The three notices MUST render in the bar's leading area, in the order gone, changed, save error.
- **error-lines-alert**: The gone and save-failed lines MUST be exposed with the alert role, through the shared error text.
- **conflict-warning**: When `conflict` is set the component MUST render a warning alert below the bar (`data-slot="document-save-conflict"`) holding the `conflict` message, or `Someone else saved this {noun}.` by default.
- **reload-theirs**: The conflict warning MUST offer a "Reload theirs" button that calls the document's `takeTheirs`.
- **overwrite**: The conflict warning MUST offer an "Overwrite" button that calls the document's `overwrite`.
- **overwrite-disabled-while-saving**: The "Overwrite" button MUST be disabled while the document is saving.
- **reload-theirs-always-enabled**: The "Reload theirs" button MUST NOT be disabled by the saving state.
- **noun-default**: `noun` MUST default to "document".
- **messages-override**: Each of `messages.gone`, `messages.changedElsewhere` and `messages.conflict` MUST replace the matching default wording when provided, whatever `noun` is.
- **no-save-result-await**: Save and Overwrite MUST be fired without the component waiting on or handling their returned promise.

## Appearance

- **Corner radius**: The bar has none; the conflict warning uses the Alert's `rounded-lg`.
- **Padding**: The bar is Button Bar's (`px-6 py-2`); the conflict warning passes `p-2`, which the class merge lets replace the Alert's own `px-4 py-3`.
- **Font**: Notices use `text-sm` (14px by Tailwind's scale); the conflict warning is `text-sm`.
- **Background**: The bar is Button Bar's recessed `bg-apt-bg`; the warning is the Alert's warning tint (`bg-apt-orange/10`).
- **Foreground/Text**: Error lines use `text-apt-red`; the changed notice uses `text-apt-orange`; the warning text is `text-apt-text`.
- **Border**: The bar has Button Bar's `border-y border-apt-border`; the warning has a 1px border `border-apt-orange/40`.
- **Shadow**: None.
- **Min/Max size**: The notice group is `flex min-w-0 flex-wrap items-center gap-2`, so notices wrap instead of overflowing; the warning is `mt-2 flex flex-wrap items-center gap-2`, so its message and buttons wrap. The two warning buttons are small (`size="sm"`), "Reload theirs" with the outline variant and "Overwrite" with the destructive variant.

## States

| State | Appearance change |
|-------|------------------|
| Clean | Cancel and Save disabled; no notices |
| Dirty | Cancel and Save enabled |
| Saving | Save reads "Saving…" and is disabled; Cancel disabled; Overwrite disabled when a conflict shows |
| Gone | Red error line in the leading area |
| Changed elsewhere | Orange notice in the leading area |
| Save failed | Red "Save failed: ..." line in the leading area |
| Conflict | Warning alert below the bar with Reload theirs and Overwrite; the changed notice is hidden |

Pressed, Focused and Loading: the Save, Cancel and warning buttons take their pressed and focus appearance from the shared Button; the component adds none. Loading is the Saving state above.

## Accessibility

- **Role**: The bar is a toolbar named "Editing actions" (from Button Bar); the gone and save-failed lines have the alert role; the conflict warning is an Alert, which has the alert role.
- **Label**: The buttons are labeled by their visible text: Cancel, Save (or Saving…), Reload theirs, Overwrite.
- **State announcements**: Because the error lines and the conflict warning carry the alert role, they are announced when they appear. The changed-elsewhere notice is a plain paragraph with no role and is not announced when it appears; the source states no reason, so whether it should be announced is open.
- **Keyboard**: All controls are native buttons reachable by Tab and activated with Enter or Space; the component adds no key handling.
- **Minimum tap target**: Cancel, Save and both warning buttons use the shared Button at `size="sm"`, which is `h-7` (28px tall) with a minimum height and width that default to 0 unless an ancestor sets `--adh-button-min-height` and `--adh-button-min-width`; the component sets neither.
- **changed-notice-announcement**: NEEDS REVIEW: Not implemented in source. The changed-elsewhere notice has no alert or status role while the gone, save-failed and conflict notices do; a decision from the design owner, checked against screen-reader behavior, would settle whether it needs a live-region role.
- **orange-text-contrast**: NEEDS REVIEW: Not implemented in source. The changed notice uses `text-apt-orange` at 14px and the source does not state its contrast against the page background; a token-pair contrast measurement in light and dark themes would settle whether it meets WCAG 1.4.3.

## Conformance Test Vectors

The tests beside the source are `documentSaveBar.test.tsx`; each vector names the test it comes from where one exists.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| save-bar-001 | render-button-bar (test: "is the standard editing button bar, with Cancel and Save and nothing else") | Clean document | A toolbar named "Editing actions" holds exactly two buttons, "Cancel" then "Save" |
| save-bar-002 | cancel-enabled-by-dirty, save-enabled-by-dirty (test: "disables Cancel and Save with nothing to save") | `dirty=false` | Save and Cancel are both disabled |
| save-bar-003 | cancel-reverts, save-saves (test: "wires Save and Cancel when dirty, and holds both while saving") | `dirty=true`; click Save, then Cancel | `save` and `revert` are each called (the test asserts called, not a count) |
| save-bar-004 | saving-state (test: same) | `dirty=true`, `saving=true` | A disabled button named "Saving…" and a disabled Cancel |
| save-bar-005 | gone-notice, noun-default, changed-notice (test: "names the document in its default notices") | `noun="note"`, `gone=true`, `changedElsewhere=true` | Alert reads "This note no longer exists."; text "This note changed since it was opened." is shown |
| save-bar-006 | messages-override (test: "takes host wording for any notice") | `changedElsewhere=true`, `messages.changedElsewhere="This file changed on disk."` | Text "This file changed on disk." is shown |
| save-bar-007 | conflict-warning, reload-theirs, overwrite, changed-notice-hidden-on-conflict (test: "offers Reload theirs and Overwrite on a conflict, and hides the changed notice under it") | `noun="file"`, `dirty=true`, `changedElsewhere=true`, `conflict={text:"t",version:"v9"}`; click Reload theirs, then Overwrite | "Someone else saved this file." shown inside an alert; no "changed since" text; `takeTheirs` and `overwrite` are each called (the test asserts called, not a count) |
| save-bar-008 | save-error-notice, error-lines-alert (test: "shows a failed save inline as an alert") | `saveError="disk full"` | One alert reading "Save failed: disk full" |
| save-bar-009 | overwrite-disabled-while-saving | `conflict` set, `saving=true` | "Overwrite" disabled; "Reload theirs" enabled |
| save-bar-010 | accept-class-name, wrapper-slot | `className="mt-4"` | The element with `data-slot="document-save-bar"` has class `mt-4` |
| save-bar-011 | conflict-warning | `conflict` null | No `data-slot="document-save-conflict"` element renders |
| save-bar-012 | notices-leading | `gone=true`, `changedElsewhere=true`, `saveError="x"` | The leading area holds, in order, the gone line, the changed line, then "Save failed: x" |
| save-bar-013 | messages-override | `noun="file"`, `messages.conflict="Taken."`, `conflict` set | The warning reads "Taken." and not "Someone else saved this file." |

## Edge Cases

- **Null and empty input**: With no `messages` prop the component MUST use the default wording built from `noun`; with `saveError` null or an empty string the save-failed line MUST NOT render (the shared error text renders nothing for a falsy error).
- **Boundary values**: A `noun` of an empty string yields notices like "This  no longer exists."; the source does not guard it, and callers SHOULD pass a non-empty noun.
- **Concurrent access**: The conflict state is the concurrency case: a conflict warning MUST replace the changed notice, and Overwrite MUST be disabled while a save is in flight so a second save cannot start from the warning. Save from the bar is disabled while saving for the same reason.
- **Error states**: A failed save shows `Save failed: ` plus the error inline and keeps the bar usable, in place of a browser alert; a missing document shows the gone notice while the draft is kept, as the hook's `gone` documents.
- **Offline or disconnected state**: The component has no network access of its own. A save that fails for network reasons arrives as `saveError`, and the component shows it with no retry control of its own; the user can press Save again while the document is still dirty.
- **Several notices at once**: Gone, changed-elsewhere and save-error MAY show together; they wrap within the leading area.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `document` | the dirty, saving, gone, changedElsewhere, conflict, saveError, save, overwrite, revert and takeTheirs members of a versioned document | required | The document, from `useVersionedDocument` |
| `noun` | string | `"document"` | What the document is called in default notices |
| `messages` | `{ gone?, changedElsewhere?, conflict? }` | `{}` | Replaces any notice's wording |
| `className` | string | none | Applied to the wrapper element |

## Deep Linking

Not applicable: the component has no routes or URLs.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| gone | `This {noun} no longer exists.` | The document was found gone while a draft existed, by a save or a reload; replaceable through `messages.gone` |
| changedElsewhere | `This {noun} changed since it was opened.` | The stored document changed while a draft existed; replaceable through `messages.changedElsewhere` |
| conflict | `Someone else saved this {noun}.` | A save lost the race; replaceable through `messages.conflict` |
| saveFailed | `Save failed: {error}` | A save failed; the prefix is fixed in source and not replaceable |
| reloadTheirs | `Reload theirs` | Conflict warning button; fixed in source |
| overwrite | `Overwrite` | Conflict warning button; fixed in source |

The Cancel, Save and Saving… labels come from Button Bar.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the component defines no animation or transition |
| Increase Contrast | The notices use fixed theme tokens (`text-apt-red`, `text-apt-orange`, `text-apt-text`) and the component defines no contrast-mode variant; the contrast of the orange pair is the open question on `orange-text-contrast` |
| Differentiate Without Color | The red and orange notices are text sentences, and the conflict warning is a sentence with two labeled buttons, so no state relies on color alone |

## Feature Flags

Not applicable: the component has no flag checks in source.

## Analytics

Not applicable: the component emits no analytics events.

## Privacy

- **Data collected**: None; it displays the save error text passed in, which comes from the caller.
- **Storage**: None.
- **Transmission**: None; save, overwrite and revert are callbacks the caller owns.
- **Retention**: None.

## Logging

Not applicable: the component writes no log output.

## Platform Notes

- **SwiftUI**: Compose an `HStack` of a leading notices `VStack` and a trailing Cancel and Save pair, with `Button(role: .destructive)` for Overwrite inside a warning-tinted `GroupBox`. Disable with `.disabled(!dirty || saving)`; swap the Save title for a `ProgressView` or "Saving…" text. Post `AccessibilityNotification.Announcement` for the gone, save-failed and conflict notices to match the alert role.
- **Compose**: A `Row` with a notices `Column` and two `TextButton`s; the conflict warning is a `Card` (tinted container color) with a `FlowRow` of the message, a `OutlinedButton` and a destructive `Button`. Use `Modifier.semantics { liveRegion = LiveRegionMode.Assertive }` on the error lines and warning to match the alert role.
- **React/Web**: The source is `packages/web/packages/ui/src/blocks/document-save-bar.tsx`, built from `ButtonBar`, `Button`, `Alert` and `ErrorText` and typed against `VersionedDocument` from `hooks/useVersionedDocument`. Tests are `packages/web/packages/ui/src/__tests__/documentSaveBar.test.tsx`.
- **AppKit / UIKit**: On AppKit use an `NSStackView` with a notices stack and `NSButton`s for Cancel and Save (key equivalent for Save is the platform convention, not set in source), and an `NSBox` for the conflict warning; post `NSAccessibility.post(element:notification: .announcementRequested)` for alert notices. UIKit: a `UIStackView` with `UIButton.Configuration` buttons and a `UIAccessibility.post(notification: .announcement, ...)` on notices.
- **WinUI 3**: Use a `Grid` with a leading `StackPanel` (or `ItemsRepeater`) of `TextBlock` notices and trailing Cancel and Save `Button`s, with `IsEnabled` bound to the dirty and saving flags and the Save `Content` switched to "Saving…". Show the conflict warning as an `InfoBar` (`Severity="Warning"`, `IsClosable="False"`, `IsOpen` bound to the conflict) whose `ActionButton` is "Reload theirs" and whose `Content` or a second button is "Overwrite" (`Style` accent or red foreground). Set `AutomationProperties.LiveSetting="Assertive"` on the error `TextBlock`s; `InfoBar` raises its own UI Automation notification. Visual states for the buttons come from the default `ButtonStyle` (Normal, PointerOver, Pressed, Disabled).

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/document-save-bar.tsx` | confirmed (1.0.0) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: Reuse the standard Button Bar with only Cancel and Save instead of drawing a custom bar.
**Rationale**: The source says a document should read the same as every other editing surface.
**Approved**: pending

**Decision**: Show save failures inline in the bar rather than in a browser alert.
**Rationale**: The source documents that the failure is "shown here rather than in a browser alert", so the message stays beside the controls that caused it.
**Approved**: pending

**Decision**: A conflict replaces the changed-elsewhere notice and puts its choices in a warning below the bar.
**Rationale**: When someone else saved first the user has a real decision (Reload theirs or Overwrite), so the weaker "changed" notice would be redundant.
**Approved**: pending

**Decision**: Wording is replaceable per notice through `messages`, with a `noun` for the defaults.
**Rationale**: A file-backed host needs different words (the source's example is "This file changed on disk.") without changing the component.
**Approved**: pending

**Decision**: Overwrite is disabled while saving, but Reload theirs is not.
**Rationale**: Overwrite starts a save and a second one must not overlap; Reload theirs discards the draft and starts no save.
**Approved**: pending

**Decision**: Save and Overwrite are fired and their promises ignored.
**Rationale**: The document object owns success and failure and reports them through `saving`, `saveError` and `conflict`, so the bar only reflects them.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | accessibility |
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | partial | internationalization |

The component holds no state and delegates every action to the document, which passes separation of concerns, and its seven tests cover the buttons, notices and conflict flow, which passes unit-test coverage. All controls are native buttons, which passes keyboard navigation. Screen-reader support is partial because the changed notice carries no live-region role. Hardcoded strings is partial because the save-failed prefix and the Reload theirs and Overwrite labels are fixed English in source, while the three notices are replaceable.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
