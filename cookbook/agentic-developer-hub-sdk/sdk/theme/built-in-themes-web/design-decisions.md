
**Decision**: Port only 21 of the web manifest's 39 themes, leaving out the eight `adh*` font variants and ten editor palettes.
**Rationale**: The font variants differ only in typography, a web font-loading concern with no Swift analogue. The editor palettes already ship in Swift as terminal themes with real ANSI palettes, and the web copies would be the worse duplicate.
**Approved**: pending

**Decision**: Fill `ansi` as a best-effort derivation from semantic colours instead of porting an ANSI palette.
**Rationale**: These are brand themes and web defines no ANSI colours for them. The array exists only to satisfy the terminal feature; the exact web values that drive chat live in `roleOverrides`.
**Approved**: pending

**Decision**: Override both bubble fills to fully transparent in the seven flat terminal themes instead of omitting them.
**Rationale**: The web CSS declares no fill and `.pc-bubble` draws no box. Leaving the roles to derive had given Old School Terminal a grey slab the website has never drawn. An explicit transparent value lets the chat view read the theme as a flat transcript line.
**Approved**: pending

**Decision**: Carry web body size as a `sizeScale` ratio against a 15px baseline, not as absolute point sizes.
**Rationale**: AppKit metrics are not CSS pixels (body is 13pt by default), so transcribing pixels would make every ported theme about a fifth larger than every Swift-native theme. A ratio preserves what each theme said relative to its siblings, including the CSS note that VT323 renders small and needs a bump.
**Approved**: pending

**Decision**: Reduce a gradient to its first colour stop and a font stack to its first family plus a monospaced flag.
**Rationale**: `ColorTheme` holds solid `RGBAColor` values and `FontStyle` holds one family and a flag. The first stop is deterministic and keeps the dominant hue; the doc comments record the loss.
**Approved**: pending

**Decision**: Keep native-only changes in `BuiltInThemes+Native.swift` rather than in the generated file.
**Rationale**: The generated file must not be hand-edited, and the web catalogue has no tokens for native chrome such as the selection fill and cards. Applying the changes over the generated values means a generator re-run cannot silently drop them.
**Approved**: pending

**Decision**: Keep `thinkingDoneText` out of Old School Terminal although it shares a phosphor palette with the two CRT themes.
**Rationale**: Its CSS does not declare `--pc-thinking-done-color`, and a green settled line on that theme, the one the olylo chat wears, read as a turn still running. Sharing a palette is not the same as sharing the answer to this question.
**Approved**: pending

