
The source has no test file of its own. The only test that names these types is `BubbleTruncationTests` in the macOS test target, which builds `ThemeTerminalOptions(fontName: "Menlo-Bold", fontSize: 21)` as a fixture and asserts nothing about the types. Vectors derive from the source's code and doc comments; the types are otherwise exercised only through `ColorTheme` coding.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| themeoptions-001 | terminal-init-defaults, terminal-is-empty | `ThemeTerminalOptions()` | all eight fields `nil`; `isEmpty` is true |
| themeoptions-002 | terminal-is-empty | `ThemeTerminalOptions(paddingTop: 0)` | `isEmpty` is false; zero is a value, not nil |
| themeoptions-003 | terminal-is-empty | each one of the eight fields set alone | `isEmpty` is false each time |
| themeoptions-004 | terminal-partial-override | `ThemeTerminalOptions(fontSize: 13)` | `fontSize == 13`; the other seven fields are `nil` |
| themeoptions-005 | project-init-defaults, project-is-empty | `ThemeProjectOptions()` | all three fields `nil`; `isEmpty` is true |
| themeoptions-006 | project-is-empty | `ThemeProjectOptions(highlightActivePane: false)` | `isEmpty` is false; `false` is a value, not nil |
| themeoptions-007 | codable-synthesized | encode `ThemeTerminalOptions(paddingTop: 4)` to JSON | object containing only the key `paddingTop` with value 4 |
| themeoptions-008 | codable-synthesized | decode `{}` as `ThemeTerminalOptions` and as `ThemeProjectOptions` | both succeed and `isEmpty` is true |
| themeoptions-009 | cursor-shape-raw-value | encode `TerminalCursorShape.hollowBlock` inside an array | `["hollowBlock"]` |
| themeoptions-010 | cursor-shape-decode-unknown | decode `["triangle"]` as `[TerminalCursorShape]` | throws a decoding error |
| themeoptions-011 | cursor-shape-cases, cursor-shape-traits | `TerminalCursorShape.allCases` | `[.block, .hollowBlock, .underline, .bar]` |
| themeoptions-012 | cursor-shape-label | the four `label` values | `"Block  ▉"`, `"Hollow Block  ▢"`, `"Underline  _"`, `"Bar  |"` |
| themeoptions-013 | cursor-shape-no-blink, terminal-fields | `ThemeTerminalOptions(cursorShape: .bar, cursorBlinks: true)` | shape and blink stored in separate fields; `cursorBlinks == true` |
| themeoptions-014 | codable-color-format, project-fields | encode `ThemeProjectOptions(paneOutline: RGBAColor(hexString: "#336699FF")!)` | JSON key `paneOutline` has the string `"#336699FF"`; the other two keys are absent |
| themeoptions-015 | codable-color-format | decode `{"paneBackdrop":"red"}` as `ThemeProjectOptions` | throws a decoding error |
| themeoptions-016 | codable-type-mismatch | decode `{"paddingTop":"4"}` as `ThemeTerminalOptions` | throws a decoding error |
| themeoptions-017 | terminal-traits, project-traits | two instances built from the same arguments | `==` is true; changing one field makes `==` false |
| themeoptions-018 | codable-synthesized | round trip `ThemeTerminalOptions(paddingTop: 2, paddingLeading: 3, paddingBottom: 4, paddingTrailing: 5, fontName: "FiraCodeNFM-Reg", fontSize: 12.5, cursorShape: .underline, cursorBlinks: false)` | decoded value equals the original |

