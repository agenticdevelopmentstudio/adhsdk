
`ThemeTypography` is the typography half of a theme. It holds one `FontStyle` per `TextRole` plus a global `sizeScale` that multiplies every role's size at once. UI code reads fonts by role (`title`, `heading`, `body`, `caption`, `code`, `button`) the way it reads colors by `ThemeRole`, so a label's meaning survives a theme swap and a global size change.

The source file defines four public types and two clamp helpers: `TextRole` (enum), `FontWeight` (enum), `FontStyle` (struct) and `ThemeTypography` (struct, with `sizeScaleRange` and `clampedSizeScale(_:)`). It imports only `Foundation`; the source comment says `FontWeight` is bridged to `NSFont.Weight` in CoreMacOS so the Core model stays Foundation-only. The bridges to platform fonts live in separate files (the iOS bridge is `ThemeTypography+UIFont.swift`) and are not part of this contract. A `ColorTheme` carries a `ThemeTypography` as its `typography` property (see [ColorTheme](cookbook:932449c9-b57f-4e2c-992a-1e27584742b6)).

