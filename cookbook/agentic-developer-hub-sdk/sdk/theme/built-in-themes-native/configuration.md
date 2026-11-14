
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `BuiltInThemes.webPorted` | `[ColorTheme]` | the generated list | The input list, read from `BuiltInThemes+Web.swift`; the only dependency this file takes |
| `theme.id` | `String` | per theme | The key `nativeAdjusted` switches on |
| `ember` | `RGBAColor` | `#17130fff` | Fishlamp's card colour and pane backdrop |
| Fishlamp selection | `RGBAColor` | `#232831ff` | Cool slate selection fill |
| Fishlamp selection edge | `RGBAColor` | `#e8a33dff` | Amber line marking a selection |

The file reads no environment variables or settings keys and injects no dependencies.

