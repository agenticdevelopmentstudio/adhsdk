---
id: d1036253-b5c6-4ce5-a285-b91bae4b9f2f
title: "Landing Page Blocks"
type: ingredient
version: 1.0.1
status: review
language: en
created: 2026-11-14
modified: 2026-11-14
author: mfullerton
copyright: 2026 mfullerton
license: MIT
summary: "Shared landing-page block renderer: maps each LandingBlock kind to its kit component, builds prose bodies, and lists section index rows."
platforms:
  - typescript
  - web
tags:
  - landing
  - page
  - blocks
depends-on:
  - 811cc18f-e33a-42bb-bd2d-dfc3dc21bc77
  - 79093eb5-83e8-46d8-9efe-3cc6ff88d8db
  - 7e4a2c5b-8f3d-4a7e-b9f2-1c5e8d3b6a2f
  - 01947259-4883-44e1-a047-6b4e463cb422
  - 91db9191-1ab2-4d09-a9a8-b0dc23669066
  - 335f37a4-cd9e-4575-a78a-8717b34e5a2d
  - 53a37583-e86d-41ca-8dd2-8394ba530091
  - b0ce8cbb-31ac-425a-889c-68e699d24578
  - ba2377b1-f831-4ef8-bf2c-d8393e5eb2c1
  - 4cd07922-a00d-4029-8cb5-2307463129cc
  - a63de97e-d75c-4733-a875-bad20e001fcb
  - 98444e89-1044-43a7-9ec5-75da579c528a
  - 12cc7564-cb08-4b62-9785-c3b1cc0c46f0
  - 5182f5ec-186b-4605-8c40-ea70a49262c2
  - 42e7a2ea-f138-4edb-899f-43c1946e4ef8
  - 688cd8dc-2927-4a8a-9931-807fe283ed01
  - f98e53f7-ac16-48b0-afa5-544d05bf3f70
  - 1675b18e-34d5-4d8e-987f-92697539a5e6
  - e7060a14-3f66-429a-9ea5-288f1fe5a76f
related:
  - 05930e64-fa82-49ef-b50d-22d87fa7d182
  - 6f5f455d-b744-425d-a21e-494fc18caaf2
references: []
approved-by: ""
approved-date: ""
---

# Landing Page Blocks

## Overview

This module is what every landing page layout shares: how one block of page data becomes a rendered component, and which rows the section index lists. The snap deck and the continuous flow both call it, so a block cannot render one way in a deck and another way in a flow. It exports three functions, `prose`, `renderBlock` and `indexRows`.

`renderBlock` takes one `LandingBlock` and returns the kit component for its `kind`: Lede, Trust, Cards (with Card children), Points, Code, Shot, Table, StatusPill, Rule, Stats, Versus, Chips, Checklist, Faq, Closer, Cta (with Btn children) or Roadmap. `prose` turns a list of paragraphs into `<p>` elements, because the kit styles a block body through its paragraph child. `indexRows` returns one link row per page section.

Every block it renders is a server component, and the module sits behind the server-safe barrel (a build check asserts the built `dist/index.js` stays free of the client-component directive). It holds no state and does no I/O.

## Behavioral Requirements

- **prose-paragraphs**: `prose` MUST return one `<p>` element per entry of the list it is given, in the same order.
- **prose-keys**: Each `<p>` that `prose` returns MUST carry its list index as its key.
- **prose-empty**: `prose` MUST return an empty list when given an empty list.
- **render-block-kind-dispatch**: `renderBlock` MUST select the component to render from the block's `kind`.
- **render-block-key**: `renderBlock` MUST pass the `key` argument it is given as the key of the element it returns.
- **render-lede**: For `Lede`, `renderBlock` MUST render a Lede whose children are the block's `children`.
- **render-trust**: For `Trust`, `renderBlock` MUST render a Trust whose `items` are the block's `items`.
- **render-cards-flags**: For `Cards`, `renderBlock` MUST pass the block's `pair`, `trio` and `wide` flags through to the Cards component.
- **render-cards-card**: For `Cards`, `renderBlock` MUST render one Card per entry of `items`, passing the entry's `kicker` and `title` unchanged.
- **render-cards-body**: For `Cards`, `renderBlock` MUST render each card body through `prose`.
- **render-cards-icon**: For `Cards`, `renderBlock` MUST pass a card's `icon` to Card as the path `/icons/<icon>.svg`, and MUST pass no icon when the card has none.
- **render-points**: For `Points`, `renderBlock` MUST pass the block's `entries` and `ordered` flag through to Points.
- **render-code**: For `Code`, `renderBlock` MUST render a Code whose `text` is the block's `text`.
- **render-shot-fields**: For `Shot`, `renderBlock` MUST pass the block's `title` and `caption` to Shot.
- **render-shot-media**: For `Shot` with a `src`, `renderBlock` MUST pass Shot an `<img>` as `media`, whose source is `/screenshots/<src>.png` and whose `alt` text is the block's `caption`.
- **render-shot-placeholder**: For `Shot` with no `src`, `renderBlock` MUST NOT pass `media`, so that Shot draws its own placeholder frame.
- **render-shot-pending-label**: For `Shot`, `renderBlock` MUST pass the `pendingLabel` argument it is given to Shot as `pendingLabel`.
- **render-shot-default-label**: When no `pendingLabel` argument is given, `renderBlock` MUST use the text `Screenshot coming soon`.
- **render-table**: For `Table`, `renderBlock` MUST pass the block's `caption`, `columns` and `rows` through to Table.
- **render-status-pill**: For `StatusPill`, `renderBlock` MUST render a StatusPill with the block's `free` flag and the block's `children` as its content.
- **render-rule**: For `Rule`, `renderBlock` MUST pass the block's `steps` through to Rule.
- **render-stats**: For `Stats`, `renderBlock` MUST pass the block's `entries` through to Stats.
- **render-versus**: For `Versus`, `renderBlock` MUST pass the block's `them` and `us` sides through to Versus.
- **render-chips**: For `Chips`, `renderBlock` MUST pass the block's `entries` and `soon` flag through to Chips.
- **render-checklist**: For `Checklist`, `renderBlock` MUST pass the block's `groups` through to Checklist.
- **render-faq-entries**: For `Faq`, `renderBlock` MUST pass each entry's `question` and `open` flag unchanged.
- **render-faq-answer**: For `Faq`, `renderBlock` MUST render each entry's `answer` through `prose`.
- **render-closer**: For `Closer`, `renderBlock` MUST render a Closer with the block's `title` and a body rendered through `prose`.
- **render-cta-buttons**: For `Cta`, `renderBlock` MUST render one Btn per entry of `buttons`, with the entry's `href`, `variant` and `label` as its link target, variant and content.
- **render-roadmap**: For `Roadmap`, `renderBlock` MUST render a Roadmap with the block's `eyebrow`, whose children are each child block rendered by `renderBlock`.
- **render-roadmap-pending-label**: For `Roadmap`, `renderBlock` MUST hand the `pendingLabel` it was given to every nested `renderBlock` call, so a Shot nested in a Roadmap is worded the same as one outside it.
- **render-roadmap-keys**: For `Roadmap`, `renderBlock` MUST key each nested child by its index in `children`.
- **render-exhaustive**: `renderBlock` MUST be written so that a `kind` added to `LandingBlock` without a matching case is a compile-time type error at the point of the switch.
- **render-unknown-kind**: For a block whose `kind` matches no case at runtime, `renderBlock` MUST return that block value itself, unrendered. This is the source's behavior: the exhaustiveness check is a type check, not a runtime guard.
- **index-rows-shape**: `indexRows` MUST return one row per entry of `page.sections`, in section order, each row an `href` and a `label`.
- **index-rows-href**: `indexRows` MUST set each row's `href` to `#` followed by the section's `id`.
- **index-rows-label**: `indexRows` MUST set each row's `label` to the section's `eyebrow`.
- **index-rows-no-hero**: `indexRows` MUST NOT return a row for the hero, because the browser's Home key already reaches the top of the page.
- **server-only**: The module MUST NOT introduce a client-component boundary, so that it stays inside the server-safe barrel.

## Appearance

Not applicable: this module renders no markup of its own except `<p>` elements from `prose` and the `<img>` inside a Shot. All visual styling belongs to the kit components it composes.

- **Paragraph styling**: `prose` exists because the kit styles a body through its paragraph child: `.lp-card p`, `.lp-closer p` and `.lp-faq details p`. A body rendered as a bare text child inherits the page defaults instead, so the words are right and the pixels wrong.
- **Shot image**: the `<img>` has no styling of its own in this module; Shot frames it.
- **Corner radius, padding, font, colors, border, shadow, size**: not applicable; set by the composed components.

## States

Not applicable: the functions are pure and stateless, and the module has no pressed, disabled, focused or loading state. The one state-like input is a Shot that has no image yet.

| State | Appearance change |
|-------|------------------|
| Default | — |
| Shot with no `src` | Shot draws its placeholder frame, with the pending label as its status line |
| Shot with `src` | Shot shows the image at `/screenshots/<src>.png` |
| Pressed | Not applicable: no interactive element of its own |
| Disabled | Not applicable: no interactive element of its own |
| Focused | Not applicable: no interactive element of its own |
| Loading | Not applicable: rendering is synchronous |

## Accessibility

- **Role and semantics**: Not applicable: the module adds no role or landmark. Roles belong to the composed components; the section index rows are plain `#id` link targets for the host's navigation to draw.
- **Shot image alternative text**: The `<img>` rendered for a Shot with a `src` takes the block's `caption` as its `alt` text.
- **Keyboard and focus**: Not applicable: the module draws no control. Buttons come from Btn, and Faq entries from Faq.
- **Announce state changes**: Not applicable: the module has no state.
- **Minimum tap target**: Not applicable here; owned by Btn and the other interactive components.

## Conformance Test Vectors

The source has no unit test beside it. Vectors 001 to 013 are derived from the source; vectors 014 to 016 come from assertions in `packages/web/packages/adh/src/__tests__/landingFlow.test.tsx` and `landingDeck.test.tsx` (index rows) and `packages/web/packages/landing/src/__tests__/page.test.tsx` (the `heroSlots` pending-label test, which goes through `renderBlock`).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| blocks-001 | prose-paragraphs, prose-keys | `prose(['a', 'b'])` | Two `<p>` elements containing `a` then `b`, keyed 0 and 1 |
| blocks-002 | prose-empty | `prose([])` | An empty list |
| blocks-003 | render-block-kind-dispatch, render-code | `renderBlock({ kind: 'Code', text: 'a b' }, 0)` | A Code element with `text` equal to `a b` |
| blocks-004 | render-block-key | `renderBlock({ kind: 'Lede', children: 'x' }, 7)` | An element whose key is `7` |
| blocks-005 | render-cards-icon, render-cards-card | A `Cards` block with one card whose `icon` is `shield` | Card receives the icon `/icons/shield.svg` |
| blocks-006 | render-cards-icon | A `Cards` block with one card that has no `icon` | Card receives no icon |
| blocks-007 | render-cards-body, prose-paragraphs | A card with `body` of two strings | The card contains two `<p>` children |
| blocks-008 | render-shot-media | `Shot` with `src` `main-window` and `caption` `The main window` | Shot receives an `<img>` with source `/screenshots/main-window.png` and `alt` `The main window` |
| blocks-009 | render-shot-placeholder, render-shot-default-label, render-shot-pending-label | `Shot` with no `src`, called with no label | Shot receives no `media`, and its `pendingLabel` is `Screenshot coming soon` |
| blocks-010 | render-roadmap, render-roadmap-pending-label, render-roadmap-keys | A `Roadmap` whose child is a `Shot` with no `src`, called with `pendingLabel` `Soon` | The nested Shot shows the pending label `Soon`; the child is keyed 0 |
| blocks-011 | render-faq-entries, render-faq-answer | A `Faq` entry with `open: true` and an `answer` of one string | Faq entry keeps `open` true and its answer is one `<p>` |
| blocks-012 | render-cta-buttons | A `Cta` with buttons `{ href: '/start', label: 'Get started' }` and one with `variant: 'ghost'` | Two Btn elements; the first has `href` `/start` and passes no variant (Btn then uses its `primary` default), the second has variant `ghost` |
| blocks-013 | render-unknown-kind | A value cast to `LandingBlock` whose `kind` is `Nope` | The same value returned, not an element |
| blocks-014 | index-rows-shape, index-rows-href, index-rows-label | A page with sections `{ id: 'what-it-is', eyebrow: 'What it is' }`, `{ id: 'what-it-does', eyebrow: 'What it does' }`, `{ id: 'the-shape', eyebrow: 'The shape' }` | Rows `#what-it-is` / `What it is`, `#what-it-does` / `What it does`, `#the-shape` / `The shape` (landingFlow test: gives every band a row in the index) |
| blocks-015 | index-rows-no-hero | A page with a hero and three sections | Exactly three rows; none for the hero |
| blocks-016 | render-shot-pending-label | A hero `Shot` with no image, rendered with a host label (page.test: words a pending hero Shot as its host asks) | The placeholder reads the host's label, not the default |

## Edge Cases

- **Empty list to prose** (MUST): `prose([])` returns an empty list; a Card, Closer or Faq answer with no paragraphs gets no children.
- **Null and empty block fields** (MUST pass through): a `Cards` block with an empty `items` list renders a Cards element with no Card children; a `Roadmap` with empty `children` renders an empty Roadmap. Neither is guarded by the source.
- **Shot without a screenshot** (MUST): no `src` leaves `media` out so the placeholder is reachable. An unconditional `<img>` would have made it unreachable, because the kit renders the placeholder only when `media` is absent.
- **Card without an icon** (MUST): `icon` is `undefined`, not an empty path, so no broken `/icons/undefined.svg` is requested.
- **Unknown kind at runtime** (MUST, as documented): the block value is returned as-is, and a plain object is not a valid React child, so React raises a render error when the value is placed in the tree. Only the compile-time check protects against this, and this module raises nothing itself.
- **Nested roadmap depth** (MUST recurse): Roadmap children are rendered recursively with no depth limit; a Roadmap inside a Roadmap renders.
- **Boundary values** (MUST pass through): a `Table` with no rows, or a `Cta` with no buttons, is passed through as given; the source sets no minimum or maximum count anywhere.
- **Concurrent access**: Not applicable: the functions are pure and share no mutable state, so any number of renders can run at once.
- **Error states and offline**: Not applicable: no network, file system or dependency is touched, and the module throws nothing of its own. The image it names is fetched by the browser, not by this module; a missing image file shows as a broken image, which the module does nothing about.
- **Page with no sections** (MUST): `indexRows` returns an empty list.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `block` | `LandingBlock` | required | The block to render; its `kind` selects the component |
| `key` | `number` | required | React key for the returned element |
| `pendingLabel` | `ReactNode` | `Screenshot coming soon` | Status line of a Shot with no image; the host's word for it when it has one |
| `paragraphs` | `ReactNode[]` | required | The list `prose` turns into `<p>` elements |
| `page` | `LandingPage` | required | The page whose sections `indexRows` lists |

## Deep Linking

Not applicable as a destination. The module is where the section anchors are made: each `indexRows` row links to `#<section id>`, the DOM id of the matching screen or band. The section `id` is computed by the page generator, not derived here.

| Platform | URL Pattern |
|----------|-------------|
| Web | `#<section id>` |
| Apple | Not applicable: web source only |
| Android | Not applicable: web source only |

## Localization

Not applicable: the module holds one string of its own, the default pending-shot label, and copy otherwise arrives in the block data. The default is worded to match the content generator's own placeholder image so a page and a help page say the same thing.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (inline constant) | `Screenshot coming soon` | Status line of a Shot with no image, unless the host passes its own |

## Accessibility Options

Not applicable: the module has no animation, color or contrast logic of its own; those options belong to the components it composes.

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: no motion in this module |
| Increase Contrast | Not applicable: no color in this module |
| Differentiate Without Color | Not applicable: no color in this module |

## Feature Flags

Not applicable: the module reads no flag; which blocks appear is decided by the page data.

| Flag Key | Default | Description |
|----------|---------|-------------|
| — | — | None |

## Analytics

Not applicable: the module emits no events.

| Event | Properties | When |
|-------|-----------|------|
| — | — | None |

## Privacy

- **Data collected**: None.
- **Storage**: None; the module is stateless.
- **Transmission**: None from this module; the browser requests the screenshot and icon files the paths name.
- **Retention**: Not applicable.

## Logging

Not applicable: the module writes no log output.

| Event | Level | Message |
|-------|-------|---------|
| — | — | None |

## Platform Notes

- **SwiftUI**: Start from a `@ViewBuilder` function that switches over an enum with one case per block kind; Swift's exhaustive `switch` gives the same compile-time guarantee as the `never` check. Build paragraph bodies as `Text` views in a `VStack`, and use `AsyncImage` or an asset-catalog image for a Shot with a placeholder view when no image is named. Section rows become a `List` or `ScrollViewReader` anchors keyed by section id.
- **Compose**: Use a `@Composable` function with a `when` over a sealed interface of blocks; a sealed `when` is exhaustive at compile time. Bodies are `Text` composables in a `Column`. A Shot with no image shows a placeholder `Box`; the index becomes `LazyColumn` items that scroll to the section's key.
- **React/Web**: The source is `packages/web/packages/landing/src/page/blocks.tsx`, re-exported from `packages/web/packages/landing/src/page/index.ts`. It is a `.tsx` module of three exports, with a `switch` on `block.kind` whose default case assigns the block to a `never` variable. Block types come from `./types`, and each case maps to a component in `../blocks`. It stays free of `'use client'` so the server-safe barrel holds.
- **AppKit / UIKit**: Use a factory returning an `NSView` or `UIView` per block kind from an enum switch, with `NSStackView` or `UIStackView` for paragraph bodies and `NSImageView` or `UIImageView` for a Shot (placeholder view when no image). The index is an `NSTableView` or `UITableView` whose rows scroll to the section view.
- **WinUI 3**: Build a `DataTemplateSelector` subclass whose `SelectTemplateCore` returns one `DataTemplate` per block kind, and bind an `ItemsRepeater` (or `ItemsControl`) to the section's block list so each block is drawn by `ItemsRepeater.ItemTemplate`. A C# `switch` expression over a sealed record hierarchy, with a discard arm that throws, replaces the `never` check; the source's runtime fall-through (the value returned unrendered) has no XAML equivalent, so pick the throw or an empty template deliberately. Render paragraph bodies as a `StackPanel` of `TextBlock` elements with `TextWrapping="Wrap"` and spacing from the style, not from inline margins. A Shot is an `Image` with `Source` set to a `BitmapImage` and `AutomationProperties.Name` bound to the caption (the `alt` equivalent); with no image, show a `Border` placeholder holding a `TextBlock` for the pending label, switched with a `VisualStateManager` state or a `Visibility` binding. The section index is a `NavigationView` with `MenuItems` of `NavigationViewItem`, or a `ListView` of `HyperlinkButton` rows, calling `FrameworkElement.StartBringIntoView` on the target section element.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/landing/src/page/blocks.tsx` | confirmed (1.0.1) |
| apple | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: One shared module renders blocks for both the snap deck and the continuous flow.
**Rationale**: A block that renders one way in a deck and another in a flow is the same content saying two different things; one copy removes the drift (the source's own comment).
**Approved**: pending

**Decision**: Bodies go through `prose` as `<p>` elements, never as a bare text child.
**Rationale**: The kit styles a body through its paragraph child (`.lp-card p`, `.lp-closer p`, `.lp-faq details p`); a bare child is valid JSX with the right words and the wrong pixels.
**Approved**: pending

**Decision**: A Shot with no `src` passes no `media`, and the page model supplies the default pending label `Screenshot coming soon`.
**Rationale**: The kit renders the placeholder only when `media` is absent, and `pendingLabel` has no default in the kit because it is visible copy the kit does not choose. The label is chosen here once for every page built from data, and a host with its own word passes that instead. It matches the content generator's placeholder image wording.
**Approved**: pending

**Decision**: Icon ids and screenshot ids are resolved to `/icons/<id>.svg` and `/screenshots/<id>.png` here, against the site's own origin.
**Rationale**: One image set then serves the brochure and the help site, whose Markdown sanitizer accepts only absolute http or https sources (from the `Shot` block type's comment).
**Approved**: pending

**Decision**: The unhandled-kind case is a compile-time `never` assignment, and at runtime the block value is returned unrendered.
**Rationale**: The switch is the one place that could silently drop a block from every site's page at once, so a new `kind` must fail the type check. Technical debt that affects behavior: there is no runtime guard in this module, so data that bypasses the type system comes back as an unrendered value and fails later, in React, instead of at the switch.
**Approved**: pending

**Decision**: `indexRows` omits the hero.
**Rationale**: The hero is the top of the page, which the browser's Home key already reaches; a first row meaning "go back to where you started" carries no information.
**Approved**: pending

**Decision**: Every block it renders is a server component.
**Rationale**: The module sits behind the server-safe barrel, and a build check asserts `dist/index.js` stays free of `'use client'`.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | accessibility |

The module separates concerns cleanly: it only maps data to kit components, and styling, behavior and copy live in the components and the page data. Unit-test coverage passes: `page-blocks.test.tsx` covers blocks-001 to blocks-016. Error handling is partial because the unhandled-kind case is guarded at compile time only, and at runtime the block is returned unrendered. Semantic markup passes because bodies are real paragraphs and the Shot image carries its caption as `alt` text.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.1 | 2026-11-14 | Mike Fullerton | Conformance tests added (page-blocks.test.tsx, 16 of 16 vectors); unit-test-coverage now passed. |
| 1.0.0 | 2026-11-14 | mfullerton | Initial creation |
