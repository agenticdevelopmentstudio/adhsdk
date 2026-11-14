
Appearance is the pure, framework-agnostic logic behind a user's color mode and accessibility display choices. It owns the `AppearancePrefs` shape, the defaults, the normalization of untrusted stored data, the per-browser `localStorage` cache, and the mapping from preferences onto an HTML element (the `dark` class and `data-*` attributes the theme CSS keys off).

"Default" or "auto" means follow the system (or the theme's own default). It is represented by the absence of an attribute, so an unset preference leaves the document pristine and the matching media query (`prefers-color-scheme`, `prefers-reduced-motion`, `prefers-contrast`) governs.

Two consumers share this code so there is one source of truth for the storage key, the defaults and the DOM mapping: the React store (`appearance-store.tsx`) and the pre-paint inline script (`APPEARANCE_PREPAINT_SCRIPT`). The storage key, the enum-pref defaults, the boolean-pref list and the pre-paint script live in a plain `.mjs` file (`appearance-prepaint.mjs`) so a Vite or Next config, which runs in plain Node, can load them. The same file exports an `appearancePrepaint()` Vite plugin that inlines the script at the end of `<head>`.

This recipe describes the logic, not the React store, the settings panel or the server sync that reconcile the cache with the signed-in user's saved preferences; those are separate components.

