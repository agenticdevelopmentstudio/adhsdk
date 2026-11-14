
- **Decision**: Silently ignore localStorage read/write failures instead of surfacing an error.
  **Rationale**: This prioritizes resilience over error reporting. In an inaccessible environment (private browsing, quota exceeded), the hint simply reappears on every visit rather than breaking the page. The source chose silent degradation over logging to a telemetry service or falling back to an in-memory store.
  **Approved**: pending

- **Decision**: Render a literal "×" character as the close affordance rather than an icon or a "Close" text label.
  **Rationale**: "×" is a widely understood visual convention for dismissible UI. Implementations on other platforms MAY substitute a platform-idiomatic close affordance (e.g., the iOS system close symbol, Material Design's close icon) while preserving the semantic `aria-label="Dismiss"`.
  **Approved**: pending

- **Decision**: Hardcode the close button's `aria-label` to the English string "Dismiss" rather than exposing it as a configurable/localizable prop.
  **Rationale**: The source has no localization plumbing, so adding a `dismissLabel` prop would be behavior this recipe does not describe. Implementations that need localization SHOULD add an optional label prop that defaults to a localized "Dismiss" string — see **Localization** above.
  **Approved**: pending

- **Decision**: Store dismissal as the single-character string `"1"` rather than a boolean or JSON value.
  **Rationale**: This is a minimal storage choice. The comparison `getItem(...) === '1'` treats any missing or mismatched value as "not dismissed," so no separate presence check is needed.
  **Approved**: pending

- **Decision**: Document the localStorage key and CSS class prefix as the template variable `{{app_prefix}}` (e.g. `{{app_prefix}}-hint-dismissed:<id>`, `{{app_prefix}}-hint`) rather than the literal `aws-` string found in the source file.
  **Rationale**: Per this cookbook's Template Variables convention, consumer-specific literals must not be hardcoded into a shared recipe; `aws-` is specific to the source application. Every platform port MUST use the same `<prefix>-hint-dismissed:<id>` key scheme so dismissal state stays consistent across ports.
  **Approved**: pending

