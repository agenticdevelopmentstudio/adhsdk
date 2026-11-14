
- **catalogue-membership**: `webPorted` MUST contain exactly these 21 themes by `name`, in this order: Charcoal, Signal, Terminal, Terminal Split, Green Matrix, Green Matrix (Glass), Old School Terminal, CRT Monitor, Handheld Communicator, Synthwave '84, Cobalt2, Vesper, Professional, Techy, Whimsical, Fishlamp, Dev Team, Mike Fullerton, My Projects, Projects Overview, Agentic Development Studio.
- **catalogue-names-verbatim**: Each `name` MUST be the web manifest's own label, including the parentheses in "Green Matrix (Glass)" and the apostrophe in "Synthwave '84".
- **catalogue-no-editor-duplicates**: `webPorted` MUST NOT contain a theme whose `name` equals the name of any hand-authored theme in `BuiltInThemes.all`.
- **catalogue-visibility**: Every theme in `webPorted` MUST appear in `BuiltInThemes.all`. The list the app ships is `webPortedNative`, which is `webPorted` mapped through `nativeAdjusted` in `BuiltInThemes+Native.swift`.
- **theme-id-stable**: Each theme's `id` MUST be the fixed string `B1B6F0E2-0000-4000-8000-000000000NNN`, where `NNN` runs from `101` (Charcoal) to `121` (Agentic Development Studio) in list order. Ids are never derived at runtime.
- **theme-id-unique**: The ids of `BuiltInThemes.all` MUST be pairwise distinct.
- **theme-appearance**: Every theme MUST declare `appearance: .dark`.
- **theme-built-in**: Every theme MUST set `isBuiltIn` to `true`.
- **theme-attribution**: Every theme MUST set `attribution` to "Agentic Developer Hub SDK".
- **theme-base-colours**: Each theme MUST give `foreground`, `background`, `cursor` and `selection` as `RGBAColor` values built from 8-digit `#RRGGBBAA` strings. The values per theme are in the catalogue table below.
- **theme-selection-from-cursor**: Each theme's `selection` MUST be its `cursor` colour at alpha `4d` (about 30%).
- **ansi-count**: Each theme's `ansi` MUST hold exactly 16 colours, so `hasValidPalette` is true (`ColorTheme.ansiColorCount` is 16).
- **ansi-derived-fill**: `ansi` is a best-effort fill derived from the theme's semantic colours for the terminal feature, not a palette the web theme defines. In every theme index 0 MUST equal `background` and index 15 MUST equal `foreground`.
- **ansi-bright-repeats-normal**: In every theme, indices 1 to 6 MUST equal indices 9 to 14 respectively (the bright half repeats the normal half for those six slots).
- **ansi-accent-slots**: In every theme except CRT Monitor and Handheld Communicator, indices 4 and 5 MUST equal the theme's `cursor` (its accent). In CRT Monitor and Handheld Communicator, indices 3 and 4 MUST equal the accent `#00ff41ff`.
- **ansi-no-warning-no-link**: CRT Monitor and Handheld Communicator have no `--color-warning` or `--color-link` in their CSS. Their `ansi[3]` and `ansi[11]` MUST fall back to the accent, and their `ansi[5]` and `ansi[13]` MUST be `#005fffff`, the accent shifted toward magenta in place of `--color-link` as the source comment describes.
- **ansi-transparent-background**: CRT Monitor and Handheld Communicator MUST carry a fully transparent `background` (`#00000000`), and therefore a fully transparent `ansi[0]`; their `ansi[8]` MUST be `#050805ff`.
- **role-overrides-keyed**: `roleOverrides` MUST be keyed by `ThemeRole.rawValue` and hold `RGBAColor` values. Any role a theme does not list is left to `SemanticPalette` to derive.
- **role-overrides-universal**: Every theme MUST override the nine chat roles every web theme defines: `chatSurface`, `chatInputBackground`, `chatInputBorder`, `chatInputFocus`, `personaName`, `personaText`, `userName`, `userText` and `timestampText`.
- **role-overrides-bubble-fills**: Every theme MUST override `personaBubble` and `userBubble`, either with the web fill or, where web declares none, with `#00000000`.
- **role-overrides-optional**: The roles `personaBubbleBorder`, `userBubbleBorder`, `sendButton`, `sendButtonHover`, `sendButtonText` and `thinkingDoneText` MUST be present only in the themes whose CSS declares them and MUST be absent elsewhere, where they derive. The per-theme sets are in the requirements below and the role table in the catalogue section.
- **flat-terminal-themes**: Terminal, Terminal Split, Green Matrix, Green Matrix (Glass), Old School Terminal, CRT Monitor and Handheld Communicator MUST override both `personaBubble` and `userBubble` to `#00000000`. Their CSS declares no `--pc-persona-bg` or `--pc-user-bg`, and `.pc-bubble` styles only its width, so web draws no box. The transparent override is explicit rather than left to derive; the chat bubble view reads it as a flat transcript line with no padding and no corner radius.
- **flat-terminal-no-send-button**: The seven flat themes MUST NOT override `sendButton`, `sendButtonHover` or `sendButtonText`.
- **thinking-done-declared**: CRT Monitor and Handheld Communicator MUST override `thinkingDoneText` to `#00ff41ff`.
- **thinking-done-not-elsewhere**: No other theme MUST override `thinkingDoneText`; in particular Old School Terminal MUST NOT, so its settled status line takes the library default grey even though it shares a phosphor palette with the two CRT themes.
- **whimsical-gradient-first-stop**: Whimsical's web CSS defines `--pc-persona-bg`, `--pc-user-bg` and `--pc-send-bg` as `linear-gradient(...)`. `ColorTheme` holds solid colours only, so Whimsical MUST use each gradient's first colour stop: `personaBubble` `#c8506aff`, `userBubble` `#5a4a98ff`, `sendButton` `#c8506aff`.
- **transparent-send-button**: Dev Team, Mike Fullerton and Projects Overview MUST override `sendButton` to `#00000000` and `sendButtonText` to the accent `#c4a35aff`, a text-only send button.
- **send-button-hover-absent**: Techy, Whimsical, Dev Team, Mike Fullerton and Projects Overview MUST NOT override `sendButtonHover`.
- **send-button-hover-present**: Charcoal, Signal, Synthwave '84, Cobalt2, Vesper, Professional, Fishlamp, My Projects and Agentic Development Studio MUST override `sendButtonHover`, alongside `sendButton` and `sendButtonText`.
- **bubble-borders-declared**: `personaBubbleBorder` and `userBubbleBorder` MUST be overridden in Charcoal, Techy, Fishlamp, Dev Team, Mike Fullerton, My Projects, Projects Overview and Agentic Development Studio, and MUST NOT be overridden in the other thirteen themes.
- **typography-roles**: Every theme's `typography.styles` MUST hold a `FontStyle` for each of the six `TextRole` cases, keyed by `TextRole.rawValue`, with these base sizes and weights: title 22 semibold, heading 15 semibold, body 13 regular, caption 11 regular, code 12 regular, button 13 medium.
- **typography-family**: Title, heading, body, caption and button MUST share the theme's first named web font family; `code` MUST use the family of the theme's `--font-mono` stack. Where the two coincide (Charcoal, Terminal, Terminal Split, Green Matrix, Green Matrix (Glass), Old School Terminal, CRT Monitor, Handheld Communicator, Fishlamp, Mike Fullerton) all six roles use one family. The families per theme are in the catalogue table.
- **typography-monospaced-flag**: Each `FontStyle.monospaced` MUST come from the font stack's own generic fallback: true for every role of a monospaced stack, false for the non-code roles of a proportional stack, and true for `code` in every theme. Sans themes are not forced monospaced.
- **typography-size-scale**: `ThemeTypography.sizeScale` MUST carry each theme's web body size as a ratio against a catalogue baseline of 15px, not as transcribed point sizes: Terminal, Terminal Split, Green Matrix, Green Matrix (Glass), Techy, Dev Team and My Projects 0.9333 (14px); Old School Terminal and Whimsical 1.0667 (16px); CRT Monitor and Handheld Communicator 1.2667 (19px); Mike Fullerton 0.9 (13.5px); Projects Overview 0.8667 (13px).
- **typography-size-scale-default**: A theme whose CSS states no body size MUST leave `sizeScale` at its default of 1.0: Charcoal, Signal, Synthwave '84, Cobalt2, Vesper, Professional, Fishlamp and Agentic Development Studio.
- **typography-scale-reaches-size**: The scale MUST affect the resolved size: `typography.size(.body)` is the body style's `size` times `sizeScale`, so Old School Terminal resolves larger than its base 13.
- **generated-source**: `BuiltInThemes+Web.swift` MUST be produced by the generator and MUST NOT be hand-edited. Native-only changes to a generated theme (selection fill, cards, the project plane) MUST live in `BuiltInThemes+Native.swift`, applied over the generated values, so a re-run cannot drop them. Today that file adjusts only Fishlamp.
- **hex-literals-valid**: The generator MUST emit only valid 8-digit hex literals, because every colour is built with `RGBAColor(hexString:)` and force-unwrapped; a malformed literal traps when the static theme is first read and is not a recoverable condition.
- **no-side-effects**: Reading `webPorted` MUST NOT touch files, the network, processes or notifications. Every theme is a `static let` on `BuiltInThemes`, an `enum` with no stored state, and `ColorTheme` is a value type.

### Catalogue

Base colours, type scale and font families per theme. Every theme also has the six-role type sizes above, `appearance: .dark`, and `selection` equal to `cursor` at alpha `4d`.

| Swift name | Theme name | id suffix | foreground | background | cursor | sizeScale | body family | code family |
|---|---|---|---|---|---|---|---|---|
| `charcoal` | Charcoal | 101 | `#e8e6e3ff` | `#0c0c0fff` | `#c4a35aff` | 1.0 (unset) | Iosevka | Iosevka |
| `signal` | Signal | 102 | `#ece8dfff` | `#0a0c11ff` | `#f6b73cff` | 1.0 (unset) | Space Grotesk | JetBrains Mono |
| `terminal` | Terminal | 103 | `#b0b0b0ff` | `#0a0a0aff` | `#33ff33ff` | 0.9333 | IBM Plex Mono | IBM Plex Mono |
| `terminalSplit` | Terminal Split | 104 | `#d0d0d0ff` | `#0a0a0aff` | `#ffcc00ff` | 0.9333 | IBM Plex Mono | IBM Plex Mono |
| `greenMatrix` | Green Matrix | 105 | `#00ff41ff` | `#000000ff` | `#00ff41ff` | 0.9333 | JetBrains Mono | JetBrains Mono |
| `greenMatrixGlass` | Green Matrix (Glass) | 106 | `#00ff41ff` | `#000000ff` | `#00ff41ff` | 0.9333 | JetBrains Mono | JetBrains Mono |
| `oldSchoolTerminal` | Old School Terminal | 107 | `#00ff41ff` | `#000000ff` | `#00ff41ff` | 1.0667 | VT323 | VT323 |
| `crtMonitor` | CRT Monitor | 108 | `#00ff41ff` | `#00000000` | `#00ff41ff` | 1.2667 | VT323 | VT323 |
| `handheldCommunicator` | Handheld Communicator | 109 | `#00ff41ff` | `#00000000` | `#00ff41ff` | 1.2667 | VT323 | VT323 |
| `synthwave84` | Synthwave '84 | 110 | `#f2f0f5ff` | `#262335ff` | `#ff7edbff` | 1.0 (unset) | Exo 2 | JetBrains Mono |
| `cobalt2` | Cobalt2 | 111 | `#ffffffff` | `#193549ff` | `#ffc600ff` | 1.0 (unset) | Rubik | Victor Mono |
| `vesper` | Vesper | 112 | `#ffffffff` | `#101010ff` | `#ffc799ff` | 1.0 (unset) | Geist | Geist Mono |
| `professional` | Professional | 113 | `#e8eaedff` | `#0e1620ff` | `#8aa8d4ff` | 1.0 (unset) | Inter | JetBrains Mono |
| `techy` | Techy | 114 | `#c9d1d9ff` | `#0d1117ff` | `#00ff88ff` | 0.9333 | Inter | JetBrains Mono |
| `whimsical` | Whimsical | 115 | `#f5e8f5ff` | `#1a1024ff` | `#f08aa8ff` | 1.0667 | Nunito | JetBrains Mono |
| `fishlamp` | Fishlamp | 116 | `#f0e4d0ff` | `#0b0a09ff` | `#e8a33dff` | 1.0 (unset) | Iosevka | Iosevka |
| `devTeam` | Dev Team | 117 | `#e8e6e3ff` | `#14141aff` | `#c4a35aff` | 0.9333 | Manrope | DM Mono |
| `mikeFullerton` | Mike Fullerton | 118 | `#e8e6e3ff` | `#0e0e14ff` | `#c4a35aff` | 0.9 | DM Mono | DM Mono |
| `myProjects` | My Projects | 119 | `#e8e6e3ff` | `#14141aff` | `#c4a35aff` | 0.9333 | Manrope | DM Mono |
| `projectsOverview` | Projects Overview | 120 | `#e8e6e3ff` | `#14141aff` | `#c4a35aff` | 0.8667 | Manrope | DM Mono |
| `agenticDevelopmentStudio` | Agentic Development Studio | 121 | `#e8e6e3ff` | `#0c0c0fff` | `#c4a35aff` | 1.0 (unset) | Manrope | DM Mono |

Chat role overrides per theme, beyond the nine universal roles and the two bubble fills:

| Theme | Extra overridden roles |
|---|---|
| Charcoal, Fishlamp, My Projects, Agentic Development Studio | `personaBubbleBorder`, `userBubbleBorder`, `sendButton`, `sendButtonHover`, `sendButtonText` |
| Signal, Synthwave '84, Cobalt2, Vesper, Professional | `sendButton`, `sendButtonHover`, `sendButtonText` |
| Terminal, Terminal Split, Green Matrix, Green Matrix (Glass), Old School Terminal | none |
| CRT Monitor, Handheld Communicator | `thinkingDoneText` |
| Techy | `personaBubbleBorder`, `userBubbleBorder`, `sendButton`, `sendButtonText` |
| Whimsical | `sendButton`, `sendButtonText` |
| Dev Team, Mike Fullerton, Projects Overview | `personaBubbleBorder`, `userBubbleBorder`, `sendButton` (transparent), `sendButtonText` |

Other values worth stating. Green Matrix (Glass), Old School Terminal, CRT Monitor and Handheld Communicator set `chatInputBackground` to `#00000000`. Green Matrix (Glass) and Old School Terminal set `chatSurface` to `#050805cc`; CRT Monitor and Handheld Communicator set it to `#040c069e`. Dev Team, My Projects and Projects Overview set `chatInputBackground` to `#0c0c0fff` while their `background` is `#14141aff`. Mike Fullerton's `chatInputBackground` is `#0c0c0f99`, its `chatSurface` is `#0e0e148c` and its `ansi[8]` is `#14141cb2`.

