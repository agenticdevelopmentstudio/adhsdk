---
id: f09feb7c-6778-445a-8a68-863c5d60b5cc
title: "CollapseToggle"
type: ingredient
version: 1.2.2
status: review
language: en
created: 2026-09-22
modified: 2026-09-25
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "A simple toggle button for collapsible sections using directional glyphs (» / «) to indicate state."
platforms:
  - typescript
  - web
tags:
  - ui
  - button
  - disclosure
depends-on: []
related: []
references: []
approved-by: ""
approved-date: ""
---

# CollapseToggle

## Overview

A minimal toggle control that switches between expanded and collapsed states of a region or list. The component displays a directional glyph (» when collapsed, « when expanded) and is intended for use in layouts where custom collapsible behavior is desired — such as rail navigation, side panels, or column lists. It is not a full disclosure component; it provides only the toggle mechanism and leaves layout decisions to the caller.

## Behavioral Requirements

- **click-invokes-on-toggle**: Clicking the button MUST invoke the `onToggle` callback with the click event.
- **forwarded-click-event**: The `onToggle` callback MUST receive the React `MouseEvent` so the caller can inspect modifier keys (Ctrl/⌘-click).
- **glyph-when-collapsed**: When `collapsed` is `true`, the button MUST display the `»` (RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK, U+00BB) glyph.
- **glyph-when-expanded**: When `collapsed` is `false`, the button MUST display the `«` (LEFT-POINTING DOUBLE ANGLE QUOTATION MARK, U+00AB) glyph.
- **aria-label-text**: The button's `aria-label` MUST be set to "Collapse {label}" when `collapsed` is `false`, and "Expand {label}" when `collapsed` is `true`, where `{label}` is the value of the `label` prop.
- **aria-expanded-state**: The button's `aria-expanded` attribute MUST be set to `true` when `collapsed` is `false`, and `false` when `collapsed` is `true`.
- **title-attribute-text**: The button's `title` attribute MUST match the `aria-label` value to provide tooltip text.
- **button-type**: The button element MUST have `type="button"` to prevent form submission.
- **aria-controls-optional**: If the `controls` prop is provided, the button's `aria-controls` attribute SHOULD be set to that value to indicate the region being toggled.
- **classname-merge**: The component MUST accept an optional `className` prop and apply it to the button element; when a caller class conflicts with one of the component's default classes for the same CSS property, the caller's class MUST override the default.

## Appearance

- **Corner radius**: Rounded corners (`rounded` in Tailwind, 0.25rem or 4px)
- **Padding**: `px-1` (0.25rem horizontal, no explicit vertical padding)
- **Font**: Font family monospace (`font-mono`); weight and size are inherited from the parent, not set by the component
- **Background**: Transparent (no background color specified)
- **Foreground/Text**: Muted text color by default (`text-apt-text-muted`), changes to primary text color on hover (`hover:text-apt-text`)
- **Border**: None specified
- **Shadow**: None
- **Min/Max size**: No explicit constraints; size is determined by font size and padding

## States

| State | Appearance change |
|-------|------------------|
| Default | Muted text color, no outline |
| Hover | Text color changes to primary (`text-apt-text`) |
| Focus-visible | Gold ring outline (`focus-visible:ring-2 focus-visible:ring-apt-gold/40`) at 40% opacity |
| Collapsed | Displays `»` glyph |
| Expanded | Displays `«` glyph |

## Accessibility

- **Role**: Button (semantic `<button>` element)
- **Label requirements**: The `aria-label` is always present and dynamically set based on state. The label MUST include the region name from the `label` prop so users understand what is being toggled.
- **State announcement**: The `aria-expanded` attribute indicates the expanded/collapsed state to assistive technologies.
- **Region association**: When `controls` is provided, `aria-controls` links the button to the region it controls, allowing assistive technology users to navigate directly to that region.
- **Keyboard navigation**: The button is keyboard-accessible via the standard HTML button element; keyboard focus is visible via the `focus-visible:ring` style.
- **minimum-tap-target**: NEEDS REVIEW: Not implemented in source. The source applies `px-1` (0.25rem horizontal padding) and no width, height, or minimum-size rule, so the hit area is exactly the inherited `font-mono` glyph box plus that padding — at a typical 14px rail font this lands well under the 44×44pt target the ingredient template names; measuring the rendered button at its two call sites (the TopicDetail rail and the theme-editor column list) against the 44×44pt floor, plus a decision on whether to pad the button itself or enlarge the surrounding row's hit area, would settle it.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| collapse-toggle-001 | glyph-when-collapsed | `collapsed={true}, label="Topic List"` | Button displays `»` glyph |
| collapse-toggle-002 | glyph-when-expanded | `collapsed={false}, label="Topic List"` | Button displays `«` glyph |
| collapse-toggle-003 | aria-label-text | `collapsed={true}, label="Topic List"` | `aria-label="Expand Topic List"` |
| collapse-toggle-004 | aria-label-text | `collapsed={false}, label="Topic List"` | `aria-label="Collapse Topic List"` |
| collapse-toggle-005 | aria-expanded-state | `collapsed={true}` | `aria-expanded="false"` |
| collapse-toggle-006 | aria-expanded-state | `collapsed={false}` | `aria-expanded="true"` |
| collapse-toggle-007 | title-attribute-text | `collapsed={true}, label="Items"` | `title="Expand Items"` |
| collapse-toggle-008 | button-type | Any props | `type="button"` on element |
| collapse-toggle-009 | click-invokes-on-toggle | User clicks button | `onToggle` callback invoked with click event |
| collapse-toggle-010 | forwarded-click-event | User Ctrl+clicks button | `onToggle` callback receives event with `ctrlKey=true` |
| collapse-toggle-011 | aria-controls-optional | `controls="item-list"` | `aria-controls="item-list"` |
| collapse-toggle-012 | aria-controls-optional | `controls` not provided | `aria-controls` attribute is absent |
| collapse-toggle-013 | classname-merge | `className="custom-class"` | Custom class appears in rendered button className |
| collapse-toggle-014 | click-invokes-on-toggle | User focuses the button and presses Enter or Space | `onToggle` callback invoked with the resulting click event (native `<button>` key-activation behavior) |
| collapse-toggle-015 | forwarded-click-event | User ⌘-clicks the button | `onToggle` callback receives the event with `metaKey=true` |

## Edge Cases

- **Empty, null, or missing label**: `label` is typed as a required `string`, so omitting it is a compile-time error. At runtime the source interpolates `label` straight into `${collapsed ? "Expand" : "Collapse"} ${label}` with no guard, trim, or fallback: an empty string produces the verb followed by a trailing space — `aria-label="Expand "` and the same value in `title` — and the button still renders its glyph and still fires `onToggle`. If `null`/`undefined` reaches the component at runtime anyway (bypassing the type system), it is interpolated as the literal text `"null"` or `"undefined"` (e.g. `aria-label="Expand undefined"`). Implementations MUST reproduce this pass-through behavior and MUST NOT substitute a default region name.
- **Label contains special characters**: The label is interpolated verbatim into the template literal that builds `aria-label` and `title`, with no escaping, trimming, or HTML-interpretation step. Behavior: whatever string is passed (quotes, symbols, markup-looking text) is rendered as-is into the accessible name and tooltip, and is never HTML-interpreted.
- **Multiple rapid clicks**: Each click triggers `onToggle`. The caller is responsible for debouncing or state management; the component renders only the current `collapsed` state.
- **`controls` prop targets non-existent element**: If `aria-controls` points to an element that does not exist, no runtime error occurs; the attribute is still set. Assistive technology behavior is undefined.
- **Dynamic className changes**: If `className` is updated while the button is rendered, the new class is applied immediately via the class-merging utility.
- **Very long label text**: No truncation or overflow handling in the component; label length is unconstrained. The aria-label will be long but valid; visual overflow depends on parent container.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `collapsed` | `boolean` | — | Required. Current collapse state; `true` = collapsed, `false` = expanded. |
| `onToggle` | `(e: MouseEvent<HTMLButtonElement>) => void` | — | Required. Callback invoked when button is clicked. Receives React MouseEvent for modifier key inspection. |
| `label` | `string` | — | Required. Region name for aria-label; appears in accessible label as "Expand {label}" or "Collapse {label}". |
| `controls` | `string \| undefined` | `undefined` | Optional. `id` of the region this button controls; passed to `aria-controls`. |
| `className` | `string \| undefined` | `undefined` | Optional. Additional CSS class(es) merged with component defaults via class utility. |

## Deep Linking

Not applicable: CollapseToggle is a stateless UI primitive without its own route or deep-linking behavior. State (collapsed/expanded) is managed by the parent component, and the button itself has no URI identity.

## Localization

The verbs "Expand" and "Collapse" are hard-coded English string literals inside the component. The source contains no string table, no message catalogue, no locale parameter, and no lookup call — the two words are written directly into the template literal that builds `aria-label` and `title`.

Everything else in the accessible name comes from the caller: `label` is interpolated verbatim, so the caller is the party that supplies a localized region name. A caller passing a localized `label` into this component gets a mixed-language accessible name (for example "Expand Themenliste") until the consuming application localizes the two verbs as well. Implementations that need a fully localized name MUST source the verbs from their own catalogue rather than from this component.

The glyphs `»` and `«` are literal characters in the JSX and are not mirrored, re-selected, or swapped for right-to-left locales.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | The source declares no `transition-*`, `animate-*`, or duration class; the swap between `»` and `«` and the hover color change are instant re-renders. No transition is applied; nothing to disable under Reduce Motion. |
| Increase Contrast | The source pins the foreground to the `apt-text-muted` token, raises it to `apt-text` on hover, and draws the focus ring as `apt-gold/40`. It declares no high-contrast variant and no `prefers-contrast` query, so the contrast delivered is whatever those tokens resolve to in the active theme. Implementations MUST use the same tokens rather than substituting fixed color values, so a theme that raises contrast raises this control's contrast with it. |
| Differentiate Without Color | Color is never the sole carrier of state. Collapsed versus expanded is carried by the glyph shape (`»` versus `«`), by `aria-expanded`, and by the `aria-label`/`title` text, none of which depend on color. The one color-only change in the source is the `hover:text-apt-text` shift, which signals pointer position rather than component state. |

The component also inherits the platform's focus-visible behavior: the `focus-visible:ring-2` style paints only when the browser judges focus to be keyboard-driven.

## Feature Flags

Not applicable: CollapseToggle is a stateless primitive with no feature-flag control. Feature flags (if needed) would be the responsibility of the consuming component.

## Analytics

Not applicable: The component does not emit analytics events. Analytics tracking (if desired) would be the caller's responsibility in the `onToggle` callback.

## Privacy

Not applicable: CollapseToggle collects no data, stores no state persistently, and transmits nothing. All state is ephemeral and managed by the parent component.

## Logging

Not applicable: The component has no built-in logging or diagnostic output.

## Platform Notes

- **React/Web (source)**: The component is defined in `packages/web/packages/ui/src/components/collapse-toggle.tsx`. It uses React hooks conventions (functional component), standard HTML button element with ARIA attributes, and Tailwind CSS for styling via a `cn()` utility function. The click handler is a React `MouseEvent<HTMLButtonElement>`.
- **SwiftUI**: No direct equivalent in SwiftUI's component library. Build a custom `Button` with a conditional glyph — SF Symbols `chevron.right`/`chevron.left` (the platform substitution recorded in Design Decisions), or the literal `»`/`«` characters in a `Text` view for exact visual parity. Apply `.accessibilityLabel()` for the "Expand/Collapse {label}" text, and `.accessibilityValue()` (e.g. "collapsed"/"expanded") so the state itself is exposed to VoiceOver — the label text alone does not convey state the way `aria-expanded` does.
- **Compose (Android/Kotlin)**: Use `Button` or `IconButton` with a conditional `Icon` (Material Icons chevron left/right, the same platform substitution). Apply `contentDescription` with dynamic text matching the source's aria-label pattern, and expose the expanded/collapsed state via `Modifier.semantics { stateDescription = if (collapsed) "collapsed" else "expanded" }` or the `expand`/`collapse` semantics actions — Compose has no `expandedState` semantics property.
- **AppKit / UIKit**: On macOS, use `NSButton` with `setButtonType(.momentaryChange)` and toggle images (or the literal `»`/`«` glyph as the button's title). Expose the expanded/collapsed state through the `NSAccessibilityProtocol` methods `isAccessibilityExpanded()` / `setAccessibilityExpanded()` (`NSAccessibilityExpanded`), not `accessibilityHint`, which does not map to `aria-expanded`. On iOS, use `UIButton` with `configurationUpdateHandler` to swap images; UIKit has no expanded/collapsed accessibility concept, so set `accessibilityValue` to "expanded"/"collapsed" to carry the state, and `accessibilityLabel` for the "Expand/Collapse {label}" text. Assign `accessibilityTraits = .button`.
- **WinUI 3**: Use a `Button` control with a `TextBlock` displaying the `»` or `«` character (U+00BB, U+00AB). Set `AutomationProperties.Name` to the state-dependent label ("Expand {label}" / "Collapse {label}"), and implement the `IExpandCollapseProvider` automation pattern (`ExpandCollapseState.Expanded` / `.Collapsed`) so assistive technology receives the state the way `aria-expanded` does on web. Use a `VisualStateManager` state group to apply hover and focus styles. The `Click` event handler receives the click source; detect modifier keys via `InputKeyboardSource.GetKeyStateForCurrentThread` if modifier inspection is needed.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/components/collapse-toggle.tsx` | unverified |

## Design Decisions

1. **Unicode glyphs for state indication**
   **Decision**: The component uses `»` (RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK, U+00BB) for collapsed and `«` (LEFT-POINTING DOUBLE ANGLE QUOTATION MARK, U+00AB) for expanded — not chevron icons or an image asset — and the glyph is fixed on purpose; the component does not expose a way to swap in different glyphs (arrows, +/-, etc.).
   **Rationale**: A single character needs no icon asset and follows the direction convention of "closed" (pointing away) versus "open" (pointing inward).
   **Approved**: pending

2. **Platform glyph substitution**
   **Decision**: Native platforms other than WinUI 3 substitute a platform-native chevron icon (SF Symbols `chevron.right`/`chevron.left` on Apple platforms, Material Icons chevron left/right on Compose) for the literal `»`/`«` characters; only the WinUI 3 note renders the same U+00BB/U+00AB characters the web source does.
   **Rationale**: Apple and Android platform conventions render this kind of iconography through vector icon assets rather than a typographic character in a text control, so requiring the literal character everywhere would fight the platform's own idioms; WinUI 3's `TextBlock`-based button has no equivalent native chevron icon control, so it keeps the literal character.
   **Approved**: pending

3. **Event forwarding in onToggle**
   **Decision**: The `onToggle` callback receives the full React `MouseEvent` rather than just a boolean.
   **Rationale**: This enables callers to detect Ctrl/⌘-click for hierarchical toggle behavior (noted in the source comment: "apply this toggle to every list"). This trades callback simplicity for power; callers uninterested in modifiers ignore the event parameter.
   **Approved**: pending

4. **aria-expanded always inverted from collapsed**
   **Decision**: The `aria-expanded` attribute is set to `!collapsed` (the opposite of the `collapsed` prop).
   **Rationale**: This ensures the accessible state always reflects the logical expanded state of the controlled region: when `collapsed=true` (user sees the "expand" label and `»` glyph), `aria-expanded=false` signals the region is not yet expanded. This is the correct ARIA mapping.
   **Approved**: pending

5. **No size constraints**
   **Decision**: The button's size is determined entirely by the inherited font size plus the `px-1` padding; the source sets no width, height, or minimum.
   **Rationale**: This is a deliberate trade for placement flexibility — the same control sits in a narrow rail beside TopicDetail and in the theme-editor's column headers — and it moves responsibility for the hit area onto the caller's layout. The Accessibility section records the open question of what minimum that layout has to guarantee.
   **Approved**: pending

6. **Title attribute mirrors aria-label**
   **Decision**: The `title` attribute is set to the same text as `aria-label`.
   **Rationale**: This provides a tooltip for mouse users without duplicating logic; however, it means the tooltip also says "Expand {label}" or "Collapse {label}", which is self-evident to sighted users and potentially redundant.
   **Approved**: pending

7. **Minimum hit area is undecided**
   **Decision**: Whether the toggle button itself must guarantee a minimum 44×44pt/48×48dp hit area, or whether that responsibility stays with the caller's surrounding row layout, is undecided.
   **Rationale**: The source sets no width, height, or minimum size — only `px-1` padding — so at typical rail font sizes the rendered hit area falls under the platform minimum tap-target guidelines (see `#accessibility`). Settling this requires measuring the rendered button at its two call sites (TopicDetail rail, theme-editor column list) against the 44×44pt floor.
   **Approved**: pending

8. **RTL glyph mirroring is undecided**
   **Decision**: Whether the `»`/`«` glyphs should mirror (swap) for right-to-left locales is undecided.
   **Rationale**: The source hardcodes the glyphs as literal, unmirrored characters (see `#localization`); a caller in an RTL locale sees the same visual direction as in LTR, which may read backwards for languages where "closed" and "open" reverse convention.
   **Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.touch-target-size](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5b4e41dc-8362-5dad-aa80-f1b5500ed1f2) | failed | Accessibility |
| [adc.check.accessibility.reduced-motion](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/412a8e85-ad91-5e53-b3ee-ae938dda2538) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | failed | Internationalization |
| [adc.check.internationalization.text-expansion-tolerance](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8007859b-a974-5b8a-88f7-162624b0c056) | partial | Internationalization |
| [adc.check.internationalization.unicode-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d255b8aa-7379-52ef-b4e8-b08386ba6aac) | passed | Internationalization |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | failed | Best Practices |

The `passed` rows rest on the source's literal ARIA attributes and native `<button>` semantics, its absence of any `transition-*`/`animate-*` class, and `label`'s untouched pass-through of any Unicode input; the `failed` rows rest on the source's own hardcoded English verbs, its unmirrored `»`/`«` glyphs, and its documented under-44×44pt hit area; the `partial` rows reflect that the source inherits font size and theme color/spacing tokens whose actual scaling, contrast, and overflow behavior the source code cannot itself confirm. separation-of-concerns passes because `CollapseToggle` is pure presentation over its `collapsed`/`onToggle`/`label` props with no logic beyond a template string, while unit-test-coverage is failed because no test file exercises this component at all.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.2.2 | 2026-09-25 | Mike Fullerton | Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.2.1 | 2026-09-24 | Mike Fullerton | Phase 6 lint: re-audited open-question markers against the marker rules; kept markers are one-line named bullets. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case with citations updated throughout; corrected glyph terminology (guillemets, not chevrons) and platform API names (Compose semantics, WinUI keyboard-state API, WinUI ExpandCollapse pattern, AppKit/UIKit state exposure); reformatted Design Decisions and Compliance to the standard form and corrected appearance values (corner radius, font, focus-ring color); added keyboard-activation and ⌘-click test vectors, tightened the aria-controls-absent vector, and merged the duplicate empty/missing-label edge cases; recorded platform-glyph-substitution, minimum-hit-area, and RTL-glyph-mirroring as pending Design Decisions |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Replace unresolved review markers with the source's actual behavior for empty label, localization, and accessibility display options; narrow the open tap-target question to the Accessibility section |
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation from source at packages/web/packages/ui/src/components/collapse-toggle.tsx |
