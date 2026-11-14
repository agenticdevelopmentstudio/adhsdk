
| String Key | Default (en) | Context |
|-----------|---------------|---------|
| `dev-banner.default-message` | `Development Preview — Coming Soon!` | Fallback text rendered when no `message` prop is supplied. The source hardcodes this string rather than resolving it from a localization resource (see Compliance: `no-hardcoded-strings`); consumers targeting non-English audiences SHOULD supply a localized `message` instead of relying on the default. |

The container's CSS applies `text-transform: uppercase` to the rendered message. This casing transform is locale-sensitive — for example, Turkish distinguishes dotted/dotless `İ`/`i` under uppercase rules that differ from other Latin-script locales — so translators should verify how their locale's uppercase form renders rather than assuming a simple ASCII mapping.

