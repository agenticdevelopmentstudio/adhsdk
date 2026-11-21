---
id: 34d98464-3a63-49c7-9979-8cc5f4940b6a
title: "DescriptionCard"
type: recipe
version: 1.0.0
status: review
language: en
created: 2026-11-21
modified: 2026-11-21
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A card holding an optional title and a markdown description, rendered through a caller-supplied renderer or as plain text; nothing when both are empty."
platforms:
  - typescript
  - web
tags:
  - block
  - card
  - description
  - ui
ingredients:
  - ea565474-df7a-42bd-9613-5dd0cd861911
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# DescriptionCard
## Overview

`DescriptionCard` in `@adh-sdk/ui` shows a title and a description in a `Card`. `ui` has no markdown dependency, so the description is rendered by the `renderMarkdown` function the caller passes; without one it is plain text with its line breaks kept. When both title and description are empty the block renders nothing.
## Ingredients

| Name | rdid | Role | Required | Configuration |
|---|---|---|---|---|
| Card | [adhsdk.ingredient.ui.components.layout.card](cookbook:ea565474-df7a-42bd-9613-5dd0cd861911) | The bordered container with header, title and content slots | yes | `className` merged after `gap-4`; host attributes forwarded |
## Integration Requirements

- **render-card-shell**: The block MUST render its content in a `Card` and forward `className` and remaining host attributes to it.
- **render-title**: When `title` is a non-empty string, the block MUST render it in a `CardHeader` as a `CardTitle`, and MUST omit the header otherwise.
- **render-description-through-renderer**: When `renderMarkdown` is given, the block MUST render the description as the result of calling it with the description string, inside `CardContent`.
- **render-description-as-plain-text**: When `renderMarkdown` is absent, the block MUST render the description as a whitespace-preserving paragraph (`whitespace-pre-wrap`), never as HTML.
- **omit-empty-content**: The block MUST omit `CardContent` when `description` is empty or absent.
- **render-nothing-when-empty**: The block MUST render nothing (return null) when both `title` and `description` are empty or absent.
## Layout

```
┌ Card ───────────────────────────┐
│ CardHeader > CardTitle  (title)  │
│ CardContent (description)        │
└──────────────────────────────────┘
```

- Header only when `title` is non-empty; content only when `description` is non-empty.
- Plain text: `<p className="whitespace-pre-wrap text-sm text-apt-text-muted">`.
- Only `apt-*` tokens; no raw hex.
## Shared State

The block holds no state; every prop flows down into a composed part.
## Integration Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-title, render-description-as-plain-text | `<DescriptionCard title="Plan" description={'line one\nline two'} />` | title "Plan"; a `<p>` with `whitespace-pre-wrap` containing both lines |
| T2 | render-description-through-renderer | `description="**hi**" renderMarkdown={md => <div>{md.toUpperCase()}</div>}` | the renderer's output is shown, called with `**hi**` |
| T3 | render-nothing-when-empty | `<DescriptionCard />` and `<DescriptionCard title="" description="" />` | nothing rendered |
| T4 | omit-empty-content | `<DescriptionCard title="Only title" />` | no card-content element |
| T5 | render-title | `<DescriptionCard description="just text" />` | no card-header element |
| T6 | render-card-shell | `className="col-span-2" data-testid="dc"` | the card carries both |
## Edge Cases

- **Whitespace-only strings** are non-empty: they render a card with blank text; callers trim.
- **Renderer output is trusted**: the block does not sanitise what `renderMarkdown` returns.
- **Title only / description only** each render one slot.
## Platform Notes

- **Swift / SwiftUI**: Not applicable until a SwiftUI port; translate DescriptionCard as a stack of `Text` and `ProgressView`/`Image(systemName:)` views.
- **Kotlin / Compose**: Not applicable until a Compose port; use `Column`, `Text`, `LinearProgressIndicator`.
- **React / Web (TypeScript)**: Exported from `@adh-sdk/ui` (`@adh-sdk/ui/blocks/description-card`). Used by the mysites progress view with `MarkdownRenderer`.
- **AppKit / UIKit**: Not applicable until a native port; use `NSStackView`/`UIStackView` with `NSProgressIndicator`/`UIProgressView`.
- **WinUI 3**: Not applicable until a WinUI port; use `StackPanel`, `TextBlock`, `ProgressBar`.
## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/description-card.tsx` | confirmed (1.0.0) |

## Design Decisions

**Decision**: The markdown renderer is injected.
**Rationale**: Keeps `ui` free of a `markdown` dependency; the host passes its own renderer.
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
