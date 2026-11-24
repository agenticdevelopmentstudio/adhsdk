
Applicable. The component currently builds every label by concatenating a verb, an optional quoted target name, and a suffix (`labelFor`) at render time, and capitalizes the noun for the trigger label. Concatenation breaks in languages whose word order differs from English, so each label MUST be authored as a single, whole, localized template string with named placeholders — never assembled from separately translated fragments:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| category_gear_menu.trigger_label | "{noun} actions" | Trigger label; `{noun}` is the capitalized noun |
| category_gear_menu.add | "Add {noun}…" | Add item label |
| category_gear_menu.rename | "Rename…" | Rename item label, no target |
| category_gear_menu.rename_target | 'Rename "{target}"…' | Rename item label, with target |
| category_gear_menu.move | "Move…" | Move item label, no target |
| category_gear_menu.move_target | 'Move "{target}"…' | Move item label, with target |
| category_gear_menu.file | "Also file in…" | File item label, no target |
| category_gear_menu.file_target | 'Also file "{target}" in…' | File item label, with target |
| category_gear_menu.delete | "Delete…" | Delete item label, no target |
| category_gear_menu.delete_target | 'Delete "{target}"…' | Delete item label, with target |

The trigger label's initial-letter capitalization of `noun` is a casing transform and therefore locale-sensitive: implementations MUST apply the current locale's casing rules (e.g., a locale-aware title-case call), never an invariant-culture uppercasing call, since which letters change case — and whether capitalization applies at all — varies by language.

