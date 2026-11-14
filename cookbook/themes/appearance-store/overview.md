
The appearance store is the one in-memory holder of the user's `AppearancePrefs` (colour mode, reduce motion, contrast, text size, spacing, focus outlines, underline links) on a web page. It is a module-level external store read through `useSyncExternalStore`, so no React Context or Provider is needed. A change made through it is cached in `localStorage`, painted onto `<html>` as the `dark` class and `data-*` attributes, and announced to subscribed components. The module also owns the single OS colour-scheme listener that re-resolves colour mode `auto`.

`localStorage` is only a per-browser cache. The truth lives on the server, and the consuming application reconciles the two through `adoptAppearance` (sign-in: the server's prefs win) and `resetAppearance` (sign-out: back to the OS setting, cache cleared). Neither call is made from inside this module. The module makes no network call itself.

A site that wears the prefs on only some routes mounts a scope (`mountAppearanceScope`, or the `AppearanceScope` component) on those routes. Once any scope has mounted, the store paints `<html>` only while at least one scope is mounted.

The pure logic it builds on (the defaults, normalisation, the storage reads and writes, `applyAppearance`, `clearAppearance`) lives in `appearance.ts` and is shared with the pre-paint script; this recipe specifies only the store layered over it.

