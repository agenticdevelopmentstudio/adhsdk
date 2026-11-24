
The `useHelpEntry` hook does not implement logging or console warnings itself; it returns `undefined` when an entry is not found. Consuming components (such as `<HelpEnabled>`, [adhsdk.ingredient.ui.components.overlays.help-enabled](cookbook:fcb8a0a4-2446-46f9-99bb-49b0317529d4)) are responsible for warning to the console when an unknown id is requested, preventing downstream components from rendering popovers with undefined content.

