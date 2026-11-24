
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `facet.all` | "All" | Quick-select button to select all options |
| `facet.none` | "None" | Quick-select button to clear all selections |
| `facet.trigger_count` | "{label} ({count})" | Trigger text combining the filter label with its selected count; MUST be produced through a locale-aware, plural-capable formatter (e.g., ICU MessageFormat) rather than a fixed "(N)" template, since numeral placement and pluralization are not the same across locales |

The component does not provide i18n keys for option labels; label strings come from the `options` array or the `labelOf` function, which are the responsibility of the host application to localize. If a host's `labelOf` applies a casing transform (for example, upper-casing an option value), that transform is locale-sensitive and MUST use a locale-aware casing API — never an invariant-culture call — because the option label is user-facing text.

