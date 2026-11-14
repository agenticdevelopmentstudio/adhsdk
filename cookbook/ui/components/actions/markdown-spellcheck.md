---
id: 81b8d777-f5c2-4a9a-8d5f-bbddf6e4e094
title: "Markdown Spell Check"
type: ingredient
version: 1.2.1
status: review
language: en
created: 2026-06-26
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "An off-by-default toolbar toggle that runs a markdown-aware spell/grammar check via harper.js in a popover with apply actions."
platforms:
  - typescript
  - web
tags:
  - markdown
  - spellcheck
  - grammar
  - harper
  - toolbar
depends-on:
  - f3c25236-d72f-4a7b-839a-b7f335b3acd0
  - b118c7bc-e163-40f0-bcc8-eb079e835794
related:
  - f5d2eb1c-fb0e-48e3-b124-7e730ac8231c
references:
  - https://writewithharper.com
approved-by: ""
approved-date: ""
---

# Markdown Spell Check

## Overview

A standalone editor-toolbar control in `@adh-sdk/ui`
(`components/markdown-spellcheck`) that adds an **optional**, **markdown-aware**
spelling & grammar check to a markdown editor. It is built for the
`MarkdownEditor` `toolbarExtras` slot: the consumer passes the same markdown
`value` plus an `onApply` handler, and the control renders a toggle in the
toolbar.

The check is **off by default**. The first time it is enabled, the control
lazy-loads [harper.js](https://writewithharper.com) — an offline grammar checker
whose WebAssembly runs inside a Web Worker (`WorkerLinter`), so neither the WASM
nor the worker ships on initial page load and linting never blocks the UI
thread. harper is asked to parse the input as **Markdown source**, so fenced code
blocks and markdown syntax are skipped and only prose is checked — the whole
point over the browser's native textarea spellcheck.

Problems are surfaced in a lightweight popover **panel/list** (not inline
squiggles on the textarea, which would be far costlier): each row shows the
flagged text, harper's message, and one apply-a-suggestion action per
replacement. Applying edits the markdown source through `onApply`; the panel then
re-lints. It reuses the shared `Popover` (Escape / outside-click dismissal +
focus restore) and `Button`, and holds no source of its own.

## Behavioral Requirements

- **default-off**: The control MUST render its toggle in the off state
  (`aria-pressed="false"`) and MUST NOT lint, load harper, or show the panel
  until the toggle is enabled.
- **lazy-load-harper**: The control MUST import harper.js (and its WASM) only
  the first time the check is enabled — never on initial render — and MUST reuse
  that one linter instance for the lifetime of the control.
- **use-worker-linter**: The control MUST drive harper's `WorkerLinter` (WASM
  in a Web Worker), not a main-thread `LocalLinter`, so the UI thread is not
  blocked.
- **lint-markdown-source**: The control MUST lint in markdown source mode
  (`language: 'markdown'`) so fenced code blocks and markdown syntax are skipped
  and only prose is checked.
- **list-problems**: When enabled and problems exist, the control MUST list
  each problem as the flagged text plus harper's message in the panel.
- **offer-suggestions**: For a problem that has suggestions, the control MUST
  render one apply action per suggestion, capped at the first four; applying it
  MUST call `onApply` with the next markdown source.
- **relint-on-settle**: While the panel is open, the control MUST re-lint
  when the source settles after a change, debounced so a burst of edits coalesces
  into one check.
- **show-empty-state**: When enabled and no problems are found, the control
  MUST show an explicit "No issues found." state rather than an empty panel.
- **show-error-state**: If harper fails to load or lint, the control MUST
  show an inline "unavailable" state instead of crashing.
- **reset-on-disable**: Toggling the check off MUST close the panel and clear
  the listed problems.
- **be-client-only**: The control MUST be a client component
  (`"use client"`); it MUST NOT execute harper or worker code during SSR.
- **dispose-on-unmount**: The control MUST call the linter's `dispose()` when
  the control unmounts, releasing its worker/WASM resources.
- **apply-latest-lint**: `apply` MUST resolve `issueIndex` and `suggestionIndex`
  against the results of the linter's most recently completed `lint(source)`
  call.

## Appearance

```
toolbar ─────────────────────────────────────────────
  […other controls]  [✓ Check spelling  (3)]   ← toggle Button (outline, sm);
                              │                   SpellCheck icon + label +
                              │                   count Badge (error) when open
                              ▼ on enable (popover, side=bottom align=end, w-80)
  ┌ SPELLING & GRAMMAR ───────────────────────────┐
  │ ┌───┐                                          │
  │ │teh│  Did you mean "the"?                      │  ← flagged chip (mono, red)
  │ └───┘  [✓ the]                                  │     + message + apply chips
  │ ──────────────────────────────────────────────│
  │ recieve  Did you mean "receive"?                │
  │          [✓ receive]                            │
  └────────────────────────────────────────────────┘
       states: Checking… (spinner) · No issues found. · unavailable (red)
```

- Toggle: shared `Button` via `buttonVariants({ variant: "outline", size: "sm" })`
  with a leading `SpellCheck` icon; an error-tone `Badge` shows the open problem
  count.
- Panel: the shared `PopoverContent` (`bg-apt-surface`, `border-apt-border`,
  `text-apt-text`), `w-80`, `max-h-[24rem] overflow-auto`.
- Caption: `fieldCaptionClass` (from typography utilities).
- Each problem: a `<li>` with the flagged text in a `rounded bg-apt-surface-2`
  mono chip (`text-apt-red`), the message in `text-xs text-apt-text-muted`, and
  apply chips as the shared `Button` (`variant="outline" size="xs"`) with a
  `Check` icon.
- Tokens only: `apt-*` surfaces/text/borders/semantics; no raw hex, no
  `!important`.

## States

| State | Appearance change |
|---|---|
| Off (default) | Only the outline toggle is shown (`aria-pressed="false"`); no harper, no panel in the DOM |
| Loading (first enable) | Toggle pressed; panel shows a `Spinner` + "Checking…" |
| Ready — problems | Panel lists each flagged text + message + apply chips; toggle shows an error-tone count `Badge` |
| Ready — clean | Panel shows "No issues found." |
| Re-linting | Prior list stays visible (no "Checking…" flash) until fresh results replace it |
| Error | Panel shows a red `CircleAlert` + "Spell check is unavailable in this browser." |
| Dismissed / off | Popover unmounts, focus returns to the toggle, listed problems cleared |

## Accessibility

- The toggle is a real `<button>` whose accessible name is the `label`
  (default `Check spelling`) and whose on/off state is exposed via
  `aria-pressed`.
- The panel is a shared `Popover`, so it inherits Escape + outside-click
  dismissal and focus restore to the toggle.
- The problem list is a semantic `<ul>` labelled `Spelling and grammar issues`;
  each apply action is a real `<button>` (keyboard operable) with an
  `aria-label` of the form `Replace "<flagged>" with "<suggestion>"`, so the
  action is unambiguous out of context.
- harper's `message()` is rendered as plain text (never HTML), so untrusted lint
  text cannot inject markup.
- Loading uses the shared `Spinner` (`role="status"`); the error state pairs an
  `aria-hidden` icon with literal text.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | default-off | Render with a fake linter, do not click | One button named `Check spelling` with `aria-pressed="false"`; no message/panel text in the DOM |
| T2 | default-off, lazy-load-harper | Render with a spy `createLinter`, then enable | `createLinter` is not called on render; it is called exactly once after the toggle is enabled |
| T3 | list-problems, offer-suggestions | Enable over source `"teh cat sat"` (fake flags `teh`→`the`) | The panel shows `teh`, the message, and an apply action named `Replace "teh" with "the"`; the toggle is `aria-pressed="true"` |
| T4 | show-empty-state | Enable over clean source `"the cat sat"` | The panel shows "No issues found." |
| T5 | offer-suggestions, apply-latest-lint | Enable over source with two flagged problems (`teh`, `recieve`), click the apply action for the second problem | `onApply` is called with `recieve` replaced, not `teh` — the index resolves against the latest `lint()` result |
| T6 | show-error-state | Enable with a fake `createLinter` whose returned promise rejects | The panel shows the red `CircleAlert` "Spell check is unavailable in this browser." state instead of throwing |
| T7 | reset-on-disable | Enable over source with problems, disable, then re-enable before the fake linter's `lint()` resolves | On re-enable the panel shows "Checking…", not the previously listed problems — the prior list was cleared on disable |
| T8 | relint-on-settle | Enable (immediate first lint resolves), then fire several source changes in quick succession using a spy `lint` and fake timers, then advance past `debounceMs` | `lint` is called once for the initial open and exactly once more after the timers settle — not once per change |
| T9 | lint-markdown-source, use-worker-linter | Mock the `harper.js` module import and call the exported `createHarperLinter()` directly, then call `.lint(source)` | A `WorkerLinter` is constructed (not `LocalLinter`) and its `lint` is called with `{ language: 'markdown', dedup: true }` |
| T10 | be-client-only | Import the component module in a simulated server environment (no `window`/`document`) and render without enabling | No throw, and no harper import or worker/WASM code executes |
| T11 | dispose-on-unmount | Enable with a fake linter exposing a spied `dispose`, then unmount the component | The spied `dispose()` is called exactly once |
| T12 | offer-suggestions | Enable over source flagged with an empty suggestion (`Remove` kind, `suggestions: [""]`) | The apply chip reads "Remove"; clicking it calls `onApply` with the flagged span deleted |

> Tests inject a fake `MarkdownLinter` through the `createLinter` prop so no WASM
> runs in jsdom; this also makes the lazy-load contract (T2) directly assertable.

## Edge Cases

- A problem with no suggestions renders "No suggestion." instead of apply chips
  (e.g. a flagged proper noun harper can't correct).
- A `Remove`-kind suggestion has an empty replacement; the apply chip reads
  "Remove" and applying deletes the flagged span. harper's own `applySuggestion`
  performs the edit, so `Replace` / `Remove` / `InsertAfter` kinds are all handled
  correctly (not a naive `[start,end)` splice).
- Suggestions are capped at the first four per problem to keep the panel light.
- Fenced code, inline code, and markdown punctuation are not prose, so harper's
  markdown parser does not flag them.
- Dismissing the popover (Escape / outside-click) turns the check off; re-enabling
  re-lints the current source from scratch.
- The first lint after enabling runs immediately; later re-lints debounce, so a
  fast typist triggers one check, not one per keystroke.
- If harper cannot load or lint (e.g. a worker/WASM bundling failure in the host
  app), the panel degrades to the error state instead of throwing.

## Configuration

`@adh-sdk/ui/components/markdown-spellcheck`

| Option | Type | Default | Description |
|---|---|---|---|
| `value` | `string` | — (required) | The markdown source to check |
| `onApply` | `(next: string) => void` | — (required) | Called with the next source when a suggestion is applied |
| `label` | `ReactNode` | `"Check spelling"` | Visible text / accessible name of the toggle |
| `debounceMs` | `number` | `600` | Debounce before re-linting after the source settles |
| `createLinter` | `CreateMarkdownLinter` | `createHarperLinter` | Linter factory (DI seam); inject a fake in tests |
| `disabled` | `boolean` | `false` | Disable the toggle |
| `className` | `string` | — | Extra classes on the toggle button |

```ts
export interface SpellIssue {
  start: number
  end: number
  flagged: string
  message: string
  suggestions: string[]
}

export interface MarkdownLinter {
  lint(source: string): Promise<SpellIssue[]>
  apply(source: string, issueIndex: number, suggestionIndex: number): Promise<string>
  dispose(): void
}

export type CreateMarkdownLinter = () => MarkdownLinter | Promise<MarkdownLinter>

export const createHarperLinter: CreateMarkdownLinter

export function MarkdownSpellCheck(props: {
  value: string
  onApply: (next: string) => void
  label?: React.ReactNode
  debounceMs?: number
  createLinter?: CreateMarkdownLinter
  disabled?: boolean
  className?: string
}): React.JSX.Element
```

The default `createHarperLinter` dynamically imports `harper.js` +
`harper.js/binary`, constructs a `WorkerLinter` (American dialect), and lints with
`{ language: 'markdown', dedup: true }`. The exported types never reference
harper, so consumers do not need harper resolvable to type-check.

## Deep Linking

Not applicable: this is a reusable UI primitive exported for toolbar integration and does not participate in app routing or deep linking.

## Localization

Known gap, not "not applicable": the component hard-codes its user-facing
copy — the "Checking…" loading text, "No issues found." empty state, and the
"Spell check is unavailable…" error state, plus the per-suggestion
`Replace "<flagged>" with "<suggestion>"` accessible names — with no
locale-sensitive formatting per source. Only the toggle's own text is
externalized, via the `label` prop (default `"Check spelling"`); a consumer
cannot localize the rest without editing this component.

## Accessibility Options

This control inherits focus management and keyboard dismissal from the shared
`Popover` primitive, and every interactive element is a real `<button>` with
an accessible name and `aria-pressed`/state attributes. See **default-off**,
**list-problems**, and **offer-suggestions** in Behavioral Requirements.

## Feature Flags

Not applicable: this ingredient is a reusable UI component and is not gated by feature flags.

## Analytics

Not applicable: this ingredient is presentational. Consumers may instrument toggle activation and suggestion application in their own event tracking systems; the only externally visible callback is `onApply`.

## Privacy

Not applicable: harper.js lints entirely client-side (see **use-worker-linter**), so the component makes no network calls and collects or stores no data of its own; it only holds the `value` source string and reports edits back through `onApply`.

## Logging

Not applicable: This control is presentational and emits no structured log events. Enabling,
dismissing, and applying a suggestion are local UI interactions; only the applied
source change is reported to the consumer (`onApply`). A harper load/lint failure
is surfaced to the user via the error state rather than logged.

## Platform Notes

- **SwiftUI**: Render the toggle as a `Button` driving `@State private var isOpen`, presenting the panel via `.popover(isPresented: $isOpen)` (side/alignment via `attachmentAnchor`). Lazy-load the checker only in the `.popover`'s `onAppear`/the toggle's `onChange` — never at view init — and keep one instance for the view's lifetime, releasing it in `.onDisappear` (mirrors lazy-load-harper and dispose-on-unmount). Inside, a `List` (or `VStack` for a short list) of flagged text + message + one `Button` per suggestion realizes list-problems/offer-suggestions; a `ProgressView` covers the loading state, a `Text("No issues found.")` the empty state, and a `Label` with a warning `Image(systemName:)` the error state. SwiftUI has no markdown-aware spellcheck API of its own; a `TextEditor`/`TextField` inherits the system's built-in checking (`NSSpellChecker`-backed on macOS via the underlying `NSTextView`, the system checker via `UITextView` on iOS). To replicate harper's markdown-aware filtering, iterate the document to identify prose-only ranges (excluding code blocks and markup) and drive the system checker over those ranges in isolation.
- **Compose**: Render the toggle as a `Button`/`IconToggleButton` driving `var expanded by remember { mutableStateOf(false) }`, presenting the panel via `DropdownMenu`/`Popup` anchored to the toggle. Lazy-load the checker in a `LaunchedEffect(expanded)` guarded on `expanded`, keyed so it runs at most once, and cancel/release it in `DisposableEffect`'s `onDispose` (lazy-load-harper, dispose-on-unmount). Inside, a `Column` of flagged text + message + a `Button`/`AssistChip` per suggestion realizes list-problems/offer-suggestions; a `CircularProgressIndicator` covers loading, a `Text` the empty state, and a `Text` with an error `Icon` the error state. Jetpack Compose has no Compose-native spellcheck API; the platform's checker is reached through the View-based `TextServicesManager` / `SpellCheckerSession` that backs `BasicTextField`'s `InputConnection`, not through a Compose call. To replicate markdown-aware filtering, iterate over the document range and identify prose sections (excluding code blocks and markup) before submitting them to a `SpellCheckerSession`.
- **React/Web (TypeScript)**: Component at
  `packages/web/packages/ui/src/components/markdown-spellcheck.tsx`, exported from
  `@adh-sdk/ui/components/markdown-spellcheck`. Built on the shared `Popover`,
  `Button`, `Badge`, and `Spinner` components. harper.js is a dependency of `@adh-sdk/ui`,
  marked `external` in `tsup.config.ts` so the dist re-emits the dynamic
  `import('harper.js')` verbatim and the **consumer's** bundler (Next.js)
  code-splits and lazy-loads the WASM binary. Consumed by hub's `ResearchDetail` (in the
  `MarkdownEditor` `toolbarExtras` slot). Demo lives in `ui-showcase` (Overlays
  group); regenerate `sources.generated.ts` via `gen-sources.py` after source changes.
- **AppKit / UIKit**: On AppKit, back the toggle with an `NSButton` presenting an `NSPopover` (an `NSViewController` whose view lays out an `NSTableView`/`NSStackView` of flagged text + message + one `NSButton` per suggestion). On UIKit, back it with a `UIButton` presenting a `UIViewController` via popover presentation (`UIPopoverPresentationController`) laying out a `UITableView`/stack the same way. Lazy-load the checker only when the popover/view controller is first presented, keep one instance for the control's lifetime, and release it when it's dismissed for good (lazy-load-harper, dispose-on-unmount). An `NSProgressIndicator`/`UIActivityIndicatorView` covers loading, a label the empty state, and a label paired with a warning glyph the error state. macOS and iOS apps implement native spell-check using `NSSpellChecker` (macOS) or `UITextChecker` (iOS). To apply markdown-aware filtering (skipping code blocks and markup), iterate the document to identify prose-only ranges and spell-check those ranges in isolation.
- **WinUI 3**: Back the toggle with a `ToggleButton` presenting the panel via a `Flyout`/`FlyoutPresenter` anchored to it, containing a `ListView` of flagged text + message + one `Button` per suggestion (list-problems/offer-suggestions). Lazy-load the checker only when the `Flyout` is first opened (its `Opened` event), keep one instance for the control's lifetime, and release it on unload (lazy-load-harper, dispose-on-unmount). A `ProgressRing` covers loading, a `TextBlock` the empty state, and a `TextBlock` paired with a warning `FontIcon` the error state. Windows desktop applications use `TextBox` with `IsSpellCheckEnabled` set to `true`, or `RichEditBox` with spell-checking enabled, for the underlying check. To replicate the markdown-aware exclusion of code blocks and markdown syntax, implement a custom spell-check pass: parse the document to identify prose sections (exclude fenced code blocks, inline code, and markdown markers), then iterate over those prose ranges and invoke the platform spell-checker for each range, similar to harper.js's markdown source mode.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/markdown-spellcheck.tsx` | unverified |

## Design Decisions

- **Decision**: A popover panel/list, not inline squiggles on the textarea.
  **Rationale**: Per-character overlay positioning over a `<textarea>` is costly
  and brittle; a list of problems with explicit apply actions is cheaper, more
  accessible, and matches the "lightweight panel" brief.
  **Approved**: pending
- **Decision**: harper's `WorkerLinter`, lazy-loaded on first enable.
  **Rationale**: The WASM is multi-MB; keeping it off the initial bundle and off
  the UI thread (a Web Worker) is essential. Loading only when the user opts in
  honors the opt-in principle.
  **Approved**: pending
- **Decision**: Markdown source mode (`language: 'markdown'`).
  **Rationale**: The reason to add this over native spellcheck is to skip code
  blocks and markdown syntax and check only prose.
  **Approved**: pending
- **Decision**: A `createLinter` DI seam with a harper-free public type surface.
  **Rationale**: Tests inject a fake (no WASM in jsdom) and the lazy contract is
  assertable; keeping harper out of the exported `.d.ts` means consumers need not
  resolve harper to type-check.
  **Approved**: pending
- **Decision**: harper's own `applySuggestion` performs edits.
  **Rationale**: It handles `Replace` / `Remove` / `InsertAfter` suggestion
  kinds correctly, which a naive substring splice would not.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.focus-management](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/eec52703-a32a-5dee-b763-59a3bac826ea) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | partial | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

`screen-reader-support` and `keyboard-navigable` pass because the toggle and every
apply action are real `<button>` elements with an accessible name (`aria-label`,
including the per-suggestion `Replace "<flagged>" with "<suggestion>"` form) and
`aria-pressed` state. `focus-management` passes because the panel is the shared
`Popover`, which supplies Escape/outside-click dismissal and focus restore to the
toggle. `semantic-markup` passes because the problem list is a labelled `<ul>` of
`<li>` rows with a real `aria-hidden` error icon. `contrast-ratio` and
`touch-target-size` are partial because the source uses only `apt-*` tokens and the
shared `Button`'s size variants, but the actual contrast values and pixel
dimensions are defined outside this file. `no-hardcoded-strings` fails because
"Checking…", "No issues found.", and the "Spell check is unavailable…" copy are
literal English strings with no i18n layer; `string-externalization` is partial
because the toggle's own label is externalized via the `label` prop but those
other strings are not. Security, Privacy and Data, and User Safety are omitted:
the component makes no network calls (harper runs offline), stores/collects no
data of its own, and produces no logs (see Logging above). `separation-of-concerns`
passes because the component isolates harper behind the `MarkdownLinter`/
`CreateMarkdownLinter` DI seam, so the UI never references harper directly and
a fake linter can stand in for tests. `unit-test-coverage` passes because
`markdownSpellcheck.test.tsx` covers the off-by-default toggle, lazy linter
creation, linting and listing problems, the empty state, and applying a
suggestion.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.2.1 | 2026-09-25 | Mike Fullerton | Restored 1.0.0 period; added 6 missing sections, fixed Decision triples, best-practices rows. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: rename requirements to subject-only kebab names (RFC 2119 keyword stays in the sentence); cap offer-suggestions at four in the requirement text; add dispose-on-unmount and apply-latest-lint requirements; add test vectors for show-error-state, reset-on-disable, the relint-on-settle debounce, lint-markdown-source/use-worker-linter, be-client-only, dispose-on-unmount, and the Remove-kind edge case; correct Platform Notes (drop the discontinued Grammarly SDK and the non-existent UITextInputDelegate/EditText spell-check APIs) and map the toggle/lazy-load/popover-panel/empty-error-state contract onto each platform's native popover-presentation control; replace the Compliance table with real accessibility/internationalization checks; add Approved lines to Design Decisions; trim tags to five; drop the duplicate markdown-editor related entry; shorten the summary; name gen-sources.py in the React/Web note |
| 1.1.1 | 2026-09-22 | Claude Haiku 4.5 | Remove "Not applicable" phrasing from Platform Notes; add concrete guidance for markdown-aware filtering on all platforms (SwiftUI, Compose, AppKit/UIKit, WinUI 3 with TextBox/RichEditBox and document range iteration) |
| 1.1.0 | 2026-09-22 | Claude Haiku 4.5 | Revise recipe: fix frontmatter URIs (agenticdevelopercookbook), restructure Platform Notes to cover all five platforms (all marked Not applicable except React/Web), fix Logging section format, promote to review status |
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial recipe for the shared markdown spell/grammar-check toolbar control (harper.js WorkerLinter), contract c12. |
