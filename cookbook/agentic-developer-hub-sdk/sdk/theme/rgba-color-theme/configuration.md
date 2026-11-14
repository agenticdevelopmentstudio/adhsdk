
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `black` (in `bestTextColor`) | `RGBAColor` | `opaqueBlack` | The dark candidate returned when it contrasts better |
| `white` (in `bestTextColor`) | `RGBAColor` | `opaqueWhite` | The light candidate returned on a tie or when it contrasts better |
| `amount` (in `desaturated`) | `Double` | 1 | Fraction of the way to the grey, clamped to 0 to 1 |
| `fraction`, `minContrast` (in `dimmed`) | `Double`, `Double` | none (required) | Starting blend toward the background, and the contrast floor against it |

Fixed values in the source: the 0.5 luminance threshold of `isDark`, the 0.03928 linearization threshold, the 0.05 step of `dimmed`, and the Rec. 601 weights 0.299, 0.587 and 0.114. There are no environment variables, settings keys or injected dependencies.

