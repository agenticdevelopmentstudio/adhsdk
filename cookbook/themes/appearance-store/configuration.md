
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `APPEARANCE_STORAGE_KEY` | string constant | `adh:appearance` | The `localStorage` key holding the cached prefs, defined in `appearance-prepaint.mjs` and shared with the pre-paint script |
| `APPEARANCE_DEFAULTS` | `AppearancePrefs` | colour mode `auto`, reduce motion `auto`, contrast `default`, text size `default`, spacing `compact`, focus outlines `false`, underline links `false` | Used for the server snapshot and by `resetAppearance` |
| `(prefers-color-scheme: dark)` | media query | read from `window.matchMedia` once at module load | The OS signal for colour mode `auto`; absent means light |
| Scope mounting | caller choice | none (site is unscoped) | A site opts in to route-scoped painting by mounting `AppearanceScope` or calling `mountAppearanceScope`; there is no way to opt back out |

