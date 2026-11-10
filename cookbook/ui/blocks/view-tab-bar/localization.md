
Labels are provided as `ReactNode` props (text, icons, or composed elements). The component does not perform any string localization. Callers MUST provide locale-specific labels via the `label` prop.

| String Key | Source | Context |
|-----------|--------|---------|
| N/A | Caller-provided `tabs[].label` and `links[].label` | User-facing tab and link text |
| `aria-label="views"` | Hardcoded in component | Semantic label for the navigation section |

The `aria-label="views"` string above is a literal in the component source (`view-tab-bar.tsx`); it is not exposed as a prop, so callers cannot override or localize it (see Compliance).

