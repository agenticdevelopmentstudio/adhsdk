
- **Theme with no CSS-declared body size** (MUST): `sizeScale` stays 1.0 rather than a guessed ratio; eight themes are in this state (test `bodyFontSizeIsPortedAsAScale`, Charcoal).
- **Web gradient where `ColorTheme` holds a solid** (MUST): the first colour stop is used, sampled deterministically, and the rest of the gradient is dropped. This is lossy by design and recorded in the doc comment on Whimsical.
- **Theme that declares no bubble fill** (MUST): the fill is an explicit `#00000000` override, not a missing key, so derivation cannot invent a visible bubble.
- **Theme with no `--color-warning` or `--color-link`** (MUST): CRT Monitor and Handheld Communicator fill `ansi` slots 3 and 11 from the accent and slots 5 and 13 with `#005fffff`.
- **Fully transparent `background`** (MUST): CRT Monitor and Handheld Communicator carry `#00000000`, so `ansi[0]` is also transparent; a consumer that needs an opaque cell colour must composite it, because this source does not.
- **Optional chat roles absent** (MUST): a missing `sendButton` role, bubble border or `thinkingDoneText` key means "derive", not "transparent" or "none". Where web means transparent the source says so with `#00000000`.
- **Font family not installed** (SHOULD): the source names only the first family of each web stack and records no fallback chain; its doc comments state the face falls back to the system face at the same metrics when the family is not installed. Only `VT323` is bundled and registered (by `ToolkitFonts`); every other family relies on the host's installed fonts. That fallback is applied where `FontStyle` is resolved to a platform font, outside this file.
- **Malformed colour literal** (MUST): `RGBAColor(hexString:)` returns nil for anything but 8 hex digits after an optional leading `#`, and this file force-unwraps, so a bad literal traps on first read. The generator is responsible for emitting valid literals.
- **Native adjustment over a generated theme** (MUST): `webPortedNative` replaces Fishlamp's `selection` with `#232831ff`, sets `card` and `selectionEdge` overrides and a `project` backdrop, so the shipped Fishlamp differs from the generated one in `webPorted`.
- **Concurrent access**: not applicable — every theme is an immutable `static let` value built once from literals, with no mutation path in this source.
- **Offline or disconnected state**: not applicable — the file performs no network or file access.
- **Null and empty input**: not applicable — the catalogue takes no input; the only absent values are intentional, such as the optional roles above and the `project` options, which only Fishlamp's native adjustment sets.
- **Boundary values**: the `sizeScale` values here (0.8667 to 1.2667) sit inside `ThemeTypography.sizeScaleRange` (0.5 to 4), so the range clamp never applies to them.

