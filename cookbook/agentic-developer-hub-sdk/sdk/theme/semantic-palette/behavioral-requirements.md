
Role set

- **role-enum**: `ThemeRole` MUST be a `String`-backed, `CaseIterable`, `Sendable` enumeration whose raw value is the case name, because the raw value is the key into `ColorTheme.roleOverrides`.
- **role-groups**: `ThemeRole` MUST define these roles, in this order. Backgrounds: `windowBackground`, `surface`, `elevatedSurface`, `controlBackground`, `card`. Text: `primaryText`, `secondaryText`, `tertiaryText`, `placeholderText`, `onAccentText`. Status: `accent`, `success`, `warning`, `danger`, `info`. Lines: `border`, `outline`, `divider`. Selection and caret: `selection`, `selectionText`, `selectionEdge`, `cursor`. Chat: `personaBubble`, `personaBubbleBorder`, `personaText`, `personaName`, `userBubble`, `userBubbleBorder`, `userText`, `userName`, `chatSurface`, `chatInputBackground`, `chatInputBorder`, `chatInputFocus`, `sendButton`, `sendButtonText`, `sendButtonHover`, `timestampText`, `thinkingDoneText`, `thinkingIdleText`.

Construction and lookup

- **struct-shape**: `SemanticPalette` MUST be a public `Equatable`, `Sendable` struct holding the `ColorTheme` it was built from in `theme`.
- **resolve-once**: `init(theme:)` MUST resolve every case in `ThemeRole.allCases` exactly once and store the results, so later `color(_:)` calls are dictionary reads. The source comment gives the reason: resolving the dimmed text roles runs an iterative contrast loop that is too costly to repeat in draw paths.
- **resolution-order**: Resolving a role MUST return the `ColorTheme.roleOverrides` entry keyed by the role's raw value when one exists, and the derived color otherwise.
- **color-lookup**: `color(_:)` MUST return the stored resolved color for the role. If the stored map has no entry it MUST resolve the role on demand with the same override-or-derive rule. With the shipped initializers that fallback is never reached.
- **color-accessors**: Each of the 40 roles MUST also be readable as a same-named computed property (`accent`, `surface`, `userBubble`, and so on) that returns `color(<role>)`.
- **declares**: `declares(_:)` MUST return true exactly when `theme.roleOverrides` has an entry for the role's raw value, and false for every role that is merely derived. It reads only the overrides, never the resolved colors.
- **declares-purpose**: `declares(_:)` exists so a caller can tell a theme that wants an element (a bubble outline) from a theme that merely derives to some opaque color; the source comment says every role derives to an opaque color, so visibility cannot answer that question.
- **derived-ignores-overrides**: `derived(_:)` MUST return the default palette-derived color for a role and MUST ignore `roleOverrides`.
- **chains-use-derived-parents**: A derived role that is defined in terms of another role MUST be computed from that role's derived value, not its overridden value. This applies to `card` (from `elevatedSurface`), `onAccentText`, `personaName`, `userBubble`, `userBubbleBorder`, `chatInputFocus`, `sendButton`, `sendButtonText` and `sendButtonHover` (all from `accent`). A theme that overrides `accent` therefore does not change those derived roles unless it overrides them too.

Derivation table

Let `bg` be `theme.background` and `fg` be `theme.foreground`. `blend(f, of: x)` is `bg.blended(withFraction: f, of: x)`. `dim(by, min)` is `fg.dimmed(towards: bg, by: by, minContrast: min)`. `ansi(n)` is `theme.ansiColor(at: n)`, falling back to `fg` when the slot is absent.

- **derive-backgrounds**: With no override, `windowBackground` MUST be `bg`; `surface` MUST be `blend(0.06, of: fg)`; `elevatedSurface` MUST be `blend(0.12, of: fg)`; `controlBackground` MUST be `blend(0.09, of: fg)`; `card` MUST be the derived `elevatedSurface`.
- **derive-card-own-role**: `card` MUST remain its own role even though it derives to `elevatedSurface`, so a theme can set cards apart from pane title bars and footers, which stay on `elevatedSurface` (source comment on `card`).
- **derive-text**: With no override, `primaryText` MUST be `fg`; `secondaryText` MUST be `dim(by: 0.32, min: 3.0)`; `tertiaryText` MUST be `dim(by: 0.55, min: 2.0)`; `placeholderText` MUST be `dim(by: 0.68, min: 1.6)`.
- **derive-on-accent**: With no override, `onAccentText` MUST be the best-contrast opaque black or white for the derived `accent`.
- **derive-status**: With no override, `accent` MUST be `ansi(4)`, `success` `ansi(2)`, `warning` `ansi(3)`, `danger` `ansi(1)` and `info` `ansi(6)`; each MUST fall back to `fg` when the theme has no color at that slot.
- **derive-lines**: With no override, `border` MUST be `blend(0.18, of: fg)`, `outline` `blend(0.30, of: fg)` and `divider` `blend(0.10, of: fg)`.
- **derive-selection**: With no override, `selection` MUST be `theme.selection`; `selectionText` MUST be the best-contrast opaque black or white for `theme.selection`; `cursor` MUST be `theme.cursor`.
- **derive-selection-edge**: With no override, `selectionEdge` MUST be the clear color, so only a theme that declares it draws a selection line (source comment: "a theme opts in by declaring it").
- **derive-persona**: With no override, `personaBubble` MUST be `blend(0.08, of: fg)`; `personaBubbleBorder` `blend(0.16, of: fg)`; `personaText` `fg`; `personaName` the derived `accent`.
- **derive-user**: With no override, `userBubble` MUST be `bg` blended 0.18 toward the derived `accent`; `userBubbleBorder` `bg` blended 0.34 toward the derived `accent`; `userText` `fg`; `userName` `dim(by: 0.32, min: 3.0)`.
- **derive-composer**: With no override, `chatSurface` MUST be `bg`; `chatInputBackground` `blend(0.09, of: fg)`; `chatInputBorder` `blend(0.18, of: fg)`; `chatInputFocus` the derived `accent`.
- **derive-send-button**: With no override, `sendButton` MUST be the derived `accent`; `sendButtonText` the best-contrast opaque black or white for the derived `accent`; `sendButtonHover` the derived `accent` blended 0.18 toward `fg`.
- **derive-timestamp**: With no override, `timestampText` MUST be `dim(by: 0.55, min: 2.0)`.
- **derive-thinking-done**: With no override, `thinkingDoneText` MUST be `fg` fully desaturated, then dimmed toward `bg` by 0.55 with a minimum contrast of 2.0. The source comment explains that the grey is the meaning (a stopped turn is no longer the live thing) and that a fixed mid-grey such as web's `#8a8a8a` washes out on a light theme, so the value is derived rather than transcribed.
- **derive-thinking-idle**: With no override, `thinkingIdleText` MUST be `fg` fully desaturated, then dimmed toward `bg` by 0.25 with a minimum contrast of 3.0. It is deliberately lighter-handed than `thinkingDoneText` and deliberately not in the theme's hue, so an idle line never reads like a turn that has not ended.
- **thinking-roles-distinct**: `thinkingDoneText`, `thinkingIdleText` and `timestampText` MUST stay three separate roles; the source comments record that themes set them apart (for example phosphor-green themes set the done line green while leaving the timestamp dim).

Chart colors

- **chart-series**: `chartSeriesColors` MUST list `accent`, `success`, `info`, `warning`, `danger` (resolved colors) followed by ANSI slots 9, 10, 11, 12, 13 and 14 that exist, and keep only entries whose contrast ratio against the resolved `surface` is at least 1.5.
- **chart-series-nonempty**: `chartSeriesColors` MUST return the five semantic colors unfiltered when the contrast filter removes every entry, so the list is never empty.
- **chart-excludes-neutrals**: `chartSeriesColors` MUST NOT draw from ANSI slots 0, 7, 8 or 15, which the source comment says sit near the background on most themes.
- **identity-series**: `identitySeriesColors` MUST visit ANSI slots 5, 6, 13 and 14 in that order and keep a slot's color only if it exists, has a contrast ratio against the resolved `surface` of at least 1.5, is not equal to any of the resolved `accent`, `success`, `warning` or `danger`, and is not already in the list.
- **identity-excludes-state**: `identitySeriesColors` MUST drop, not merely demote, a candidate equal to a state color, so an identity color can never be read as a state. `info` is intentionally not in the excluded set.
- **identity-fallback**: `identitySeriesColors` MUST return `chartSeriesColors` when no candidate survives; the source comment says two members in the same color beat two members in no color.

Reader text scale

- **size-formula**: `size(_:)` MUST return `theme.typography.size(role)` multiplied by the palette's private reader scale.
- **reader-scale-default**: A palette built with `init(theme:)` MUST have a reader scale of 1.
- **scaled-clamp**: `scaled(by:)` MUST clamp `factor` with `ThemeTypography.clampedSizeScale` before using it; a non-finite factor becomes 1.0. `ThemeTypography.sizeScaleRange` is 0.5 through 4, the same bound `ThemeStore` applies to an imported theme's own scale.
- **scaled-identity**: `scaled(by:)` MUST return the receiver unchanged when the clamped factor equals 1.
- **scaled-compounds**: `scaled(by:)` MUST return a new palette with the same `theme` and the same resolved colors and with reader scale multiplied by the clamped factor. Scaling a scaled palette therefore compounds.
- **scaled-keeps-theme**: `scaled(by:)` MUST NOT write the factor into `theme`, so the reader's "Text Size" choice survives a theme change and the designer's `sizeScale` stays a property of the typeface.
- **scaled-no-recolor**: `scaled(by:)` MUST NOT recompute colors; it reuses the stored map.

Project window colors

- **project-pane-backdrop**: `projectPaneBackdrop` MUST return `theme.project?.paneBackdrop` when set, otherwise `elevatedSurface`.
- **project-pane-outline**: `projectPaneOutline` MUST return `theme.project?.paneOutline` when set, otherwise `border`.
- **project-active-pane-outline**: `projectActivePaneOutline` MUST return `accent` and MUST NOT consult any theme override of its own. The source comment says a theme that recolors `paneOutline` restyles the frame while the active pane still stands out.

Concurrency, persistence and side effects

- **concurrency**: `SemanticPalette` is `Sendable` and all stored properties are immutable `let` values, so a palette MAY be read from any thread and every method is a pure function of its inputs.
- **no-side-effects**: Construction and every accessor MUST NOT perform file, network, process or notification work and MUST NOT log.
- **equatable-scope**: Equality MUST compare `theme`, the resolved map and the reader scale. The resolved map is derived purely from `theme`, so it never breaks equality (source comment).
- **error-surface**: No operation throws or returns an optional. A missing ANSI slot falls back to `fg`, a missing override falls back to derivation, and an out-of-range scale is clamped.

