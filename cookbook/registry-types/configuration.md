
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `def.type` | `FieldType` | — (caller-supplied; no default) | Selects which validation, coercion, search-extraction, and default-visibility rules apply. |
| `def.required` | `boolean` | — (caller-supplied; no default) | Gates whether an empty value is acceptable and whether the field can block publish. |
| `def.config.maxLength` | `number` | Type-specific: 255 (`text`), 2000 (`textarea`), 20000 (`markdown`), 2048 (`url`), 254 (`email`) | Overrides the default length cap for the string-shaped types that have one. |
| `def.config.maxItems` | `number` | 50 (`MULTI_SELECT_MAX_ITEMS`) | Overrides the maximum selection count for `multi_select`. |
| `def.config.options` | `string[]` | Absent/empty (no restriction) | Restricts accepted values for `select` and `multi_select`. |
| `def.showIf` | `ShowIfRule \| null` | Absent/`null` (always shown) | Controls whether the field is currently visible and whether `required` applies. |
| `def.deletedAt` | `string \| null` | `null` | When truthy, excludes the field from `publishBlockers` regardless of its other settings. |
| `def.label` | `string` | Falls back to `def.key` | Text `publishBlockers` reports for the field in the registrant-facing checklist. |
| `def.visibility` (as read by `searchableText`) | `FieldVisibility` | Absent (treated as always eligible to contribute text) | When present and not `'public'`, withholds the field's value from `searchableText`. |
| Field-visibility ceiling (as read by `isWithinVisibility`/`visibilitiesWithin`) | `FieldVisibility` | — (caller-supplied per field definition) | Bounds how loose a registrant may set that field's own visibility. |

