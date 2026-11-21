---
id: 598bbb0d-199d-4d3f-936c-7cf3b9f15aa5
title: "LinkList"
type: recipe
version: 1.0.0
status: review
language: en
created: 2026-11-21
modified: 2026-11-21
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A list of links: an icon by kind, the title as a new-tab link, a muted description, a bounded linked thumbnail for images, and a struck-through \"missing\" row for a target that is gone."
platforms:
  - typescript
  - web
tags:
  - block
  - links
  - list
  - ui
ingredients: []
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---
# LinkList
## Overview
`LinkList` in `@adh-sdk/ui` renders `links` (`LinkItem[]`) as a `<ul>`. Each row has a lucide icon (Image for an image, File for kind `file`, Globe otherwise), the title as an `ExternalLink` when `href` is set, the description muted under it, and for an `image` with an `href` a bounded thumbnail that links to the `href`. A `missing` row shows the struck-through dim title and a "missing" label, with no link and no thumbnail.
## Ingredients
None: the block composes `ExternalLink`, `EmptyState`, lucide icons and the shared `cn` helper directly.
## Integration Requirements
- **render-row-per-link**: The block MUST render a `<ul>` with one `<li>` per link, in the order given.
- **render-icon**: Each row MUST show a decorative icon: Image when `image`, else File when `kind` is `file`, else Globe.
- **link-title**: A title with an `href` MUST render as an `ExternalLink` (new tab, `noopener noreferrer`, no arrow glyph); without an `href` it is plain text.
- **render-description**: A description MUST render muted under the title.
- **thumbnail-images**: A link with `image` and an `href` MUST show an `<img loading="lazy" alt="">` no taller than 12rem, rounded and bordered, wrapped in a link to the `href`. Other links show no thumbnail.
- **mark-missing**: A `missing` row MUST show the title struck through in the dim text token with a "missing" label, and MUST NOT render a link or a thumbnail.
- **show-empty**: An empty list MUST show `emptyLabel` (default "No links yet.") in the shared `EmptyState` and no `<ul>`.
- **forward-class**: The block MUST merge `className` into its root element.
## Layout
```
[globe] Title  (new-tab link)
        muted description
[file]  Report (new-tab link)
[image] Photo  (new-tab link)
        [ thumbnail, links to the image ]
[globe] Gone (struck, dim)  missing
```

- Icons (lucide): `Image`, `File`, `Globe`, all `size-4 shrink-0 text-apt-text-muted`, `aria-hidden`.
- Thumbnail: `max-h-48 rounded-md border border-apt-border`.
- Missing: title `line-through text-apt-text-dim`, label `text-xs text-apt-text-dim`.
## Shared State
The block holds no state; every prop flows down into a composed part.
## Integration Test Vectors
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-row-per-link | three links | a `<ul>` with three items in order |
| T2 | link-title | a link with and without `href` | an anchor with `target="_blank"` and `rel` containing `noopener`, else plain text |
| T3 | render-icon | an image, a file and a url link | three decorative icons, one per kind |
| T4 | render-description | a link with a description | the description is shown muted |
| T5 | thumbnail-images | an image with and without `href`, a non-image with `href` | one lazy `<img alt="">` inside a link to the `href`; no other thumbnails |
| T6 | mark-missing | a missing link with `href` and `image` | struck-through dim title, "missing" label, no anchor, no `<img>` |
| T7 | show-empty | `links={[]}`, with and without `emptyLabel` | the label shown, no list |
| T8 | forward-class | `className="mt-2"` | the root carries it |
## Edge Cases
- **No `href`** renders the title as text, and an image gets no thumbnail.
- **An `image` that is also `kind: "file"`** shows the Image icon.
- **A missing row ignores `href`**: nothing links to a target that is gone.
- **Keys are indices**: the list is display-only and has no stable ids.
## Platform Notes
- **Swift / SwiftUI**: Not applicable until a SwiftUI port; translate LinkList as a `VStack` of rows.
- **Kotlin / Compose**: Not applicable until a Compose port; use `Column` with one row composable per item.
- **React / Web (TypeScript)**: Exported from `@adh-sdk/ui` (`@adh-sdk/ui/blocks/link-list`). `ExternalLink` and `EmptyState` come from `@adh-sdk/ui`; icons come from `lucide-react`.
- **AppKit / UIKit**: Not applicable until a native port; use `NSStackView`/`UIStackView`.
- **WinUI 3**: Not applicable until a WinUI port; use `StackPanel`.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/link-list.tsx` | confirmed (1.0.0) |

## Design Decisions

**Decision**: The thumbnail is decorative (`alt=""`) and the title carries the link name.
**Rationale**: A thumbnail beside a text link of the same target would otherwise be announced twice.
**Approved**: pending
## Compliance

| Check | Status | Category |
|---|---|---|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the block's source and its test file in `packages/web/packages/ui/src/__tests__/`, which asserts every requirement above.
## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-11-21 | Mike Fullerton | Initial recipe. |
