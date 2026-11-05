---
id: 85ce8c4b-5233-48af-9268-30cddd4747f9
title: Accordion
domain: adhsdk://recipes/accordion
type: ingredient
version: 1.2.2
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Stacked collapsible sections with clickable triggers and expanding/collapsing
  panels indicated by a rotating chevron.
platforms:
- typescript
- web
tags:
- ui
- collapsible
- expansion
depends-on:
- agenticdevelopercookbook://guidelines/implementing/ui/theming-with-tokens
related: []
references:
- https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
- https://www.w3.org/WAI/WCAG21/Understanding/target-size.html
- https://base-ui.com/react/components/accordion
- https://lucide.dev/guide/packages/lucide-react
approved-by: ''
approved-date: ''
---

# Accordion

## Overview

An accordion is a container of vertically stacked collapsible sections. Each section consists of a clickable trigger (header) and a hidden or visible panel (content area). The accordion exports four composable components: `Accordion` (root container), `AccordionItem` (section wrapper), `AccordionTrigger` (clickable header), and `AccordionPanel` (collapsible content area). Accordions compress long-form content into a scannable, space-efficient interface, allowing users to reveal only the information they need.

## Behavioral Requirements

- **export-four-components**: The accordion MUST export four components as named exports: `Accordion`, `AccordionItem`, `AccordionTrigger`, and `AccordionPanel`.
- **render-chevron-icon**: The `AccordionTrigger` MUST render a ChevronDown icon immediately after the trigger's child content, positioned to the right of the label.
- **rotate-chevron-on-open**: The chevron icon MUST rotate 180 degrees when its accordion panel is open (on web, Tailwind's `rotate-180` utility sets the CSS `rotate` property, not `transform`), and MUST return to its unrotated orientation when closed. The closed orientation (chevron pointing down, matching the typical placement of `AccordionTrigger` above its `AccordionPanel` within an `AccordionItem`) is a pure rotation and is not mirrored by RTL layout, so a right-to-left document uses the same closed/open chevron orientation as a left-to-right one.
- **apply-item-border**: `AccordionItem` MUST render a single-pixel bottom border between sections, using the design system's border token (`apt-border`).
- **wrap-panel-with-padding**: `AccordionPanel` MUST apply bottom spacing (12px) after its children to create visual separation from the next item's trigger or border.
- **delegate-expand-collapse-to-primitive**: All accordion components MUST delegate expand/collapse state, ARIA attribute management, and keyboard handling to the platform's accordion/disclosure primitive rather than reimplementing it.
- **set-data-slot-attributes**: The accordion MUST set `data-slot` attributes on rendered elements: "accordion" on root, "accordion-item" on items, "accordion-trigger" on triggers, "accordion-panel" on panels.
- **forward-props-to-primitive**: Each component MUST forward arbitrary props (via spread operator) to its corresponding primitive, allowing consumers to extend behavior and styling.
- **support-style-override**: Each component MUST provide a way for consumers to extend or override its default styling (a `className` prop merged with defaults on web) without needing to fork the component.
- **default-single-open**: The accordion MUST allow only one panel to be open at a time by default (the primitive's `multiple` prop defaults to `false`); consumers MAY allow multiple panels open simultaneously by passing `multiple` to `Accordion`.
- **animate-transitions**: The trigger MUST animate its color changes (`transition-colors`) and the chevron MUST animate its rotation (`transition-transform`); the panel wrapper also carries `transition-all`, but no class or inline style in the source gives it a size or opacity value to transition, so opening or closing a panel produces no observable size or opacity change on it. All of this is unconditional; the source contains no `prefers-reduced-motion` check, so the trigger and chevron transitions run the same way whether or not the user has Reduce Motion enabled.

## Appearance

- **Corner radius**: None (default; overridable via className prop)
- **Padding**: Trigger: 12px vertical (py-3), content-driven horizontal (no explicit left/right); Panel wrapper: 12px bottom (pb-3)
- **Font**: Trigger: 14px size (text-sm), 500 weight (font-medium); Panel: 14px size (text-sm)
- **Background**: Transparent (default; inherited from parent)
- **Foreground/Text**: Trigger default: apt-text; Trigger muted (chevron): apt-text-muted; Panel: apt-text-muted
- **Border**: Item: 1px solid bottom (border-b border-apt-border); Trigger: none; Panel: none
- **Shadow**: None
- **Min/Max size**: Chevron icon: 16×16px (size-4); no min/max constraints on root

## States

| State | Appearance change |
|-------|-------------------|
| Default (closed) | Chevron points downward (0 degrees); panel content hidden by overflow-hidden; trigger text in apt-text color |
| Hover | No visible color change — the trigger's hover state targets the same `apt-text` color as its default, so hovering the trigger produces no additional visual affordance beyond the pointer cursor |
| Focus (keyboard navigation) | `outline-none` suppresses the browser's default focus ring, and the trigger's focus-visible state also targets `apt-text`, matching its default — this component's own styles produce no visible focus indicator (see #requirements/support-style-override to add one via `className`) |
| Open/Expanded | Chevron rotates to 180 degrees (points upward); panel transitions open via overflow hidden animation; panel content visible |
| Closed/Collapsed | Chevron at 0 degrees (points downward); panel hidden via overflow-hidden; animation applies on close |

## Accessibility

- **Role/trait**: Trigger MUST be a button (delegated to AccordionPrimitive.Trigger). Panel MUST be a region (delegated to AccordionPrimitive.Panel).
- **Label requirements**: Trigger child content (text) serves as the accessible name for the accordion section. Screen readers announce this text when the trigger is focused.
- **State announcement**: The aria-expanded attribute on the trigger MUST reflect the panel's open/closed state and MUST be announced by screen readers.
- **Keyboard navigation**: Trigger MUST be keyboard accessible and respond to Enter and Space keys to toggle the panel (delegated to AccordionPrimitive.Trigger).
- **Minimum tap target**: Trigger touch target MUST be at least 24×24px (WCAG 2.2 SC 2.5.8, Level AA) — the level this ingredient commits to. Actual implementation depends on container padding and layout; current CSS (`py-3` plus `text-sm`'s line height) yields roughly a 44px-tall target, which also happens to satisfy the stricter 44×44px AAA target (WCAG 2.1 SC 2.5.5), though width is content-dependent since the trigger is `flex-1`.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| accordion-001 | export-four-components | `import { Accordion, AccordionItem, AccordionTrigger, AccordionPanel } from "..."` | All four components are named exports; no errors on import |
| accordion-002 | render-chevron-icon | Render `<AccordionTrigger>Section Title</AccordionTrigger>` | A `ChevronDown` icon element renders after the "Section Title" text node, inside the trigger |
| accordion-003 | rotate-chevron-on-open | Query trigger via `getByRole("button")`, click to open, then click again to close | On open: trigger's `aria-expanded` is `"true"` and the chevron's `getComputedStyle(...).rotate` is `"180deg"` (its computed `transform` stays `"none"`); on close: `aria-expanded` is `"false"` and the chevron's computed `rotate` is `"none"` |
| accordion-004 | apply-item-border | Render `<AccordionItem>...</AccordionItem>`; read `getComputedStyle(item).borderBottomWidth` and `.borderBottomColor` | `borderBottomWidth` is non-zero and `borderBottomColor` resolves to the `apt-border` token's color value |
| accordion-005 | wrap-panel-with-padding | Render `<AccordionPanel>Content</AccordionPanel>`; query the panel's content wrapper and read `getComputedStyle(...).paddingBottom` | `paddingBottom` resolves to 12px |
| accordion-006 | delegate-expand-collapse-to-primitive | Query trigger via `getByRole("button")` and panel via `getByRole("region")` | Trigger exposes `aria-expanded` and `aria-controls` referencing the panel's `id`; panel exposes a matching `id` — wiring supplied by the primitive rather than hand-set by the wrapper |
| accordion-007 | set-data-slot-attributes | Inspect rendered HTML elements | Root has `data-slot="accordion"`; items have `data-slot="accordion-item"`; triggers have `data-slot="accordion-trigger"`; panels have `data-slot="accordion-panel"` |
| accordion-008 | forward-props-to-primitive | Pass `disabled` and `value` props to `AccordionItem` | Rendered element carries the `disabled` state (e.g., `aria-disabled="true"` or `data-disabled`) and responds to the `value` used by the primitive for open/close targeting |
| accordion-009 | support-style-override | Render `<AccordionTrigger className="my-custom-class">Label</AccordionTrigger>`; query via `getByRole("button")` | `element.classList.contains("my-custom-class")` is `true` |
| accordion-010 | default-single-open | Render two `AccordionItem`s in a default `Accordion` (no `multiple` prop); open trigger 1, then open trigger 2 | Trigger 1's `aria-expanded` returns to `"false"` once trigger 2 opens; the two triggers never both report `aria-expanded="true"` at the same time |
| accordion-011 | animate-transitions | Open a panel | Computed `transition-property` of the trigger includes its color properties, of the chevron includes `transform`, and of the panel includes `all`; the chevron's computed `rotate` is `180deg` while the panel is open, and the panel itself shows no observable size or opacity change. |

## Edge Cases

- **Empty trigger text**: If `AccordionTrigger` receives no children or null children, chevron MUST still render and rotate on panel open. Screen reader announcement is degraded but component does not error.
- **Empty panel content**: If `AccordionPanel` receives no children or null children, wrapper div with pb-3 still renders. Component does not error.
- **Null or undefined className**: If className prop is null, undefined, or omitted, default classes MUST apply via `cn()` utility. No runtime error occurs.
- **Conflicting className properties**: If className prop contains a Tailwind class that conflicts with a default class (e.g., py-4 vs. py-3), the merge order in `cn()` determines precedence. Consumers who specify a class take precedence over defaults.
- **Only one panel open by default**: MUST default to single-open — see #requirements/default-single-open. Passing `multiple` to `Accordion` allows multiple panels to be open simultaneously.
- **Very long trigger text**: No special handling; text wraps naturally. Chevron remains positioned to the right via flex layout (flex flex-1 items-center justify-between).
- **Very long panel content**: No special handling; panel height is not constrained. Consumers can add max-height and overflow-y: auto via className if needed.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `className` (all components) | `string` | `undefined` | Additional CSS classes merged with defaults via the `cn()` utility; allows customization of appearance and layout |
| `children` (all components) | `ReactNode` | `undefined` | Content rendered inside: trigger text for AccordionTrigger, panel content for AccordionPanel |
| `...props` (`Accordion`) | `React.ComponentProps<typeof AccordionPrimitive.Root>` | — | Root-level props forwarded to the primitive, e.g. `multiple`, `value`, `defaultValue`, `onValueChange`, `disabled` |
| `...props` (`AccordionItem`) | `React.ComponentProps<typeof AccordionPrimitive.Item>` | — | Item-level props forwarded to the primitive, e.g. `value`, `disabled` |
| `...props` (`AccordionTrigger`) | `React.ComponentProps<typeof AccordionPrimitive.Trigger>` | — | Trigger-level props forwarded to the primitive |
| `...props` (`AccordionPanel`) | `React.ComponentProps<typeof AccordionPrimitive.Panel>` | — | Panel-level props forwarded to the primitive |

## Deep Linking

Not applicable: Accordion is a UI component with no built-in deep linking support. Deep linking to accordion sections is handled by parent page/routing logic if needed.

## Localization

Not applicable: Component contains no hardcoded user-facing strings. All text (trigger labels, panel content) is provided by consumers via children prop.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not handled: the transitions in **animate-transitions** run regardless of `prefers-reduced-motion: reduce`; the source contains no reduced-motion check. |
| Increase Contrast | Design system color tokens (apt-text, apt-text-muted, apt-border) SHOULD be defined with sufficient contrast to meet WCAG 2.1 AA standards (4.5:1 for text). Component itself does not implement special handling for prefers-contrast media query; contrast depends on token values. |
| Differentiate Without Color | Chevron icon direction (down = closed, up = open) provides state indication independent of color. The aria-expanded attribute provides semantic indication for assistive technology. |

## Feature Flags

Not applicable: Feature flag support is not a concern of the accordion component itself. If the design system requires feature-gating accordion, consumers can wrap the component or control its visibility via app-level feature flag logic.

## Analytics

Not applicable: Analytics event tracking is not a component-level concern. Consumers can attach custom event handlers via props passed to AccordionPrimitive components to emit analytics events (e.g., on expand, collapse, focus).

## Privacy

Not applicable: Component collects no user data and transmits nothing. Consumers using the accordion do not expose private information through the component itself.

## Logging

Not applicable: Logging is a consumer concern. The underlying @base-ui/react/accordion library may emit logs; consumers can enable logging if needed for debugging.

## Platform Notes

- **React/Web**: Wraps `@base-ui/react/accordion` (`AccordionPrimitive.Root`, `.Item`, `.Trigger`/`.Header`, `.Panel`), which supplies ARIA attributes, keyboard handling, and the `multiple` prop (default `false`; pass `true` for multi-open). Styling uses Tailwind classes merged via the `cn()` utility (`className` prop on every component): `border-b border-apt-border` on `AccordionItem`, `pb-3` on the panel's inner wrapper `div`, `py-3 text-sm font-medium text-apt-text` plus `hover:text-apt-text focus-visible:text-apt-text` (currently a no-op — see States) on the trigger, and `size-4 shrink-0 text-apt-text-muted transition-transform group-data-[panel-open]/acc:rotate-180` on the chevron. Exported `"use client"`. The `ChevronDown` icon is from `lucide-react`. Transitions (`transition-colors`, `transition-transform`) are unconditional and do not check `prefers-reduced-motion` (see #requirements/animate-transitions).

- **SwiftUI**: Start from DisclosureGroup or a custom view with @State for open/closed. Recreate chevron rotation using a rotation effect (.rotationEffect) on Image(systemName: "chevron.down"). Wrap each item in a VStack with dividers between sections. Apply padding using .padding(.vertical, 12) and .padding(.horizontal) modifiers. Text styling via .font(.system(size: 14, weight: .medium)). Respect motion preferences by wrapping rotation animations in `if !accessibilityReduceMotionEnabled { ... }`.

- **Compose**: Use LazyColumn or Column for the container and Surface or Card for each item. Implement expand/collapse via state and AnimatedVisibility or animateContentSize for panel animation. Render a rotating Icon (Icons.Default.ArrowDown) with rotationZ = if (isOpen) 180f else 0f. Use Spacer and Padding for spacing. Font styling via fontSize and fontWeight parameters. Conditionally apply animations based on the LocalMotionSettings or animate conditionally when prefers-reduced-motion is not set.

- **UIKit / AppKit**: For UIKit, use UITableViewController or UICollectionViewController with custom cells for trigger and collapsible panels. Implement disclosure via state callbacks and setContentOffset or similar scroll logic. Use CABasicAnimation for chevron rotation (CABasicAnimation(keyPath: "transform.rotation.z")). Disable animations when UIAccessibility.isReduceMotionEnabled is true. For AppKit, use NSOutlineView or NSViewController with collapsible subviews. Both require manual chevron rotation animation and state management, with motion preference checks to conditionally apply animations.

- **WinUI 3**: Implement using ItemsControl with Expander control (which provides native expand/collapse functionality and chevron). Set Expander.Header to trigger content and Expander.Content to panel content. Use StackPanel set to Vertical for the item container. Apply borders via Border.Stroke property. Styling via Foreground (text color), Background, and FontSize properties. WinUI's Expander natively provides ARIA attributes (aria-expanded, button role), keyboard support (Enter/Space), and rotation animation on the toggle button. When implementing custom animations, check UISettings.AnimationsEnabled or SystemParameters.ReduceMotionEnabled to conditionally apply motion.

## Design Decisions

1. **Decision**: Export `Accordion`, `AccordionItem`, `AccordionTrigger`, and `AccordionPanel` as four separate, composable components rather than one monolithic component.
   **Rationale**: Follows the composition pattern established by `@base-ui/react/accordion` and gives consumers maximum flexibility to customize each part independently.
   **Approved**: pending

2. **Decision**: Rotate the chevron 180 degrees via Tailwind's `rotate-180` utility (which sets the CSS `rotate` property, not `transform`) to indicate open/closed state, rather than swapping icons.
   **Rationale**: A recognizable UI pattern that gives clear visual feedback and animates more smoothly than swapping images.
   **Approved**: pending

3. **Decision**: Wrap panel content in an inner `div` with fixed bottom padding (`pb-3`, 12px) rather than leaving spacing to consumers.
   **Rationale**: Creates consistent visual breathing room between the panel content and the next item's border/trigger by default; consumers can still override via `className`.
   **Approved**: pending

4. **Decision**: Set a `data-slot` attribute on every rendered element (`accordion`, `accordion-item`, `accordion-trigger`, `accordion-panel`).
   **Rationale**: Enables predictable CSS targeting (e.g. `[data-slot="accordion-trigger"]`) and makes automated testing more stable by decoupling tests from class names, which may change.
   **Approved**: pending

5. **Decision**: Delegate all expand/collapse logic, ARIA attribute management, and keyboard handling to the underlying primitive library (`@base-ui/react/accordion` on web).
   **Rationale**: Keeps the wrapper lightweight and keeps WCAG conformance current as the primitive is updated, rather than reimplementing accessible disclosure behavior per platform.
   **Approved**: pending

6. **Decision**: Ship `transition-colors` and `transition-transform` on the trigger and chevron unconditionally, without checking `prefers-reduced-motion`.
   **Rationale**: Smooth transitions are the intended default feedback, but shipping them unconditionally means the component does not honor `prefers-reduced-motion` (see **animate-transitions**); fixing that means conditionally disabling the transitions inside the component, not asking consumers to patch around them with their own media-query overrides.
   **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | partial | Accessibility |
| [reduced-motion](agenticdevelopercookbook://compliance/accessibility#reduced-motion) | failed | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | partial | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | passed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | passed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | passed | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | partial | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Accessibility statuses rest on `accordion.tsx`'s delegation of ARIA/keyboard/role semantics to `AccordionPrimitive.*` (passed: keyboard-navigable, semantic-markup), rem-based Tailwind type sizing (passed: dynamic-type-support), the undefined `apt-*` token contrast values and unverified pixel target width (partial: contrast-ratio, touch-target-size), the undecorated chevron icon with no explicit `aria-hidden` (partial: screen-reader-support), the `outline-none` trigger whose focus-visible color matches its default (partial: focus-management), and the unconditional `transition-colors`/`transition-transform` with no `prefers-reduced-motion` check (failed: reduced-motion); Internationalization statuses rest on the component rendering only consumer-supplied `children` with no hardcoded or formatted strings (passed) and the unverified behavior of its `flex`/`gap`/`justify-between` layout under RTL (partial: rtl-layout-support). `separation-of-concerns` passes because `accordion.tsx` only forwards props and Tailwind classes onto `AccordionPrimitive.*`, with no business logic entangled in the wrapper. `unit-test-coverage` fails because no test file in the `ui` package exercises `Accordion`.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.2 | 2026-09-25 | Mike Fullerton | Change History reordered (1.2.1 moved to top) per Altitude_7/K14f; Compliance best-practices rows added. |
| 1.2.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; restated Tailwind/base-ui-specific requirements as behavior plus tokens and moved the implementation specifics into the React/Web platform note; added default-multi-open and animate-transitions requirements with test vectors; dropped the no-op hover/focus color claims and rewrote the States table to match; resolved the Reduce Motion contradiction between Design Decisions and Accessibility Options and reformatted Design Decisions to the three-line form; rebuilt Compliance as linked catalog checks with evidence; rewrote non-automatable test vectors against the DOM/accessibility tree; corrected the touch-target WCAG citation and level; split Configuration by component; populated references and depends-on |
| 1.1.0 | 2026-09-22 | Claude Haiku 4.5 | Revise: clarify Reduce Motion gap as genuine accessibility concern; update Platform Notes with motion preference checks for all platforms |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from web source |
