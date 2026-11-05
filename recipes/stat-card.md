---
id: b7a4a259-620f-42a3-8bc2-9e5c07c1819d
title: StatCard
domain: adhsdk://recipes/stat-card
type: recipe
version: 1.4.1
status: review
language: en
created: '2026-07-03'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "The dashboard stat card — an InfoPanel headed by an icon + title with a '{tool} ↗' deep link, over StatRows, freeform children, and a muted mono footnote."
platforms:
- typescript
- web
tags:
- block
- stat
- card
- dashboard
- ui
ingredients:
- adhsdk://recipes/info-panel
- adhsdk://recipes/stat
- adhsdk://recipes/external-link
depends-on: []
related:
- adhsdk://recipes/info-panel
- adhsdk://recipes/stat
- adhsdk://recipes/external-link
references: []
approved-by: ''
approved-date: ''
---

# StatCard

## Overview

`StatCard` in `@adh-sdk/ui` is the dashboard stat card: an `InfoPanel` headed by
an icon + title with an optional "{tool} ↗" deep link (plus optional extra header
controls via `actions`) in the header actions slot, over a vertical stack of `StatRow` figures, optional freeform content, and a muted
mono footnote. It is **pure assembly** — the shell is `InfoPanel`, the rows are
`StatRow`, the link is `ExternalLink` — so this block owns only the arrangement (a
`gap-2.5` column plus the footnote treatment), not any new chrome.

From a declarative `stats[]` (each `{ label, value, tone }`) it renders one `StatRow`
per entry; `children` render after the rows for the freeform cases (a live error
line, a sparkline), and `footnote` renders last as a small dim mono qualifier (e.g.
"anonymous · cookieless · approximate"). The card is always content-sized — it uses
`InfoPanel`'s default (non-scroll) mode, so it grows to its content rather than
scrolling.

It was extracted from a status site's Traffic/Errors telemetry cards, so every site's
"figure card with a deep link into the source tool" shares one component.

## Ingredients

| Name | Domain | Role | Required | Configuration |
|---|---|---|---|---|
| InfoPanel | adhsdk://recipes/info-panel | The card shell — bordered/rounded frame with the standard header (icon + title) and a content-sized body | yes | `title`, `icon`, `actions` (the link + extra `actions`), `className` and remaining host attributes forwarded; default content-sized (no `scroll`) |
| StatRow | adhsdk://recipes/stat | One label/value figure per `stats[]` entry, in the body stack | yes (when `stats[]` non-empty) | `label`, `value`, `tone` passed through from each `StatCardStat` |
| ExternalLink | adhsdk://recipes/external-link | The "{label} ↗" deep link into the source tool, placed in the InfoPanel actions slot | no (only when `link` given) | `href` = `link.href`, children = `link.label`; opens a new tab (noopener) |

The body-stack container, the footnote treatment, and the `stats[]`→rows mapping are
the only things this block owns; `StatCardStat` (`{ label, value, tone }`) is exported
alongside the component.

## Integration Requirements

- **render-infopanel-shell**: The card MUST render as an `InfoPanel` whose title is `title` and whose leading glyph is `icon`, exposing the card as a labeled region named by `title`.
- **title-as-accessible-name**: `title` MUST be a plain string, so the region InfoPanel names from it carries a reliable accessible name; a non-string `title` is not guaranteed to produce a meaningful one.
- **place-link-in-actions**: When `link` is provided, the card MUST render an `ExternalLink` to `link.href` labeled `link.label` in the InfoPanel actions slot, and MUST omit the actions slot when both `link` and `actions` are absent.
- **render-actions-after-link**: When `actions` is provided, the card MUST render it in the InfoPanel actions slot, after the deep link when both are present.
- **spread-host-attributes**: The card MUST pass remaining host attributes (`data-*`, `id`, handlers) through to the InfoPanel root `<section>`, so hosts can tag the card without a wrapper element.
- **render-a-statrow-per-stat**: The card MUST render one `StatRow` per `stats[]` entry, passing that entry's `label`, `value`, and `tone`.
- **render-children-after-rows**: The card MUST render `children` after the stat rows, within the same body stack.
- **render-footnote-when-present**: The card MUST render `footnote` as a muted mono caption after the children — and as the last item in the body stack even when there are no children or no `stats` — and MUST omit it when `footnote` is null/undefined.
- **stack-body-vertically**: The card MUST arrange the rows, children, and footnote in a single vertical `gap-2.5` column.
- **forward-classname**: The card MUST forward `className` onto the InfoPanel outer element.

## Layout

```
┌ InfoPanel  aria-label = title ─────────────────────────────┐
│ [icon] Title                              PostHog ↗         │  header (icon + title; link in actions)
├────────────────────────────────────────────────────────────┤
│ ┌ body stack: flex flex-col gap-2.5 ────────────────────┐   │
│ │ PAGEVIEWS · 7D                                637      │   │  ← StatRow (stats[0])
│ │ VISITORS · 7D                                 538      │   │  ← StatRow (stats[1])
│ │ …children (freeform, after the rows)…                 │   │
│ │ anonymous · cookieless · approximate                  │   │  ← footnote (muted mono 10px)
│ └───────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

- Shell: `InfoPanel` in its default content-sized (non-scroll) mode; `title`, `icon`,
  `className`, and remaining host attributes pass straight through; the InfoPanel
  actions slot receives the `ExternalLink` (when `link` is set) followed by any
  extra `actions`, and is omitted when both are absent.
- Body: a single `<div className="flex flex-col gap-2.5">` holding, in order, the
  mapped `StatRow`s, then `children`, then the footnote.
- Footnote: `pt-0.5 font-mono text-[10px] text-apt-text-dim` — matched to the StatRow
  label's micro-caption grammar; rendered only when `footnote != null`.
- No raw hex, no `!important` — all color/typography via `apt-*` tokens and the
  composed shared parts.

## Shared State

`StatCard` holds no state — it is pure, declarative assembly. Every prop flows down
into a composed part; nothing flows back up except the browser navigation an
`ExternalLink` triggers (a new tab).

| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| `title` / `icon` / `className` | Caller | InfoPanel | Down | Prop pass-through |
| `link` (`{href,label}`) | Caller | ExternalLink (actions slot) | Down | Prop → `actions` |
| `actions` | Caller | InfoPanel actions slot (after the link) | Down | Prop → `actions` |
| host attributes (`data-*`, `id`) | Caller | InfoPanel root `<section>` | Down | Rest-prop spread |
| `stats[]` | Caller | StatRow (one per entry) | Down | Array `map` |
| `children` | Caller | Body stack (after rows) | Down | Prop |
| `footnote` | Caller | Footnote caption | Down | Prop (rendered when non-null) |
| deep-link navigation | ExternalLink | New browser tab | Up (side effect) | `target="_blank"` anchor |

## Integration Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-infopanel-shell, title-as-accessible-name, place-link-in-actions, render-a-statrow-per-stat, render-footnote-when-present | `<StatCard title="Traffic" link={{href:'https://us.posthog.com',label:'PostHog'}} stats={[{label:'pageviews · 7d',value:'637'},{label:'visitors · 7d',value:'538'}]} footnote="anonymous · cookieless · approximate" />` | region named "Traffic"; a "PostHog ↗" link with `href="https://us.posthog.com"`; rows "pageviews · 7d"/"637" and "visitors · 7d"/"538"; footnote text present |
| T2 | render-children-after-rows, stack-body-vertically | `<StatCard title="Errors" stats={[{label:'open issues',value:'0'}]}><div>✓ No errors reported</div></StatCard>` | "✓ No errors reported" rendered after the "open issues"/"0" row, inside the one `flex flex-col gap-2.5` body stack |
| T3 | place-link-in-actions | `<StatCard title="Errors" stats={[...]} />` (no `link`) | no `ExternalLink`/anchor in the header actions slot |
| T4 | render-a-statrow-per-stat | `stats={[{label:'open issues',value:'2',tone:'error'}]}` | value "2" carries the error tone (`text-apt-red`) via StatRow |
| T5 | render-footnote-when-present | StatCard with no `footnote` | no footnote caption element rendered |
| T6 | render-infopanel-shell | `icon={<Bug/>}` | icon rendered as the decorative leading glyph (`aria-hidden` via InfoPanel) before the title |
| T7 | forward-classname | `className="col-span-2"` | InfoPanel outer `<section>` carries `col-span-2` |
| T8 | render-actions-after-link, place-link-in-actions | `link={{href:'https://g.example',label:'Grafana'}} actions={<span>healthy</span>}` | header actions slot holds the "Grafana ↗" link, then the status word |
| T9 | spread-host-attributes | `data-testid="monitor-card" data-monitor="lewis" data-phase="ok"` | outer `<section>` carries all three attributes |
| T10 | place-link-in-actions | `<StatCard title="Errors" stats={[{label:'open issues',value:'0'}]} />` (no `link`, no `actions`) | InfoPanel's `actions` prop is `undefined` — the header renders with no actions region at all, not merely an empty one (distinct from T3, which only checks for the missing anchor) |
| T11 | render-children-after-rows, render-footnote-when-present | `<StatCard title="Errors" stats={[{label:'open issues',value:'0'}]} footnote="approximate"><div>✓ No errors reported</div></StatCard>` | within the one body stack, order is the "open issues"/"0" row, then "✓ No errors reported", then "approximate" as the last child |
| T12 | render-actions-after-link, place-link-in-actions | `<StatCard title="Monitor" stats={[{label:'status',value:'ok'}]} actions={<span>healthy</span>} />` (no `link`) | header actions slot renders only `<span>healthy</span>`; no `ExternalLink`/anchor present |

## Edge Cases

- **No `stats`**: `stats?.map(...)` no-ops, so a card with only `children` and/or a
  `footnote` renders fine (`stats` is optional).
- **No `link` and no `actions`**: the InfoPanel actions slot is omitted entirely
  (the header shows just icon + title).
- **`actions` without `link`**: the slot renders just the extra controls (e.g. a
  monitor card's live status word), right-justified by InfoPanel.
- **`footnote` guard is `!= null`**: `null`/`undefined` hide the footnote; an empty
  string (`""`) is *not* null and WOULD render an empty caption — pass `undefined` to
  hide, not `""`.
- **Rows + children + footnote together**: order is always rows → children → footnote
  within the one `gap-2.5` stack; `children` is the escape hatch for anything the
  declarative `stats[]` can't express (e.g. the status Errors card's live error line
  with a `StatusDot` and a count).
- **Always content-sized**: it never passes `scroll` to InfoPanel, so a long stat list
  grows the card rather than scrolling; use InfoPanel directly if scroll is needed.
- **`icon` is decorative**: InfoPanel marks the leading glyph `aria-hidden`, so the
  card's accessible name is the `title` alone — see **title-as-accessible-name**.
- **Per-stat `tone`**: omitted `tone` falls back to StatRow's `neutral`; the card adds
  no tone of its own.

## Platform Notes

- **Swift / SwiftUI**: A bordered/rounded container (`.background` + `.clipShape(RoundedRectangle)`, or `GroupBox`) holds a header `HStack` (an `Image` icon marked `.accessibilityHidden(true)`, a `Text` title, a `Spacer`, then — only when `link` or `actions` is present — a nested `HStack` holding a `Link` for the "{tool} ↗" deep link followed by any extra `actions` view) and a body `VStack(spacing: 10)` of label/value `HStack` pairs (one per stat, mirroring `StatRow`), then any freeform child `View`s, then a muted footnote `Text` (`.font(.system(size: 10, design: .monospaced))`, `.foregroundStyle(.secondary)`) as the stack's last child. Forward host attributes through SwiftUI view modifiers (e.g. `.accessibilityIdentifier`) rather than arbitrary attributes.
- **Kotlin / Compose**: A bordered `Card` (or `Surface` with `border`/`shape`) with a header `Row` (an `Icon` given an empty `contentDescription` to mark it decorative, a `Text` title, a `Modifier.weight(1f)` spacer, then — only when `link` or `actions` is present — a nested `Row` holding a `TextButton`/`ClickableText` for the deep link followed by any extra `actions` composable) and a body `Column(verticalArrangement = Arrangement.spacedBy(10.dp))` of label/value `Row` pairs per stat (mirroring `StatRow`), then freeform child composables, then a `Text` footnote (small monospace `FontFamily`, muted `color`) as the column's last child. Forward host attributes via a custom `Modifier` (e.g. `Modifier.semantics { testTag = … }`) rather than arbitrary attributes.
- **React / Web (TypeScript)**: `packages/web/packages/ui/src/blocks/stat-card.tsx`, exported from `@adh-sdk/ui` (`@adh-sdk/ui/blocks/stat-card`). Composes `InfoPanel` (`../blocks/info-panel`), `StatRow` (`../components/stat`), and `ExternalLink` (`../components/external-link`). Exports `StatCard`, `StatCardProps`, and the `StatCardStat` type. Demo: `ui-showcase` Topic `stat-card` (group "Blocks — cards & sections"); the demo shows a Traffic card (declarative stats + footnote), an Errors card (stats + freeform children), and a monitor card (header `actions` status word, no link). Regenerate `sources.generated.ts` via `gen-sources.py` after source changes. Responsive: the demo lays the cards in a `sm:grid-cols-2` grid; each card is content-sized and full-width in its cell — verify at 375 / 768 / 1440.
- **AppKit / UIKit**: iOS (UIKit): a container `UIView` with a rounded `CALayer` holds a header `UIStackView` (a decorative `UIImageView` icon, a `UILabel` title, then — only when `link` or `actions` is present — a nested `UIStackView` with a link-styled `UIButton` followed by any extra action views) and a body `UIStackView` (spacing 10) of label/value `UIStackView` pairs per stat, then freeform child views, then a muted footnote `UILabel` (10pt, secondary text color) as the last arranged subview. macOS (AppKit): the same shape with `NSStackView` and `NSTextField` labels, and an `NSButton` styled as a link for the deep link. Forward host attributes via `accessibilityIdentifier` on the root view.
- **WinUI 3**: Start with a `Border` (CornerRadius for rounded corners, BorderBrush for the card outline) containing a `Grid` with two rows — a header row and a body row — so the header-to-body gap is independent of the body's own row spacing. The header row is itself a `Grid` with three columns: icon (`Image` or `SymbolIcon`), title (`TextBlock` with heading-level font), and a horizontal `StackPanel` (Spacing=4) holding a `HyperlinkButton` for the deep link followed by any extra `actions` content; bind that actions `StackPanel`'s `Visibility` to `Collapsed` when both the link and actions are absent, and the `HyperlinkButton`'s `Visibility` to `Collapsed` when only the link is absent. The body row is a `StackPanel` with `Spacing=10` (gap-2.5 equivalence), containing `TextBlock` pairs for each stat row (label and value), a `ContentPresenter` for freeform children, and a `TextBlock` for the footnote (FontSize=10, `Foreground` set to a secondary/dim text brush) as its last child, with `Visibility` bound to `Collapsed` when null. Map forwarded host attributes (`data-*`, `id`) to `AutomationProperties.AutomationId`/`Name`, or a `Tag` dictionary, on the root `Border`, since WinUI has no direct arbitrary-attribute equivalent. Use a `Resources` section to define color and typography tokens matching the design system.

## Design Decisions

**Decision**: StatCard is pure assembly of `InfoPanel` + `StatRow` + `ExternalLink`,
owning only the body stack and footnote.
**Rationale**: the "figure card with a deep link" shape recurred across the status
board and admin console; centralizing the *arrangement* (not new chrome) keeps every
such card identical and lets the parts evolve independently.
**Approved**: pending

**Decision**: stats are declarative (`stats[]`) with `children` as an escape hatch.
**Rationale**: the common case (a list of label/value figures) is data, not markup;
`children` covers the rare freeform tail (a live error line) without forcing every
caller into imperative rows.
**Approved**: pending

**Decision**: the `link` maps to an `ExternalLink` in the InfoPanel actions slot.
**Rationale**: a stat card almost always deep-links into its source tool (PostHog,
GlitchTip); putting that "{tool} ↗" in the header's actions slot is the established
dashboard grammar and keeps the affordance out of the figure rows.
**Approved**: pending

**Decision**: the footnote is a fixed muted mono 10px qualifier matched to the
StatRow label.
**Rationale**: caveats like "approximate · cookieless" read as chrome around the
figures, so they share the label's micro-caption treatment rather than competing
with the values.
**Approved**: pending

**Decision**: always content-sized (never `scroll`).
**Rationale**: a stat card is a short, fixed set of figures; letting it grow keeps
all figures visible, and callers needing a scrolling list use `InfoPanel` directly.
**Approved**: pending

**Decision**: `actions` is a passthrough slot rendered after the deep link, and host
attributes spread onto the root.
**Rationale**: the fleet status page's monitor card needed a live status word in the
header and `data-*` hooks on the card root; exposing InfoPanel's existing slot and
attribute spread keeps that card on the one StatCard grammar instead of forcing a
site back onto raw InfoPanel + a duplicated footnote.
**Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | passed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on `stat-card.tsx`: it composes InfoPanel's labeled region and
aria-hidden icon and ExternalLink's native `<a>` (screen-reader-support,
keyboard-navigable, semantic-markup pass); its own colors/typography are `apt-*`
design tokens whose rendered contrast the source can't confirm (contrast-ratio
partial); and the component defines no literal user-facing string of its own —
`title`, `label`, `value`, and `footnote` are all caller-supplied props
(string-externalization, no-hardcoded-strings pass); the component is, per its own
comment, "pure assembly" of InfoPanel/StatRow/ExternalLink with no logic of its own
(separation-of-concerns passed), and `stat.test.tsx`'s `StatCard` suite renders it
with rows, links, actions, and footnote and asserts on the composed output
(unit-test-coverage passed).

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents the InfoPanel + StatRow + ExternalLink assembly extracted from the status telemetry cards. |
| 1.1.0 | 2026-07-03 | Mike Fullerton | `actions` header slot (extra controls after the deep link) + host-attribute passthrough to the panel root; adopted by the fleet status monitor card. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Correct domain URIs to agenticdevelopercookbook:// and complete Platform Notes with all five platform bullets and explanations. |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Rewrite WinUI 3 platform note with concrete translation guidance: Border, Grid header, StackPanel body, TextBlock pairs for stats, Visibility bindings for optional elements. |
| 1.4.0 | 2026-09-22 | Mike Fullerton | Lint pass: strip `must-` from every requirement name and its citations; add title-as-accessible-name requirement; straighten summary quotes; add related domains for the recipe-as-ingredient pattern; rewrite Compliance as linked catalog checks with passed/partial statuses; add Approved: pending to each Design Decision; add three Integration Test Vectors (actions-slot omission, children-before-footnote order, actions-without-link); rewrite WinUI 3 header/actions/host-attribute guidance and give SwiftUI, Compose, and AppKit/UIKit concrete translation guidance in place of Not applicable; clarify the footnote is always last in the body stack. |
| 1.4.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
