
Derived from `PortedThemeTests` (Swift Testing suite "Ported web themes") and from the literals in `BuiltInThemes+Web.swift`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| theme-web-001 | catalogue-membership, catalogue-names-verbatim | Set of `names` of `webPorted` (test `catalogMatchesWeb`) | Equals the 21 names listed, including "Green Matrix (Glass)" and "Synthwave '84" |
| theme-web-002 | catalogue-no-editor-duplicates, theme-id-unique | Names of `BuiltInThemes.all` minus `webPorted`, and ids of `all` (test `noDuplicateNames`) | No ported name is among the remainder; the number of distinct ids equals `all.count` |
| theme-web-003 | ansi-count, theme-built-in | For each ported theme, `theme.hasValidPalette` and `theme.isBuiltIn` (test `palettesAreValid`) | Both true for all 21 |
| theme-web-004 | role-overrides-universal | For each ported theme, `roleOverrides[role.rawValue]` for the nine universal chat roles (test `chatOverridesArePresent`) | Non-nil for every theme and role |
| theme-web-005 | flat-terminal-themes, role-overrides-bubble-fills | `SemanticPalette(theme:)` alpha of `personaBubble` and `userBubble` for each ported theme (test `themesWithoutWebBubbleFillsAreFlat`) | Alpha is 0 for both in exactly the seven flat themes and no others |
| theme-web-006 | typography-roles | Each ported theme, each `TextRole.allCases` (test `typographyIsPorted`) | `typography.styles[role.rawValue]` is non-nil |
| theme-web-007 | typography-family, typography-monospaced-flag | Old School Terminal `style(.body)`; Professional `style(.body)` and `style(.code)` (test `typographyIsPorted`) | Old School Terminal family "VT323", monospaced; Professional body "Inter" not monospaced, code "JetBrains Mono" monospaced |
| theme-web-008 | typography-size-scale, typography-size-scale-default | `sizeScale` of Old School Terminal, CRT Monitor, Handheld Communicator, Terminal, Charcoal (test `bodyFontSizeIsPortedAsAScale`) | 16/15, 19/15, 19/15, 14/15 each within 0.001; Charcoal exactly 1.0 |
| theme-web-009 | typography-scale-reaches-size | Old School Terminal `typography.size(.body)` versus `style(.body).size` (test `bodyFontSizeIsPortedAsAScale`) | The resolved size is greater than the base size |
| theme-web-010 | thinking-done-declared | `palette.declares(.thinkingDoneText)` and its colour for CRT Monitor and Handheld Communicator (test `thinkingDoneColourIsDeclaredByTerminalThemes`) | Declared, colour `#00ff41ff`, and different from `timestampText` |
| theme-web-011 | thinking-done-not-elsewhere | Old School Terminal `palette.declares(.thinkingDoneText)` and its derived colour (test `oldSchoolTerminalSettlesToGrey`) | Not declared; red, green and blue channels differ by less than 0.02 (grey) |
| theme-web-012 | thinking-done-not-elsewhere | Whimsical `palette.declares(.thinkingDoneText)` and its alpha (test `thinkingDoneColourIsDerivedElsewhere`) | Not declared; derived alpha greater than 0 |
| theme-web-013 | catalogue-visibility | For each ported theme, whether `BuiltInThemes.all` holds one with the same id (test `foldedIntoAll`) | True for all 21 |
| theme-web-014 | theme-id-stable | Charcoal `id` and Agentic Development Studio `id` | `B1B6F0E2-0000-4000-8000-000000000101` and `B1B6F0E2-0000-4000-8000-000000000121` |
| theme-web-015 | ansi-derived-fill, ansi-bright-repeats-normal | Any theme, compare `ansi[0]`, `ansi[15]`, `ansi[1]` to `background`, `foreground`, `ansi[9]` | `ansi[0]` equals `background`, `ansi[15]` equals `foreground`, `ansi[1]` equals `ansi[9]` |
| theme-web-016 | whimsical-gradient-first-stop | Whimsical `roleOverrides` for `personaBubble`, `userBubble`, `sendButton` | `#c8506aff`, `#5a4a98ff`, `#c8506aff` |
| theme-web-017 | theme-selection-from-cursor, theme-base-colours | Synthwave '84 `cursor` and `selection` | `#ff7edbff` and `#ff7edb4d` |
| theme-web-018 | transparent-send-button, send-button-hover-absent | Mike Fullerton `sendButton` and `sendButtonText`; presence of `sendButtonHover` | `#00000000`, `#c4a35aff`; no `sendButtonHover` override |
| theme-web-019 | ansi-accent-slots, ansi-no-warning-no-link, ansi-transparent-background | CRT Monitor `ansi[0]`, `ansi[3]`, `ansi[5]`, `ansi[13]` | `#00000000`, `#00ff41ff`, `#005fffff`, `#005fffff` |
| theme-web-020 | flat-terminal-no-send-button, role-overrides-optional | Presence of `sendButton`, `sendButtonHover`, `sendButtonText` in Terminal `roleOverrides` | All three absent |
| theme-web-021 | bubble-borders-declared | Presence of `personaBubbleBorder` in Charcoal and in Signal `roleOverrides` | Present (`#c4a35a40`) in Charcoal; absent in Signal |
| theme-web-022 | typography-roles, typography-monospaced-flag | Techy `style(.title)` and `style(.code)` | Title Inter 22 semibold not monospaced; code JetBrains Mono 12 regular monospaced |
| theme-web-023 | send-button-hover-present | Presence of `sendButtonHover` in Signal `roleOverrides` | Present, `#ffc85aff` |
| theme-web-024 | theme-appearance, theme-attribution | Any ported theme's `appearance` and `attribution` | `.dark` and "Agentic Developer Hub SDK" |
| theme-web-025 | hex-literals-valid | `RGBAColor(hexString: "#12345")` (five digits) | `nil`, which a force-unwrap in the generated file would turn into a trap |

