
- **Missing ANSI slot**: `ColorTheme.ansiColor(at:)` returns nil for a slot beyond the theme's `ansi` array, so the status roles fall back to `fg`. MUST.
- **Empty ANSI table**: all chart and identity candidates from ANSI slots vanish; `chartSeriesColors` still returns the five semantic colors and `identitySeriesColors` falls back to them. MUST.
- **Low-contrast imported scheme**: `dimmed` shrinks its blend in steps of 0.05 until the minimum contrast holds; if no step reaches it, the result is `fg` unchanged. MUST.
- **Overridden parent role**: an override on `accent` or `elevatedSurface` does not flow into the roles derived from them; see `chains-use-derived-parents`. MUST (to match the source).
- **Translucent override**: an override such as a 40%-alpha color is returned as stored; resolution never composites it. The source gives no step that does. MUST.
- **Scale boundary**: `scaled(by:)` at 0.5 and 4 are accepted unchanged and anything outside is clamped; a factor of exactly 1 returns the same palette. MUST.
- **Non-finite scale factor**: `ThemeTypography.clampedSizeScale` maps NaN and infinities to 1.0, so `scaled(by:)` returns the receiver unchanged. MUST.
- **Compounded scale beyond the range**: each call clamps only its own factor, so two calls of 4 give a reader scale of 16. The source applies no cap to the product. MUST (to match the source).
- **Concurrent access**: not a concern; every property is an immutable `let` on a `Sendable` struct, and a scaled palette is a new value rather than a mutation.
- **Offline or disconnected state**: not applicable; the type does no I/O.
- **Cancellation and timeouts**: not applicable; every operation is synchronous, and the only loop (`dimmed`) takes at most 20 iterations.
- **Duplicate identity hues**: two ANSI slots with equal colors yield one entry in `identitySeriesColors`. MUST.

