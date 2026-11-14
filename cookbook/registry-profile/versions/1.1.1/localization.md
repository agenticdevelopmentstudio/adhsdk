
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| field-visibility.authenticated | "Signed-in members only" | Marker text shown when a field is visible only to authenticated users |
| field-visibility.private | "Private" | Marker text shown when a field is marked private |
| metadata.category | "Category" | Label for the category metadata row |
| metadata.location | "Location" | Label for the location metadata row |
| metadata.languages | "Languages" | Label for the languages metadata row |
| nav.elsewhere | "Elsewhere" | aria-label for the links navigation section |

These keys describe intent, not an implemented lookup: the TypeScript source hardcodes each string as an English literal (the `AUDIENCE_NOTE` record, and the `"Category"`/`"Location"`/`"Languages"`/`"Elsewhere"` literals inline in `RegistryProfile.tsx`). There is no resource file, i18n library call, or override prop. A host that needs another language must fork the component or wrap it; the component itself provides no localization mechanism.

