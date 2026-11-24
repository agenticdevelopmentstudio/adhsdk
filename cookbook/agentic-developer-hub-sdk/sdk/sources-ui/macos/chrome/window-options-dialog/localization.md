
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `window-options.gear.tooltip` | `"Window appearance"` | Gear button tooltip; would typically be localized per host app. |
| `window-options.reset.title` | `"Reset to Defaults"` | Reset button title; shared across all window option dialogs in the app. |

The source does not yet look these strings up by key — `WindowOptionsResetButton.title` and the default tooltip are Swift string literals with no resource-file lookup. The keys above are the target shape for wiring in localization; see Compliance: `string-externalization`.

All other user-facing strings (control titles, captions) are supplied by the host via `makeControls()` and are the host's responsibility to localize.

