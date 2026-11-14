
`RGBAColor` is a platform-neutral color value with four `Double` components (`red`, `green`, `blue`, `alpha`) held in the range 0 to 1. It exists so theme and settings data can be stored without a dependency on `NSColor` or `UIColor`: it encodes as the string `"#RRGGBBAA"`, which round-trips through `UserDefaults`. The source's own comment says UI layers add the platform-color bridge. It is a pure value type with no I/O and no state.

The source file also defines three constants (`black`, `white`, `clear`). Luminance, blending and compositing helpers live in a separate extension file (`RGBAColor+Theme.swift`) and belong to the theme layer, not to this contract.

