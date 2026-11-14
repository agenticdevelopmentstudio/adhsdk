
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `APPEARANCE_STORAGE_KEY` | string | `adh:appearance` | `localStorage` key for the cached preferences |
| `APPEARANCE_DEFAULTS` | `AppearancePrefs` | see `defaults-values` | Starting preferences and the fallback for invalid fields |
| `ENUM_PREF_DEFAULTS` | frozen object | see `enum-pref-defaults-shared` | Per-key value meaning "attribute off" |
| `BOOL_PREFS` | frozen string array | `focusOutlines`, `underlineLinks` | Boolean preference keys written as `always` |
| `systemPrefersDark` | boolean | none (caller supplies) | Argument to `applyAppearance`; the already-resolved OS dark preference |
| `el` | `HTMLElement` | none (caller supplies) | Argument to `applyAppearance` and `clearAppearance`; normally `document.documentElement` |

