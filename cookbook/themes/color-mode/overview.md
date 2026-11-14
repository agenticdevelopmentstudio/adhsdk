
Color Mode is the legacy, Provider-based color-mode context of the customer-facing toolkit. `ColorModeProvider` holds the user's choice (`auto`, `light` or `dark`), resolves `auto` against the operating system's `prefers-color-scheme` setting, persists the choice in `localStorage`, and writes the result onto the document root. `useColorMode` gives descendants the choice, the resolved mode, a setter and a cycle operation.

The source's header comment states that the ADH chrome and sites use a newer, Provider-free appearance system instead (`appearance.ts` and `appearance-store.tsx`, storage key `adh:appearance`, attribute `data-color-mode`), that the two are intentionally separate, and that they must not both be mounted on one document. This recipe covers only the legacy context.

