
- **Null targetName**: When targetName is null (no selection), labels use the bare verb form without a target name reference (e.g., "Rename…" instead of `Rename "{name}"…`).
- **Omitted noun**: When the `noun` prop is not provided, the default parameter substitutes "category" (lowercase in item labels, capitalized to "Category" in the trigger label).
- **Empty string noun**: When `noun=""` is passed explicitly, the default parameter does not apply (defaults only substitute for `undefined`, not for an empty string), so the noun stays empty: item labels read "Add …" and the trigger label reads " actions" (leading space, no noun).
- **Custom noun**: When noun is provided (e.g., "tag", "note"), labels and trigger are updated accordingly (e.g., trigger reads "Tag actions", add reads "Add tag…").
- **Disabled with no target**: When both disabled=true and canEditTarget=false, the trigger is disabled and all target-specific actions are also disabled in the UI.
- **Rapid clicking**: The component does not debounce. Each click on an enabled item invokes `onAction` once, so clicking a menu item multiple times before the menu closes invokes the callback that many times; hosts MUST tolerate repeated identical calls.
- **Dynamic targetName change**: If targetName prop changes while menu is open, labels reflect the new target immediately.

