---
id: ecaba9e2-de10-45ac-80d8-398e9ab02626
title: CopyButton
domain: adhsdk://recipes/copy-button
type: ingredient
version: 1.2.1
status: review
language: en
created: '2026-07-03'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A clipboard icon button on the shared Button + useClipboard; copies getText() resolved at click, flashes an apt-green check for 1200ms, silent on failure."
platforms:
- typescript
- web
tags:
- component
- clipboard
- copy
- button
- ui
depends-on:
- adhsdk://recipes/button
related: []
references: []
approved-by: ''
approved-date: ''
---

# CopyButton

## Overview

The shared `CopyButton` in `@adh-sdk/ui` — the one "copy this" affordance across
every adh site. It is a small icon button that, on click, resolves a `getText()`
thunk and writes the result to the clipboard, then flashes a success check for a
short window. It composes two shared parts rather than re-implementing either: the
family `Button` (`variant="outline"`, `size="icon"`, shrunk to `size-6`) for the
chrome and press feel, and the `useClipboard` hook for the write + transient
`copied` flag. `useClipboard` is a small internal hook, not independently
catalogued in this cookbook, so it has no domain of its own to list under
`depends-on`.

The payload is a function, not a string: `getText()` runs at click time, so the
copied text reflects the current filter or selection even if the underlying rows
changed since render. If `getText()` returns an empty string, nothing is copied.
Clipboard failures — an insecure context, or a denied permission — are swallowed
inside `useClipboard`, so a copy that cannot happen is a silent no-op rather than an
error.

A single export ships from `@adh-sdk/ui/components/copy-button`: the `CopyButton`
component. It carries `"use client"` (clipboard access + the `copied` state) and is
fully self-driving — the only inputs are `getText`, the `label`, and an optional
`className`.

## Behavioral Requirements

- **copies-gettext-at-click**: The component MUST call `getText()` when clicked and write its result to the clipboard via `navigator.clipboard.writeText`.
- **reflects-current-selection**: Because it invokes `getText()` only on click, the component MUST copy the text current at the moment of the click, not a value captured at render.
- **skips-empty-text**: When `getText()` returns the empty string `""`, the component MUST NOT write to the clipboard and MUST NOT flash success. `getText()`'s result is used as a JavaScript truthiness check (`if (text)`), not trimmed, so a whitespace-only string (e.g. `" "`) is truthy and MUST be copied normally — only the exact empty string counts as "nothing to copy".
- **flashes-success-check**: On a successful copy, the component MUST swap the clipboard glyph for a check icon and tint it `apt-green`.
- **idle-title-from-label**: While idle (no active success flash), the component MUST set its `title` to the current value of `label`.
- **sets-copied-title**: On a successful copy, the component MUST set its `title` to `"Copied!"`.
- **reverts-after-timeout**: The component MUST revert the check, the green tint, and the title back to the idle state 1200 ms after a successful copy.
- **swallows-copy-failure**: When the clipboard write rejects (insecure context or denied permission), the component MUST NOT enter the success state and MUST NOT throw.
- **labels-from-prop**: The component MUST expose `label` as its accessible name via `aria-label`.
- **decorative-icon**: The component MUST mark its glyph `aria-hidden` so the accessible name comes solely from `label`.
- **forwards-classname**: The component MUST merge a consumer `className` onto the button element via `cn()`.

## Appearance

```
idle       [ ⧉ ]   outline square, muted clipboard glyph        title = label
success    [ ✓ ]   apt-green check, title "Copied!"  (1200 ms)  then reverts
```

- Chrome: the shared `Button` with `variant="outline"` and `size="icon"`, overridden
  down to `size-6` (a 24px square) via `className` so it sits inline beside text or a
  label without dominating.
- Idle glyph: the lucide `Copy` icon, tinted `text-apt-text-muted`.
- Success glyph: the lucide `Check` icon, tinted `text-apt-green`.
- Colors are token-based (`apt-text-muted`, `apt-green`) and merge through `cn()`; no
  raw hex, no `!important`.

## States

| State | Appearance change |
|---|---|
| Idle | `Copy` glyph, `text-apt-text-muted`; `title` = `label` |
| Hover / focus | Inherited from `Button` outline: background lift + focus-visible ring |
| Pressed | Inherited from `Button`: subtle dip/darken on `data-pressed` |
| Success (0–1200 ms after copy) | `Check` glyph, `text-apt-green`; `title` = `"Copied!"` |
| Empty / failed click | No visible change — the click is a no-op |

## Accessibility

- The button always carries an accessible name: `aria-label={label}`. Because the
  glyph is `aria-hidden`, the name comes solely from `label` and never leaks the icon.
- It renders a real `<button type="button">` (through `Button`), so it is focusable
  and operable by Enter/Space, with the family focus-visible ring.
- `title` mirrors `label` at idle and becomes `"Copied!"` on success — a supplemental
  hover tooltip, not the accessible name (which stays `label` throughout).
- Success is signalled by more than color for sighted users: the glyph changes
  (`Copy` → `Check`) and the `title` changes to `"Copied!"`, so the affirmation is not
  conveyed by the green tint alone.
- The success state change is not actively announced to screen reader users: there is
  no `aria-live` region, and the accessible name (`aria-label`) never changes — it
  stays `label` throughout, including during the success flash. A screen reader user
  who clicks the button does not receive an equivalent affirmation to the glyph swap
  a sighted user sees.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | copies-gettext-at-click, labels-from-prop | render `<CopyButton getText={() => "rows"} label="Copy rows" />`, click the button | `navigator.clipboard.writeText` called with `"rows"`; button's accessible name is `"Copy rows"` |
| T2 | flashes-success-check, sets-copied-title | after a successful click (T1) | button `title` becomes `"Copied!"`; glyph is the `Check` icon |
| T3 | skips-empty-text | `getText={() => ""}`, click | `writeText` NOT called; no success flash |
| T4 | reverts-after-timeout, idle-title-from-label | after a successful copy, advance 1200 ms | `title` returns to `label`; glyph reverts to `Copy` |
| T5 | swallows-copy-failure, idle-title-from-label | `writeText` rejects, click | no success state; no error thrown; `title` stays `label` |
| T6 | reflects-current-selection | `getText` reads a variable mutated between render and click | `writeText` receives the value current at click, not at render |
| T7 | decorative-icon, labels-from-prop | render `<CopyButton getText={…} label="Copy" />` | rendered svg glyph carries `aria-hidden`; accessible name is `"Copy"` |
| T8 | forwards-classname | `className="ml-2"` | button element carries the `ml-2` class |
| T9 | reverts-after-timeout | after a successful copy, click again (also successful) at 1000 ms, before the first timer fires | the check persists until 2200 ms from the second click (timer is cleared and re-armed), not 1200 ms from the first |
| T10 | reverts-after-timeout | unmount the component before the 1200 ms timer fires | the pending timer is cleared on cleanup; no state update occurs after unmount |

## Edge Cases

- `getText()` returning `""` is the sanctioned "nothing to copy" signal — the host
  need not conditionally render the button; the click simply does nothing. A
  whitespace-only string is not treated as empty (see `skips-empty-text`).
- Clipboard write failure (insecure `http://` context, or a denied `clipboard-write`
  permission) is caught inside `useClipboard`, which resolves `false` and leaves
  `copied` false — the button stays idle with no error surfaced.
- Rapid re-clicks each reset the 1200 ms timer (`clearTimeout` then re-arm), so the
  check persists 1200 ms from the most recent successful copy, not the first (T9).
- Unmounting mid-flash is safe: `useClipboard` clears any pending timer on cleanup, so
  there is no state update after unmount (T10).
- The text is resolved lazily, so a stale render never copies stale data — the
  payload always reflects state at the instant of the click.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `getText` | `() => string` | required | Produces the text to copy, evaluated at click time; return `""` to copy nothing. |
| `label` | `string` | required | Accessible name (`aria-label`) and the idle hover `title`. |
| `className` | `string` | — | Extra classes merged onto the button via `cn()` (e.g. spacing). |

The 1200 ms success window and the outline/icon/`size-6` chrome are fixed by the
component and are not exposed as props — see Design Decisions.

## Deep Linking

Not applicable. The component is a stateless icon button with no navigation logic or route parameters; deep linking is not relevant to a presentational control.

## Localization

The success title `"Copied!"`, set on the `title` attribute in the `CopyButton`
component (`copy-button.tsx`), is a hard-coded, user-visible string — a hover
tooltip a user actually reads, not an internal technical value, so it is not exempt
from translation. The component exposes no way to localize or override it: a
consumer can localize the idle state via the `label` prop, but the success-state
title is fixed regardless of locale. This is a real gap for a fully localized
deployment (see Compliance); closing it would mean externalizing `"Copied!"` or
exposing it as an optional prop.

## Accessibility Options

Not applicable. The component does not respond to system accessibility preferences like Reduce Motion or Increase Contrast; it inherits focus styling from the shared `Button` component but does not implement motion reduction or contrast customization.

## Feature Flags

Not applicable. The component has no conditional behavior, build variants, or A/B testing paths; it is always enabled and its behavior is fully specified by its requirements.

## Analytics

Not applicable. The component is a presentational affordance with no built-in telemetry (as stated in Logging). Analytics instrumentation is the responsibility of the consumer application.

## Privacy

Not applicable. The component does not collect, store, or transmit any data; it only reads from `getText()` at click time and writes to `navigator.clipboard`, both of which are caller-managed and session-local.

## Logging

No logging. `CopyButton` is a presentational affordance; what a given copy means, and
any telemetry around it, belong to the consumer that supplies `getText`, not the
button.

## Platform Notes

- **SwiftUI**: A Swift equivalent would compose the native `Button` with a clipboard
  write. SwiftUI has no built-in clipboard API; use `NSPasteboard.general.setString(_:forType:)`
  (macOS) or set `UIPasteboard.general.string` (iOS). Writing requires no app
  entitlement on either platform — the iOS 16+ system paste-permission prompt applies
  only when *reading* another app's pasteboard content, not when writing. The 1200ms
  flash pattern and glyph swap work identically via `@State` transitions.
- **Compose (Android)**: Use `IconButton` in Material 3 Compose, paired with
  `LocalClipboardManager.current.setText(...)` for the write. The lazy text
  resolution pattern (`getText` thunk) maps cleanly to a lambda. Success state and
  icon swap work via `remember { mutableStateOf() }`. Writing via `ClipboardManager`
  requires no runtime permission on modern Android.
- **React/Web**: Source files `packages/web/packages/ui/src/components/copy-button.tsx` and hook `packages/web/packages/ui/src/hooks/useClipboard.ts`. The component carries `"use client"` directive (reads `navigator.clipboard` and holds transient `copied` state). Composes the shared `Button` (variant="outline", size="icon", overridden to size-6) and lucide `Copy`/`Check` icons. Demo available in `ui-showcase` Topic "copy-button" under "Composite controls" group (regenerate `sources.generated.ts` via `gen-sources.py` after source changes).
- **AppKit / UIKit**: `NSButton` (macOS) or `UIButton` (iOS) styled with outline
  appearance and a smaller icon size. Clipboard write via
  `NSPasteboard.general.setString(_:forType:)` (macOS) or `UIPasteboard.general.string`
  (iOS). Implement the 1200ms timer with `Timer.scheduledTimer` or
  `DispatchSourceTimer`. Writing requires no entitlement or permission on either
  platform; only *reading* another app's pasteboard content triggers the iOS 16+
  user-facing paste prompt, which does not apply here.
- **WinUI 3**: Use `Button` with `IconSource` (lucide or Segoe Fluent icon assets for
  `Copy` → `CheckMark` swap). Clipboard write via
  `Windows.ApplicationModel.DataTransfer.Clipboard.SetContent(DataPackage)` — put the
  text on a `DataPackage` via `SetText()` and pass it to `SetContent`; there is no
  `Clipboard.SetTextAsync()` API. The 1200ms revert uses `DispatcherTimer`. Clipboard
  writes require no declared capability in either the packaged (UWP) or unpackaged
  (Win App SDK) model.

## Design Decisions

- **Decision**: Take `getText`, not `text`.
  **Rationale**: A thunk resolves the payload at click time, so the copied text
  reflects the current filter/selection instead of a value frozen at render — the
  reason this affordance can sit next to a live, filtered table.
  **Approved**: pending

- **Decision**: Empty string means nothing copied.
  **Rationale**: `getText` signals "nothing to copy" by returning `""`, keeping the
  enabled/no-op decision inside the component so hosts never wrap it in a visibility
  conditional.
  **Approved**: pending

- **Decision**: Fail silently on clipboard errors.
  **Rationale**: `useClipboard` swallows write failures (insecure context, denied
  permission); a copy affordance that cannot copy simply does nothing rather than
  throwing or alarming the user.
  **Approved**: pending

- **Decision**: Compose the shared `Button` and `useClipboard` rather than a bespoke
  implementation.
  **Rationale**: Every "copy this" control is one component built on the family
  `Button` (outline/icon) and the shared hook, so styling and behavior stay identical
  everywhere instead of drifting per call site.
  **Approved**: pending

- **Decision**: Fix the success window at 1200 ms.
  **Rationale**: The success window is a deliberate constant (shorter than
  `useClipboard`'s 1500 ms default) so the check reads as a quick affirmation, not a
  lingering state; it is not a prop, to keep the feel consistent across call sites.
  **Approved**: pending

- **Decision**: Override the icon size to `size-6` instead of `Button`'s default.
  **Rationale**: The button overrides `Button`'s `size-8` icon square down to
  `size-6` (24px) so the control sits inline beside text or a label without
  dominating the row.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Statuses rest on the source: the real `<button type="button">` (via `Button`) and
`aria-label={label}` ground the passed accessibility checks, and
`navigator.clipboard.writeText` operating on an arbitrary string grounds the Unicode
pass; the absent `aria-live` announcement of the success state and the token-based
(non-literal) colors, whose rendered contrast the source cannot show, ground the two
partials; the `size-6` (24px) override of `Button`'s icon square grounds the
touch-target failure; and the hard-coded `"Copied!"` string in `copy-button.tsx`
grounds both internationalization failures. `separation-of-concerns` passes:
`copy-button.tsx` holds only the presentational `Button` wiring, while the
clipboard-write-and-flash logic lives entirely in the generic `useClipboard`
hook, which carries no knowledge of this component. `unit-test-coverage`
fails — no test file in the `ui` package exercises `CopyButton` or
`useClipboard`.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Restored on-main 1.0.0 Change History row (authorized); added missing separation-of-concerns/unit-test-coverage Compliance rows. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: correct Platform Notes clipboard-permission/API claims and reorder to SwiftUI/Compose/React-Web/AppKit-UIKit/WinUI-3; rewrite Localization to acknowledge the hard-coded, user-visible "Copied!" title and cite the symbol instead of a line number; reformat Design Decisions into Decision/Rationale/Approved triplets; rebuild Compliance as catalog-linked checks (passed/partial/failed) with a grounding sentence; add the idle-title-from-label requirement and T9/T10 test vectors, and clarify skips-empty-text for whitespace-only text; note why useClipboard has no depends-on entry; rename the 1.0.0 summary to "Initial ingredient". |
| 1.1.0 | 2026-09-22 | Claude Haiku 4.5 | Add missing template sections (Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, Privacy); expand Platform Notes with concrete guidance for all platforms; update domain and depends-on URIs to canonical agenticdevelopercookbook namespace; mark status review. |
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents the clipboard CopyButton on shared Button + useClipboard. |
