---
id: b329d08b-9812-47d0-8094-516359d82d19
title: ExternalLink
domain: adhsdk://recipes/external-link
type: ingredient
version: 1.3.1
status: review
language: en
created: '2026-07-03'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: 'The "{label} ↗" deep-link anchor: always opens a new tab with safe rel; small mono info-blue skin, optional glyph.'
platforms:
  - typescript
  - web
tags:
  - component
  - link
  - navigation
  - ui
depends-on: []
related:
  - adhsdk://recipes/stat-card
  - adhsdk://recipes/user-card
references: []
approved-by: ''
approved-date: ''
---

# ExternalLink

## Overview

The shared `ExternalLink` in `@adh-sdk/ui` — the "{label} ↗" deep link out of
the app: an anchor that **always opens in a new tab** (`target="_blank"`) with
the safe `rel="noopener noreferrer"`, ending in a trailing ↗ arrow affordance.
Its default skin is the dashboard deep-link grammar — small, mono, info-blue,
`whitespace-nowrap` — the look used for "PostHog ↗" / "GlitchTip ↗" jump-outs to
external tools.

The component is deliberately thin: it spreads native anchor props
(`React.ComponentProps<"a">`), so `href`, `onClick`, `title`, `data-*` and the
rest pass straight through, and it merges an optional `className` via `cn()` for
restyling. Two consumption modes exist. **Default:** trailing glyph on, for a
standalone deep link. **`glyph={false}`:** drop the arrow when a *leading* icon
already carries the "external" meaning — UserCard's social links do this
(lucide `ExternalLink` icon + restyled to sans, muted text), and StatCard puts
the default-skin link in its header actions slot.

A single export ships from `@adh-sdk/ui/components/external-link`: the
`ExternalLink` component. It is a stateless anchor with no `"use client"`
directive.

## Behavioral Requirements

- **opens-new-tab**: The component MUST set `target="_blank"` so the link opens in a new browsing context.
- **applies-safe-rel**: The component MUST set `rel="noopener noreferrer"` so the opened tab cannot access `window.opener` or leak a referrer.
- **renders-trailing-glyph-by-default**: With no `glyph` prop (default `true`), the component MUST render a trailing `↗` glyph after the children.
- **glyph-is-decorative**: The component MUST mark the `↗` glyph `aria-hidden="true"` so it is not read as part of the link's accessible name.
- **suppresses-glyph-when-false**: Given `glyph={false}`, the component MUST NOT render the `↗` glyph (so a leading icon can carry the affordance).
- **default-deep-link-skin**: The component MUST default to the deep-link grammar — inline-flex, `font-mono`, `text-[11px]`, `text-apt-blue`, no underline, `whitespace-nowrap`.
- **focus-ring**: The component MUST show a visible focus ring on keyboard focus (`focus-visible:ring-2 focus-visible:ring-apt-gold/40`).
- **merges-classname**: The component MUST merge any `className` after the base classes via `cn()`, so a consumer MAY restyle it (font, color, gap) without losing the new-tab/rel behavior.
- **forwards-anchor-props**: The component MUST forward native anchor props (`href`, `onClick`, `title`, `data-*`, …) onto the underlying `<a>`.
- **safe-attrs-not-overridable**: The component MUST apply `target="_blank"` and `rel="noopener noreferrer"` after spreading `...props`, so a caller-supplied `target` or `rel` prop cannot override the safe new-tab contract.

## Appearance

```
default            PostHog ↗          (mono · text-[11px] · apt-blue · trailing arrow)
glyph={false}      ⤴ GitHub           (leading lucide icon; no trailing arrow; restyled)
```

- Base: `inline-flex items-center gap-1 rounded-sm font-mono text-[11px]
  whitespace-nowrap text-apt-blue no-underline outline-none
  focus-visible:ring-2 focus-visible:ring-apt-gold/40`.
- Trailing glyph: a `<span aria-hidden="true">↗</span>` rendered only when
  `glyph` is truthy (default).
- Restyle path: `className` is `cn()`-merged last, so a consumer can override
  font (`font-sans`), size, color, and gap — e.g. UserCard's social links use
  `gap-1.5 font-sans text-sm text-apt-text-muted hover:text-apt-text`.
- Token-driven color (`apt-blue`, `apt-gold`); no raw hex, no `!important`.

## States

| State | Appearance change |
|---|---|
| Default | Mono, `apt-blue`, no underline, trailing `↗` |
| `glyph={false}` | No trailing arrow (leading icon expected in children) |
| Focus (keyboard) | `apt-gold/40` focus ring via `focus-visible:ring-2` |
| Restyled (`className`) | Font/color/gap overridden; new-tab + `rel` unchanged |
| Hover | No built-in hover; consumers MAY add one (e.g. `hover:text-apt-text`) |

## Accessibility

- **Accessible name = children.** The link's name comes from its text content;
  the `↗` glyph is `aria-hidden`, so a link reading "PostHog ↗" is named
  "PostHog", not "PostHog up-right arrow".
- **Keyboard focus is visible.** `focus-visible:ring-2 ring-apt-gold/40` gives a
  clear focus indicator without a persistent outline on mouse click.
- **New-tab safety.** `rel="noopener noreferrer"` is always present, closing the
  reverse-tabnabbing hole that a bare `target="_blank"` would open.
- **Leading-icon mode.** In `glyph={false}` usage the visible icon is itself
  `aria-hidden`, and the visible label text (e.g. "GitHub") remains the
  accessible name — so dropping the trailing arrow never removes the link's name.
- The component does not auto-announce "opens in a new tab"; consumers for whom
  that matters SHOULD add it (e.g. via visually-hidden text) at the call site.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | opens-new-tab, applies-safe-rel | `<ExternalLink href="https://example.com">PostHog</ExternalLink>` | anchor has `target="_blank"` and `rel="noopener noreferrer"` |
| T2 | renders-trailing-glyph-by-default | same as T1 | link text content contains `↗` |
| T3 | glyph-is-decorative | same as T1 | accessible name equals exactly `PostHog`, not including the arrow |
| T4 | suppresses-glyph-when-false | `<ExternalLink href="…" glyph={false}>GitHub</ExternalLink>` | link named `GitHub` has no `↗` text content |
| T5 | forwards-anchor-props | `href="https://us.posthog.com"` | anchor `href` equals `https://us.posthog.com` |
| T6 | merges-classname, default-deep-link-skin | `className="font-sans text-apt-text-muted"` | `cn()` is `twMerge(clsx(...))`, so the conflicting font-family utility is resolved: className contains `font-sans` and not `font-mono`; anchor still has `target="_blank"` and `rel="noopener noreferrer"` |
| T7 | safe-attrs-not-overridable | `<ExternalLink href="https://example.com" target="_self" rel="">PostHog</ExternalLink>` | anchor `target` equals `_blank` and `rel` equals `noopener noreferrer` (the passed-in `target`/`rel` do not win) |
| T8 | focus-ring | same as T1 | className contains `focus-visible:ring-2` and `focus-visible:ring-apt-gold/40` |
| T9 | default-deep-link-skin | same as T1 | className contains `whitespace-nowrap` and `no-underline` |

## Edge Cases

- **Missing `href`.** `href` is a forwarded native prop, not required by the
  component; omitting it yields an anchor with no destination (the caller's
  responsibility), while `target`/`rel` are still applied.
- **Icon-plus-text without glyph.** With `glyph={false}` and both a leading icon
  and text as children, only the text contributes the accessible name (the icon
  is `aria-hidden` at the call site).
- **Long labels.** `whitespace-nowrap` keeps the "{label} ↗" pair on one line; a
  consumer that needs wrapping overrides it through `className`.
- **Internal links.** This is for *external* jump-outs; in-app navigation SHOULD
  use the app router link, not a new-tab anchor.
- **Overriding `target`/`rel`.** The safe defaults are set *after* `...props`
  spreads, so the safe contract is guaranteed — a caller-supplied `target`/`rel`
  in props cannot accidentally drop the safe new-tab behavior.

## Configuration

| Option | Type | Default | Description |
|---|---|---|---|
| `glyph` | `boolean` | `true` | Render the trailing `↗`. Set `false` when a leading icon carries the external affordance. |
| `children` | `ReactNode` | — | The visible label (and any leading icon); becomes the accessible name. |
| `className` | `string` | — | Extra classes merged after the base skin via `cn()` (restyle font/color/gap). |
| `...props` | `React.ComponentProps<"a">` | — | Native anchor props (`href`, `onClick`, `title`, `data-*`, …) forwarded onto the `<a>`. |

## Deep Linking

Not applicable: ExternalLink is a link component that navigates to external URLs, not to app states. Deep linking guidance applies to in-app navigation patterns.

## Localization

The `↗` glyph is directional and MUST be mirrored (or swapped for a start-pointing
equivalent, e.g. `↖`) in right-to-left layouts — an unmirrored trailing arrow
points the wrong way for an RTL reader. Native ports SHOULD key this off the
platform's layout-direction API (Apple's `layoutDirection`/
`UserInterfaceLayoutDirection`, Compose's `LocalLayoutDirection`, WinUI 3's
`FlowDirection`); web SHOULD gate a logical transform on `dir="rtl"`. The
component itself has no other user-facing strings — the label is the
consumer's `children` — but a caller that adds a visually-hidden "opens in a
new tab" hint (see Accessibility) owns that string and is responsible for
localizing it; the component does not provide or externalize it.

## Accessibility Options

The default skin's `text-[11px]` is a fixed pixel size and does not respond
to the user's preferred text size. Native ports (SwiftUI, Compose, AppKit /
UIKit, WinUI 3) MUST use a scalable text style (e.g. Dynamic Type on Apple,
`sp`-based type scale in Compose) instead of a fixed point size, and the web
implementation SHOULD express the size as `rem` rather than a raw pixel
value, so the label and glyph scale with the user's text-size setting.
Reduce Motion and Differentiate Without Color do not apply: the component
has no animation, and its affordance is carried by the `↗` glyph plus the
`apt-blue` token together, not by color alone.

## Feature Flags

Not applicable: ExternalLink is a core presentational primitive with no optional behavior to gate.

## Analytics

Not applicable: The component is stateless and emits no events. Consumers who need click tracking MAY add it via a forwarded `onClick` handler or an analytics wrapper at the call site.

## Privacy

Not applicable: The component does not collect, process, or transmit any personal data.

## Logging

Not applicable: ExternalLink is a presentational anchor with no lifecycle events, errors, or state changes to log. Click tracking and navigation logging, if needed, belong to the consumer via a forwarded `onClick` or an analytics wrapper at the call site.

## Platform Notes

- **React/Web**: File `packages/web/packages/ui/src/components/external-link.tsx`. No `"use client"` directive — it is a stateless anchor that renders in server components. Uses `cn()` utility for class merging and Tailwind tokens (`text-[11px]`, `text-apt-blue`, etc.) for styling. Focus state is `:focus-visible` to avoid persistent outline on mouse click. Consumed by `blocks/user-card.tsx` (social links with `glyph={false}` + lucide icon) and `blocks/stat-card.tsx` (header actions deep link with default skin).
- **SwiftUI**: Use `Link(destination: URL)` wrapping a `Text` and custom affordance (trailing ↗ glyph). Wrap in an `HStack` to layout the text and glyph side-by-side with consistent spacing. `Link` opens the URL through the `openURL` environment action (`@Environment(\.openURL) var openURL`), which SwiftUI resolves to the platform's default-browser handler rather than the view calling `UIApplication`/`NSWorkspace` directly. Apply the same small-mono info-blue styling (font size 11pt, monospaced font design, `.foregroundStyle` matching the info-blue token). Mark the glyph `.accessibilityHidden(true)` so the accessible name remains just the label text.
- **Compose**: Use `Text` with `withLink(LinkAnnotation.Url(url))` (or `LocalUriHandler` to open the URL explicitly) so the element carries a proper link role and opens the URL in the default browser, rather than a plain `clickable` modifier with a manual `Intent`. Layout text and trailing ↗ glyph in a `Row` with consistent spacing and apply the small mono info-blue styling (fontSize = 11.sp, fontFamily = FontFamily.Monospace, color matching the info-blue token). Hide the glyph from assistive tech with `Modifier.clearAndSetSemantics {}` (the deprecated `invisibleToUser()` SHOULD NOT be used).
- **AppKit / UIKit**: On macOS, use `NSButton` with a hyperlink style or `NSTextView` with a clickable `NSAttributedString.Link` attribute; set the link's URL and add a custom trailing ↗ glyph by appending a decorative `NSAttributedString` segment (via `NSAttributedString.Key.foregroundColor` and font traits). On iOS, use `UIButton` with an attributed title containing the label and a trailing glyph, wired to a tap handler that calls `UIApplication.shared.open(url)` in the default browser. `isAccessibilityElement` cannot be set on just one run of an attributed title, so set the button's own `accessibilityLabel` to the label text alone (excluding the glyph) instead. Apply the small-mono info-blue styling (font size 11pt, system mono font, color matching the info-blue token) and ensure keyboard focus shows a visible ring.
- **WinUI 3**: Use `HyperlinkButton` with `NavigateUri` set to the external URL (the button will open it in the default browser by default), and set `Content` to a `StackPanel` with horizontal orientation containing the label `TextBlock` and a trailing glyph `TextBlock` (↗ character) or `FontIcon` using glyph `&#xE8A7;` (the Segoe Fluent "OpenInNewWindow" glyph). Alternatively, use a `Hyperlink` inline inside a `TextBlock` with a `Click` event handler that calls `Windows.System.Launcher.LaunchUriAsync(new Uri(url))` to open the URL explicitly in the default browser. Apply the small-mono info-blue styling (font size 11pt, monospace font family, foreground color matching the info-blue token). Ensure keyboard focus is visible, and mark the glyph decorative for automation by setting `AutomationProperties.AccessibilityView="Raw"` on the glyph element (`AutomationProperties.IsOffscreenBehavior` does not remove it from the automation tree) — or skip the `FontIcon` and use only the `↗` `TextBlock`, which is simpler to hide correctly.

## Design Decisions

- **Decision**: Bake `target="_blank"` and `rel="noopener noreferrer"` into the
  component rather than leaving them to the caller.
  **Rationale**: Every external jump-out is reverse-tabnabbing-safe by
  construction — the common mistake of a caller forgetting the safe attributes
  is centralised away.
  **Approved**: pending
- **Decision**: Ship one default skin (small mono info-blue deep-link grammar)
  and let consumers restyle via a `cn()`-merged `className` instead of adding
  variant props.
  **Rationale**: The deep-link grammar is the dominant use, so it is the
  default; anything else (UserCard's sans muted social links) is an override
  rather than a variant — keeping the component a thin anchor.
  **Approved**: pending
- **Decision**: Expose the trailing `↗` as a boolean (`glyph`), not a slot, on
  by default and dropped with `glyph={false}` when a leading icon already
  signals "external".
  **Rationale**: The trailing arrow is the one affordance most links want;
  a boolean avoids two arrows when a leading icon already carries the meaning.
  **Approved**: pending
- **Decision**: Mark the `↗` glyph `aria-hidden="true"`.
  **Rationale**: The arrow is a visual affordance, not content, so the
  accessible name stays the label.
  **Approved**: pending
- **Decision**: Set `target` and `rel` *after* spreading `...props`, not
  before.
  **Rationale**: This guarantees the safe defaults win over any
  caller-supplied `target`/`rel` (see **safe-attrs-not-overridable**), so the
  reverse-tabnabbing hole cannot be reopened by props.
  **Approved**: pending

## Compliance

| Check | Status | Category |
|---|---|---|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | failed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | failed | Internationalization |
| [safe-defaults](agenticdevelopercookbook://compliance/user-safety#safe-defaults) | passed | User Safety |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

The source shows a native `<a>` with an `aria-hidden` decorative glyph and an
accessible name from `children` (screen-reader-support, semantic-markup); a
plain anchor is natively keyboard-operable (keyboard-navigable); the always-on
`target="_blank"`/`rel="noopener noreferrer"` that a caller cannot override is
the safest-configuration case `safe-defaults` describes; the fixed
`text-[11px]` does not scale with the user's text-size setting
(dynamic-type-support); the `apt-blue`/`apt-gold` token values aren't visible
from this source so the contrast ratio can't be confirmed (contrast-ratio);
and nothing in the source mirrors the trailing glyph for RTL layouts
(rtl-layout-support). `separation-of-concerns` passes: `external-link.tsx`
does nothing but forward props/classes onto a native `<a>` and enforce the
safe-new-tab attributes, with no logic of its own to entangle with anything
else. `unit-test-coverage` fails — no test file in the `ui` package exercises
`ExternalLink`.

## Change History

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.3.1 | 2026-09-25 | Mike Fullerton | Restored on-main 1.0.0 Change History row (authorized); added missing separation-of-concerns/unit-test-coverage Compliance rows. |
| 1.3.0 | 2026-09-22 | Mike Fullerton | Lint pass: fix frontmatter summary quoting/length; add safe-attrs-not-overridable requirement and test vector, fix T3/T6 assertions, add focus-ring/default-deep-link-skin coverage vectors; give Localization an RTL glyph-mirroring rule and hint-text ownership, and Accessibility Options a real Dynamic Type/rem note; reformat Design Decisions to the three-line form; rebuild Compliance as catalog-linked checks; correct SwiftUI (openURL, accessibilityHidden, foregroundStyle), Compose (link role, clearAndSetSemantics), AppKit/UIKit (accessibilityLabel), and WinUI 3 (concrete glyph, AccessibilityView="Raw") Platform Notes; reword the 1.0.0 row to match the ingredient type. |
| 1.2.0 | 2026-09-22 | Mike Fullerton | Revise Platform Notes: replace "Not applicable" for non-web platforms with concrete translation guidance (SwiftUI: Link with Text and HStack, Compose: Text with clickable and Intent.ACTION_VIEW, AppKit/UIKit: NSButton or NSTextView with decorative glyph, WinUI 3: HyperlinkButton or inline Hyperlink with LaunchUriAsync). |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Add non-applicable sections (Deep Linking, Localization, Accessibility Options, Feature Flags, Analytics, Privacy, Logging) with clear rationales; correct domain to agenticdevelopercookbook://; clarify props-order safety in Edge Cases and Design Decisions; update Platform Notes to five bullets. Set status to review. |
| 1.0.0 | 2026-07-03 | Mike Fullerton | Initial recipe; documents the safe-new-tab "{label} ↗" deep link and its glyph={false} mode. |
