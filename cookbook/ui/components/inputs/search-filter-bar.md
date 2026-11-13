---
id: c57b1aed-ef38-4803-b38a-2d7e0aeced5f
title: "SearchFilterBar"
type: ingredient
version: 1.3.2
status: review
language: en
created: 2026-06-26
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A role=search bar combining a labelled search field with a configurable row of controlled filter selects above a list; option sets are caller-supplied."
platforms:
  - typescript
  - web
tags:
  - search
  - filter
  - input
  - select
  - toolbar
depends-on:
  - 0f5b7167-b375-4f44-977b-566f720a453d
  - fba584ed-a87c-4223-a4a9-de9c6dd342d3
related: []
references: []
approved-by: ""
approved-date: ""
---

# SearchFilterBar

## Overview

A search-and-filter bar in `@adh-sdk/ui` that sits above a list. It combines a
single icon-led search `Input` with a configurable row of filter `Select`s. Every
axis is **fully controlled** by the caller (value + `onChange`), and the option
sets for each select are supplied by the caller — so narrowing the list (which
typically refetches the rows) never empties a dropdown of its own options.

It is the single home for the "search + filters above a list" pattern. First
consumer: the hub `/research` document list (`ResearchFilters` is a thin domain
adapter that maps its `{ q, category, tag }` state onto this component).

## Behavioral Requirements

- **search-region-wrapper**: The SearchFilterBar MUST render its controls
  inside a single element with `role="search"`.
- **search-field-control**: The SearchFilterBar MUST render the search field
  as a controlled `type="search"` input bound to `search.value`, calling
  `search.onChange` with the new string on every keystroke.
- **search-field-label**: The SearchFilterBar MUST expose `search.label` as
  the search field's accessible name (the field is icon-only, with no visible
  label).
- **one-select-per-filter**: The SearchFilterBar MUST render exactly
  one `Select` per entry in `filters`, each labelled by its `label`, in the given
  order, with a leading all-pass option whose value is the empty string and whose
  text is `allLabel`.
- **filter-options-list**: The SearchFilterBar MUST render each filter's
  `options` (in order) as `<option>`s after the all-pass entry. A bare string
  option MUST be used as both the value and the visible text; a
  `{ value, label }` option MUST store `value` and read as `label`. The two forms
  MUST be mixable on one axis.
- **filter-value-sync**: The SearchFilterBar MUST set each
  select's current value from the filter's `value` and call that filter's
  `onChange` with the newly selected value (the empty string when the all-pass
  entry is chosen).
- **filter-row-children**: The SearchFilterBar MUST render
  `children` in the filter row, after any `filters`, so a caller-supplied control
  is one more axis on the same row rather than a second bar.
- **filter-row-omitted-when-empty**: The SearchFilterBar MUST NOT render the filter
  row when it would be empty — no `filters` and no `children` that React would
  actually render (a `false`/`null` child does not open the row).
- **orientation-layout**: The SearchFilterBar MUST stack the filter row
  under the search field by default (`orientation="stacked"`), and MUST lay the
  field and the row out as one wrapping line when `orientation="inline"`, the
  search field taking the free space with a minimum width of its own.
- **autofill-form-scope**: The SearchFilterBar MAY root itself on a
  `<form>` instead of a `<div>` when `asForm` is set, carrying `role="search"`
  onto that element and cancelling its `submit`. It MUST default to the `<div>`.

## Appearance

```
role="search"
┌──────────────────────────────────────────────┐
│ (search)  Search documents…                    │   <- Input (type=search), icon inset
└──────────────────────────────────────────────┘
┌─────────────────────┐ ┌─────────────────────┐
│ All categories    v │ │ All tags          v │   <- one Select per filter, in a row
└─────────────────────┘ └─────────────────────┘
```

- Root: `flex flex-col gap-2` when stacked, `flex flex-wrap items-center gap-2`
  when inline (+ any `className`), `role="search"` — on a `<div>`, or on a
  `<form>` when `asForm` is set.
- Search: the shared `Input` (`type="search"`, `className="pl-8"`) with a
  `lucide-react` `Search` icon absolutely positioned at the left
  (`absolute top-1/2 left-2.5 size-3.5 -translate-y-1/2 text-apt-text-muted`,
  `aria-hidden`, `pointer-events-none`).
- Filter row: `flex gap-2`, each child the shared `Select` (full-width, so two
  selects share the row evenly and stack gracefully on narrow viewports),
  followed by any `children`.
- Inline only: the search field's wrapper takes `min-w-48 flex-1` — a bare
  `flex-1` would let an empty field collapse to its icon, since a flex item's
  floor is its content width and an empty search box has none.
- Colors are inherited from the `Input`/`Select` primitives — `apt-*` tokens only,
  no raw hex, no `!important`.

## States

| State | Appearance change |
|---|---|
| Default | Search empty (placeholder shown); each select on its all-pass option |
| Search focused | `Input` gold focus ring (`focus-visible:ring-apt-gold/25`) |
| Filter active | Select shows the chosen option's label |
| Filter focused | `Select` gold focus ring |
| No filters configured | Only the search field renders; no filter row |
| Disabled (per-primitive) | Inherited `Input`/`Select` disabled styling if the caller disables the underlying controls |

## Accessibility

- The container is a `role="search"` landmark region, optionally named by
  `aria-label` — recommended when a page carries more than one search region.
  `asForm` moves that role onto a `<form>`, which changes nothing for assistive
  tech: a `<form>` is a landmark only once it is named, and this one's name and
  role are the region's.
- The search field is labelled by `search.label` via `aria-label` (icon-only, no
  visible `<label>`), and is a `type="search"` box (`role="searchbox"`).
- Each filter `Select` is labelled by its `label` via `aria-label`.
- The decorative search icon is `aria-hidden` and not focusable.
- All controls are native, so keyboard operability and focus order are inherited
  from the platform.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | search-region-wrapper | Render with only `search` | A single `role="search"` element wraps the controls |
| T2 | search-field-control, search-field-label | `search.label="Search documents"`; type `agents` | `getByRole("searchbox", { name: "Search documents" })` resolves; `onChange("agents")` fires |
| T3 | filter-row-omitted-when-empty | Render with no `filters` | No `combobox`/select is present |
| T4 | one-select-per-filter, filter-options-list | Two filters (`category` opts `[Agents, Retrieval]`, `tag` opts `[rag]`) | Two labelled selects; `category` lists `All categories`, `Agents`, `Retrieval` (in order); `tag` lists `All tags`, `rag` |
| T5 | filter-value-sync | `category.value="Agents"`; select `Retrieval` | Select shows `Agents` initially; `category.onChange("Retrieval")` fires |
| T6 | filter-value-sync | `category.value="Agents"`; choose `All categories` | `category.onChange("")` fires |
| T7 | filter-options-list | One axis, `options: [{ value: "st-1", label: "Todo" }, { value: "st-2", label: "Done" }]`; select `Done` | Options read `Todo`/`Done` and none reads `st-1`; `onChange("st-2")` fires |
| T8 | filter-options-list | One axis, `options: ["Backlog", { value: "it-1", label: "Sprint 3" }]` | Option `Backlog` has value `Backlog`; option `Sprint 3` has value `it-1` |
| T9 | filter-row-children, filter-row-omitted-when-empty | One filter plus a `<button>Platforms</button>` child; then the same child with no filters; then `{false}` as the only child | Button and select share one row; the child alone still draws the row; `{false}` draws no row (one child element under the root) |
| T10 | orientation-layout | Render default, then rerender `orientation="inline"` | Root has `flex-col` by default; inline drops it for `flex-wrap`, and the field wrapper carries `flex-1 min-w-48` |
| T11 | autofill-form-scope | Render default, then rerender `asForm` | Root is a `DIV`, then a `FORM`; exactly one `role="search"` either way; `fireEvent.submit` on the form reports the event cancelled |
| T12 | filter-value-sync | `category.value` set to a value absent from `category.options` (e.g. after the option universe changed) | The select's displayed option is the all-pass entry (index 0) even though `category.value` is still the stale, unmatched string; no `onChange` fires until the user picks something |

## Edge Cases

- **Empty option list**: a filter with `options: []` still renders its all-pass
  option, so the select is never empty.
- **Stale selected value**: if a filter's `value` is not present in `options`, the
  underlying React-controlled `<select>` cannot render a selection that isn't one
  of its options — it displays the first option (the all-pass entry) instead,
  while `value` (and the caller's state) still holds the stale, unmatched string.
  This is misleading: the control *looks* reset to "all", but the caller's filter
  is still narrowed by the old value. The caller owns keeping `value` within the
  option universe (e.g. the research pane sources options from the *unfiltered*
  document universe for this reason). See **T12**.
- **Search-only bar**: omit `filters` (or pass `[]`) for a bare search field.
- **Duplicate option strings**: the React key for each `<option>` is `value` (not
  `label`), so the caller must pre-dedupe by value before passing `options` —
  two options that share a value collide on that key, even if their labels
  differ.

## Configuration

`@adh-sdk/ui/components/search-filter-bar`

| Option | Type | Default | Description |
|---|---|---|---|
| `search` | `SearchFieldConfig` | — (required) | The search field config (see below) |
| `filters` | `FilterSelectConfig[]` | `[]` | Filter selects rendered in the filter row |
| `orientation` | `"stacked" \| "inline"` | `"stacked"` | Filter row under the field, or one wrapping line with it |
| `children` | `React.ReactNode` | — | Extra filter controls, rendered in the row after `filters` |
| `asForm` | `boolean` | `false` | Root on a `<form>` (submit cancelled) rather than a `<div>`, to scope autofill |
| `className` | `string` | — | Extra classes on the `role="search"` root |
| `aria-label` | `string` | — | Accessible name for the `role="search"` landmark |

```ts
interface SearchFieldConfig {
  value: string                       // controlled text
  onChange: (value: string) => void   // called per keystroke
  label: string                       // accessible name (icon-only field)
  placeholder?: string
  onKeyDown?: (e: React.KeyboardEvent<HTMLInputElement>) => void
}

interface FilterSelectOption {
  value: string                       // what the axis stores and reports
  label: string                       // what the option reads as
}

interface FilterSelectConfig {
  name: string                        // stable React key / axis id
  label: string                       // accessible name for the select
  value: string                       // selected value ("" = all-pass)
  options: readonly (string | FilterSelectOption)[]  // bare string = value is the text
  allLabel: string                    // text of the leading all-pass option
  onChange: (value: string) => void   // called with the new value ("" = all-pass)
}

interface SearchFilterBarProps {
  search: SearchFieldConfig
  filters?: FilterSelectConfig[]
  orientation?: "stacked" | "inline"
  children?: React.ReactNode
  asForm?: boolean
  className?: string
  "aria-label"?: string
}
export function SearchFilterBar(props: SearchFilterBarProps): React.ReactElement
```

## Deep Linking

Not applicable: this is a presentational component with no associated document or state to link to. Deep linking is the responsibility of the consuming feature.

## Localization

Not applicable: the component itself defines no user-facing strings. The search placeholder, filter labels, and all-pass option text are supplied by the caller as part of the component configuration and are localized at the point of use.

## Accessibility Options

Not applicable: accessibility preferences (Reduce Motion, Increase Contrast, Differentiate Without Color) are handled by the composed `Input` and `Select` primitives and inherited by SearchFilterBar.

## Feature Flags

Not applicable: this is a reusable UI primitive with no feature-flag concerns. Feature gating occurs at the level of the consuming feature, not the component.

## Analytics

Not applicable: this is a presentational component that emits no telemetry of its own — see **Logging** for the same reasoning. Searches and filter changes are observed and tracked by the consuming feature (e.g., the research pane's event tracking), not by the bar itself.

## Privacy

Not applicable: the component stores no data, collects no telemetry, and transmits nothing. All user input is relayed to the caller via `onChange` callbacks; what the caller does with that input is the caller's responsibility.

## Logging

This ingredient is presentational and emits no structured log events. Searches and
filter changes are observed by the consuming feature (e.g. the research pane's list
fetch + telemetry), not by the bar.

## Platform Notes

- **React / Web (TypeScript):** Component at
  `packages/web/packages/ui/src/components/search-filter-bar.tsx`, composing the shared
  `Input` and `Select` primitives. Demoed in `ui-showcase` (Forms group). The hub
  `ResearchFilters` adapts its `{ q, category, tag }` `FilterState` onto it.
- **iOS / Safari:** a search field with no `<form>` ancestor is scoped for
  autofill against the whole document, so on a page that also carries
  contact-shaped content iOS can offer "AutoFill Contact" over the search box.
  `asForm` is the fix for those pages; the attribute bag the shared `Input`
  applies (`autocomplete="off"` plus the password-manager opt-outs) is not
  sufficient on its own.
- **SwiftUI:** Build the search field from a `TextField` bound to `search.value`/`search.onChange`, with a leading `Image(systemName: "magnifyingglass")` overlay for the icon — SwiftUI has no `SearchField` view, and `.searchScopes` is for scope tokens, not for binding query text (reach for `.searchable` instead of a plain field only when the search belongs in a navigation bar's built-in search UI, not inline like this bar). Filters always render as one `Picker` per axis in a single `HStack`, each with `.pickerStyle(.menu)` for the same compact dropdown a native `<select>` gives on the web, its selection bound to the filter's `value`/`onChange` and the all-pass entry as the `.tag("")` case. `orientation` governs the bar, not the filter row: `stacked` (default) wraps the search field and the filter `HStack` in an outer `VStack`; `inline` instead lets the field and the filter `HStack` share one row, with the field taking the slack via `.frame(minWidth:)`. `asForm` has no native SwiftUI equivalent — native ports ignore this property.
- **Compose:** Build from `OutlinedTextField` for the search input and `ExposedDropdownMenuBox` per filter in a horizontal row (use `Row` with `horizontalArrangement = Arrangement.spacedBy(8.dp)` for `orientation="inline"`, or `Column` for `orientation="stacked"`). The search field is fully controlled by `value`/`onValueChange` with a leading search icon (`Icons.Default.Search`) rendered via a `leadingIcon` lambda. Each dropdown's all-pass option is the default selection (value `""`). The `asForm` property wraps the layout in a `Column` — no form submission exists in Compose; treat it as a composition point for caller validation logic.
- **AppKit / UIKit:** Build the search field from `NSSearchField` (macOS) or `UISearchBar` (iOS); on iOS, text changes arrive through the `UISearchBarDelegate` method `searchBar(_:textDidChange:)`, not target-action. Each filter is `NSPopUpButton` (macOS) — on iOS, `UIPickerView` is too heavy for a compact filter dropdown; use a `UIButton` with a `UIMenu` (`showsMenuAsPrimaryAction = true`) instead, or `UISegmentedControl` for filters with few options. Filters always sit in one horizontal `NSStackView`/`UIStackView`; `orientation` governs the outer arrangement instead — `stacked` (default) puts that filter stack below the search field in a vertical outer stack, `inline` puts the two side by side in a horizontal outer stack that wraps. `asForm` has no native AppKit/UIKit equivalent — the autofill scoping it fixes is a web/`<form>`-specific quirk — so native ports ignore this property.
- **WinUI 3:** Build the search field from a `TextBox` (or `AutoSuggestBox`) with `PlaceholderText` bound to `search.placeholder`, two-way binding to `search.value`, and a `TextChanged` handler calling `search.onChange` directly — the component has no built-in debounce, and native ports need none either. Each filter is a `ComboBox` with items bound to the options list, the all-pass entry prepended manually, two-way binding to `value`, and a `SelectionChanged` handler calling `onChange`. Filters always sit in one horizontal `StackPanel`; `orientation` governs the outer arrangement instead — `stacked` (default) puts that filter `StackPanel` below the search box in a vertical outer `StackPanel`, `inline` puts the two side by side in a horizontal outer arrangement that wraps. `asForm` has no native WinUI 3 equivalent — `Microsoft.UI.Xaml` (the WinUI 3 namespace; `Windows.UI.Xaml` is UWP's) has no form/autofill-scoping construct to map it to — so native ports ignore this property.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/search-filter-bar.tsx` | unverified |

## Design Decisions

- **Decision**: Both the search field and every filter select are fully
  controlled, with caller-supplied option sets.
  **Rationale**: explicit-over-
  implicit — the bar owns no list/data state; it cannot desync from the consumer,
  and the consumer keeps option universes stable so narrowing never empties a
  dropdown.
  **Approved**: pending
- **Decision**: An option is a bare string *or* a `{ value, label }` pair, and the
  two mix on one axis.
  **Rationale**: the original `string[]` was a yagni bet that
  a consumer proved wrong — an axis over *records* (a status, an iteration, an
  owner) filters by id and reads as a name. Making the caller keep a label↔id
  codec of its own would be a lossy guess about data it already holds correctly:
  two ids can share a display name, and two names can share an id. The bare string
  stays as the shorthand for the case where they coincide, so no existing caller
  had to change.
  **Approved**: pending
- **Decision**: `children` land in the filter row rather than in a config union.
  **Rationale**: yagni / optimize-for-change — `filters` covers the single-select
  axis, which is most of them; an axis that is genuinely a different control (a
  multi-select, a date range, a toggle group) composes at the call site instead of
  growing a union that has to describe every control the platform will ever filter
  with. The bar supplies the landmark, the field and the row.
  **Approved**: pending
- **Decision**: `asForm` lives here, off by default, rather than each host
  wrapping the bar in its own `<form>`.
  **Rationale**: dry — "a search field with
  no form ancestor is autofilled against the whole document" is a property of
  search fields, not of any one page, and it is a measured platform quirk that
  needs a paragraph to be legible at a call site. Default-off because a bar
  rendered inside a host's own form would nest one, which the parser resolves by
  dropping it.
  **Approved**: pending
- **Decision**: Compose the existing `Input` + `Select` primitives rather than
  restyle.
  **Rationale**: dry / consistency — the bar inherits the standard
  focus-ring and token treatment, so it matches every other field on the platform.
  **Approved**: pending
- **Decision**: The filter row is omitted entirely when `filters` is empty.
  **Rationale**: principle-of-least-astonishment — a search-only bar shows no empty
  control row.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | partial | Accessibility |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | passed | Internationalization |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | passed | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

The source shows `role="search"`, `aria-label` on the search field and every
select, and `aria-hidden` on the decorative icon (screen-reader-support,
semantic-markup) and relies on native controls for keyboard operability
(keyboard-navigable); it carries no owned strings, since every label, the
placeholder, and every option come from the caller (no-hardcoded-strings,
string-externalization) and relays typed text verbatim through a native input
(unicode-support). Contrast, dynamic type, and touch-target sizing are inherited
from the composed `Input`/`Select` primitives, which are outside this file, so
they read as partial; text-expansion tolerance is likewise partial because
overflow handling for a long translated label lives in `Select`, not here. RTL
fails because the search icon is positioned with the physical `left-2.5`
offset rather than a logical `start` offset, so it does not flip sides under a
right-to-left layout. `separation-of-concerns` passes because the component composes
the shared `Input`/`Select` primitives with no owned business logic beyond the small
pure `asOption` helper, and `unit-test-coverage` passes because `searchFilterBar.test.tsx`
exercises the search field, every filter axis, orientation, form-root, and autofill
attributes with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-06-26 | Mike Fullerton | Initial recipe — extracted from the hub research filter bar into `@adh-shared/ui`. |
| 1.1.0 | 2026-08-24 | Mike Fullerton | Added `asForm` for the iOS autofill scoping the registry search needs. Brought the spec back level with the component: `{ value, label }` options, `orientation`, `children`, `aria-label`, `onKeyDown`, and the moved source path. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Added missing sections (Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, Privacy) with appropriate non-applicable explanations. Moved status to review. |
| 1.2.1 | 2026-09-22 | Mike Fullerton | Expanded Platform Notes with concrete translation guidance for SwiftUI, Compose, AppKit / UIKit, and WinUI 3; removed "Not applicable" from all non-source platforms. |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Lint pass: corrected `depends-on` to the Input/Select recipes; added `Approved: pending` to every Design Decision; rebuilt Compliance as linked, catalog-derived checks; fixed wrong native APIs and the orientation mapping in the SwiftUI, AppKit/UIKit, and WinUI 3 platform notes and removed their fabricated `asForm`/debounce claims; corrected the stale-selected-value and duplicate-option-strings edge cases with a new conformance vector; fixed the Filter-active state description; and collapsed the duplicated Analytics/Logging text. |
| 1.3.1 | 2026-09-24 | Mike Fullerton | Renamed `may-scope-autofill-with-a-form` to the subject-only `autofill-form-scope`. |
| 1.3.2 | 2026-09-25 | Mike Fullerton | Reshaped Design Decisions into `**Decision**`/`**Rationale**`/`**Approved**` line triples. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
