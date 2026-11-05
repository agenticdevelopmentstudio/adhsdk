---
id: d9df7837-8e06-460a-a703-60441d74eeed
title: Categories and Tags
domain: adhsdk://recipes/categories-and-tags
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: A two-row composition pairing a single category selection with a set of tags,
  sharing label alignment.
platforms:
- typescript
- web
tags:
- classification
- form-fields
depends-on:
- adhsdk://recipes/category-field
- adhsdk://recipes/tag-set-field
related:
- adhsdk://recipes/document-identity-field
references: []
approved-by: ''
approved-date: ''
---

# Categories and Tags

## Overview

The Categories and Tags component is a composition of two independent field components—a category field and a tag set field—arranged vertically in a shared table-like layout. The component coordinates the label alignment between the two rows by sharing a CSS custom property, ensuring visual consistency when captions are right-aligned. Each field maintains its own state; the component manages neither category nor tag data, only layout and disabled state.

**Props**: `category: { label: string; noun: string; options: readonly string[]; nodes?: readonly CategoryTreeNode[]; value: string; onChange: (next: string) => void; onRename?: (node: CategoryTreeNode, nextName: string) => void | Promise<void> }`, `tags: { label: string; noun: string; options: readonly string[]; value: string[]; onChange: (next: string[]) => void }`, `disabled?: boolean` (default `false`), and `className?: string`. `label` and `noun` are required (non-optional) on both `category` and `tags`; the type carries no default and no optional fallback for either.

## Behavioral Requirements

- **compose-two-fields**: Component MUST render `CategoryField` with `layout="inline"` and `TagSetField` with `layout="inline"` vertically stacked, `CategoryField` first.
- **share-label-width**: Component MUST set the `--apt-field-label-w` CSS custom property on its root element to ensure both rows' label columns have equal width and right edges align.
- **accept-category-data**: Component MUST accept a `category` object containing `label`, `noun`, `options`, `value`, and `onChange`; it MUST pass these to `CategoryField`.
- **accept-category-nodes**: Component MUST accept an optional `category.nodes` array and pass it to `CategoryField` for breadcrumb and rename behavior.
- **accept-category-rename**: Component MUST accept an optional `category.onRename` callback and pass it to `CategoryField`.
- **accept-tags-data**: Component MUST accept a `tags` object containing `label`, `noun`, `options`, `value` (array), and `onChange`; it MUST pass these to `TagSetField`.
- **disable-both-rows**: Component MUST pass the `disabled` prop (default `false`) to both `CategoryField` and `TagSetField`.
- **forward-classname**: Component MUST accept an optional `className` and merge it onto its root element so host styling composes with the component's own classes rather than replacing them.
- **use-gap-between-rows**: Component MUST apply 12px of vertical spacing between the two rows.
- **render-data-slot**: Component MUST set `data-slot="categories-and-tags"` on its root element.
- **require-category-label-noun**: `category.label` and `category.noun` are required (non-optional) string properties in the component's props type; the component MUST NOT supply a default value for either, and omitting either one MUST be a compile-time type error rather than a silent render with `undefined`.
- **require-tags-label-noun**: `tags.label` and `tags.noun` are required (non-optional) string properties in the component's props type; the component MUST NOT supply a default value for either, and omitting either one MUST be a compile-time type error rather than a silent render with `undefined`.
- **preserve-tab-order**: Component MUST render `CategoryField` before `TagSetField` in DOM order, so keyboard focus visits the category row before the tags row.

## Appearance

- **Container**: Flex column layout, full width, no fixed height.
- **Gap between rows**: 12px (Tailwind `gap-3` on React/Web; see Platform Notes for other platforms).
- **Label column width**: Set via the `FIELD_LABEL_GROUP_CLASS` class (`[--apt-field-label-w:6.5rem]`) applied to the root alongside its layout classes and any host `className`; the custom property cascades to both child rows. A host `className` that sets `--apt-field-label-w` again takes precedence through ordinary CSS cascade order (see Edge Cases).
- **Child rows**: Both use inline layout as defined by `CategoryField` and `TagSetField`.
- **No border, shadow, or background**: The component has no intrinsic visual styling; appearance is inherited from child components.

## States

| State | Appearance change |
|-------|------------------|
| Default | Both rows enabled and interactive, as defined by `CategoryField` and `TagSetField`. |
| Disabled | Both rows receive `disabled={true}` — see **disable-both-rows**. The visual and interactive disabled treatment is owned by the child components. |

## Accessibility

The root element is a plain `<div>`; it is not exposed as an ARIA group or `fieldset`, and carries no `role` of its own. DOM order determines tab order — see **preserve-tab-order** — so the category row is reachable before the tags row. All labels, roles, and other interactive accessibility semantics belong to `CategoryField` and `TagSetField`.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| cat-tag-001 | compose-two-fields, render-data-slot | Render with category and tags props | Root element renders with `data-slot="categories-and-tags"` and contains `CategoryField` before `TagSetField` in the DOM |
| cat-tag-002 | share-label-width | Render with both rows | Root element's class list includes the class emitted by `FIELD_LABEL_GROUP_CLASS` (`[--apt-field-label-w:6.5rem]`), setting the custom property via CSS rather than an inline style |
| cat-tag-003 | accept-category-data | `category.label="Type"`, `category.noun="type"`, `category.options=["A","B"]`, `category.value="A"`, `category.onChange=spy` | `CategoryField` receives `label`, `noun`, `options`, and `value` equal to the values in `category`; the `onChange` reference `CategoryField` receives is the same function passed as `category.onChange` |
| cat-tag-004 | accept-category-nodes | `category.nodes=[{...}]` present | `CategoryField` receives the same `nodes` array reference |
| cat-tag-005 | accept-category-rename | `category.onRename=spy` present | `CategoryField` receives the same `onRename` function reference |
| cat-tag-006 | accept-tags-data | `tags.label="Tags"`, `tags.noun="tag"`, `tags.options=["x","y"]`, `tags.value=["x"]`, `tags.onChange=spy` | `TagSetField` receives `label`, `noun`, `options`, and `value` equal to the values in `tags`; the `onChange` reference `TagSetField` receives is the same function passed as `tags.onChange` |
| cat-tag-007 | disable-both-rows | `disabled=true` | Both `CategoryField` and `TagSetField` receive `disabled={true}` |
| cat-tag-008 | forward-classname | `className="custom-class"` | Root element's classList includes `custom-class` alongside the component's own classes |
| cat-tag-009 | use-gap-between-rows | Render with both rows | Root element has 12px of vertical spacing between rows (`gap-3` class on React/Web) |
| cat-tag-010 | require-category-label-noun | Construct props with `category.label` or `category.noun` omitted | TypeScript fails to compile: both are required string properties, not optional |
| cat-tag-011 | require-tags-label-noun | Construct props with `tags.label` or `tags.noun` omitted | TypeScript fails to compile: both are required string properties, not optional |
| cat-tag-012 | preserve-tab-order | Render with both rows and tab in from outside the component | Focus lands on `CategoryField`'s first interactive control before `TagSetField`'s |

## Edge Cases

- **Empty category options list**: When `category.options` is an empty array, `CategoryField` receives it and determines rendering behavior; this component does not filter or default it.
- **Empty tags options list**: When `tags.options` is an empty array, `TagSetField` receives it and determines rendering behavior; this component does not filter or default it.
- **Empty category value**: When `category.value=""` (empty string), the component passes it through as-is; no category is selected.
- **Empty tags value array**: When `tags.value=[]` (empty array), no tags are selected; the component passes it through as-is.
- **Missing category.nodes**: When `category.nodes` is undefined or omitted, `CategoryField` receives undefined and operates without breadcrumb/rename support; this is valid.
- **Missing category.onRename**: When `category.onRename` is undefined or omitted, `CategoryField` receives undefined and rename behavior is disabled; this is valid.
- **Disabled state with active user interaction**: When `disabled=true`, both rows are marked disabled but still render; child components determine whether clicks or keyboard input are accepted.
- **className overriding label width**: When a host's `className` also sets `--apt-field-label-w`, the host's value wins: `cn()` places `className` last in the merged class list, and because the same custom property is set on the same element, ordinary CSS cascade order — not import order or specificity — decides the winner, so the later declaration applies without needing `!important`.

## Configuration

Not applicable: This component accepts props only; it does not expose configuration via environment variables, feature flags, or external settings.

## Deep Linking

Not applicable: This component is a form field, not a standalone route target. Deep linking behavior is the responsibility of the host application.

## Localization

Not applicable: The component does not emit any user-facing strings; all text (`category.label`, `category.noun`, `tags.label`, `tags.noun`) is supplied by the host and assumed to be localized before being passed to the component.

## Accessibility Options

Not applicable: Accessibility option handling (Reduce Motion, Increase Contrast, Differentiate Without Color) is delegated to child components `CategoryField` and `TagSetField`.

## Feature Flags

Not applicable: This component does not use feature flags. Feature flag gating is the responsibility of the host application.

## Analytics

Not applicable: This component emits no analytics events. Event tracking is delegated to the child components `CategoryField` and `TagSetField`, and to the host's application-level analytics.

## Privacy

Not applicable: This component stores no data, collects no user information, and transmits nothing. Data handling is the responsibility of the host application.

## Logging

Not applicable: This component performs no logging. Logging is delegated to child components and the host application.

## Platform Notes

- **React/Web**: Source implementation at `packages/web/packages/ui/src/blocks/categories-and-tags.tsx`. Uses Tailwind CSS (`flex`, `w-full`, `flex-col`, `gap-3`), the `cn()` utility for classname merging, and the `FIELD_LABEL_GROUP_CLASS` constant exported from the same package for shared label-width management. The component is marked "use client" for React Server Components compatibility.
- **SwiftUI**: Start with a `VStack(spacing: 12)` to replicate the flex column and gap. Compose a `CategoryField` view and a `TagSetField` view as children. Align both rows' label columns with a `Grid` using `gridColumnAlignment(.trailing)` on the label column (or, outside `Grid`, a shared alignment guide), rather than a custom environment key. Supply all label and noun strings via bindings from the host, matching the TypeScript interface exactly.
- **Compose**: Use a `Column(verticalArrangement = Arrangement.spacedBy(12.dp))` for the flex column and gap. Compose a `CategoryField` and `TagSetField` as children. Size the shared label column with an intrinsic-size measurement or `SubcomposeLayout` so both rows agree on its width, rather than a mutable state holder. Accept `label` and `noun` strings as parameters and pass them through; do not assume defaults.
- **AppKit / UIKit**: Stack a category control and a tag control vertically using `NSStackView` (AppKit) or `UIStackView` (UIKit) with spacing 12 and axis `.vertical`. Use a shared width constraint or layout guide to align labels. Accept label and noun strings as view configuration parameters, mirroring the TypeScript interface.
- **WinUI 3**: Use a `StackPanel` with `Orientation="Vertical"` and `Spacing="12"` (epx). Compose a category control and tag control as children. Synchronize label column width using a shared `double` property or `x:Bind` to a view model's label width value. All strings come from the host.

## Design Decisions

**Decision**: No default label or noun values — the component requires the host to supply `category.label`, `category.noun`, `tags.label`, and `tags.noun`.
**Rationale**: This avoids embedding assumptions about the semantic meaning of the fields (e.g., whether a field is for "categories" in a research system vs. "types" in a work-tracking system); the host controls all user-facing language.
**Approved**: pending

**Decision**: Share label alignment through the `--apt-field-label-w` CSS custom property rather than a fixed `labelWidth` prop.
**Rationale**: This lets sibling components (e.g., `document-identity-field.tsx`) that use the same `FIELD_LABEL_GROUP_CLASS` constant stay in alignment without duplicating the value, keeping one source of truth for the shared alignment strategy.
**Approved**: pending

**Decision**: A single `disabled` prop governs both rows.
**Rationale**: Both fields edit one logical draft or record, so they are disabled or enabled together; this prevents inconsistent states (e.g., category editable but tags read-only) and simplifies the host's state management.
**Approved**: pending

**Decision**: Neither `options` nor `value` is filtered or defaulted before being passed to the children.
**Rationale**: Empty arrays, undefined values, and missing optional properties all flow through as-is, keeping the component transparent and delegating validation and defaulting to the host.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | passed | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Focus-management passes because the source's render order (`CategoryField` before `TagSetField`, see **preserve-tab-order**) is what determines focus order and it is logical; keyboard-navigable and screen-reader-support are marked partial because full operability is owned by `CategoryField` and `TagSetField`, which this source file does not implement; no-hardcoded-strings passes because `label` and `noun` are required host-supplied props with no literal string fallback anywhere in the source. Best-practices statuses rest on `CategoriesAndTags` being pure composition of `CategoryField` and `TagSetField` with no embedded logic of its own (separation-of-concerns: passed), and on `categoriesAndTags.test.tsx` directly rendering the block and asserting its behavior across seven cases (unit-test-coverage: passed).

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names; documented prop types in Overview; made label/noun requirements compile-time-checked with corrected test vectors; restated className/gap requirements platform-neutrally; fixed SwiftUI/Compose/WinUI 3 platform notes; documented the Disabled state, tab order, and the CSS-cascade label-width override; replaced the N/A Compliance section with an evaluated table; reformatted Design Decisions; added depends-on/related links |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
