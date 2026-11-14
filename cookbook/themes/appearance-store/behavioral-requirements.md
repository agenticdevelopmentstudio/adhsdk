
### Public surface

- **exports**: The module MUST export `mountAppearanceScope`, `AppearanceScope`, `adoptAppearance`, `resetAppearance`, `useAppearancePreferences` and the `UseAppearancePreferences` interface (`prefs: AppearancePrefs`, `set: (patch: Partial<AppearancePrefs>) => void`). The package index re-exports all of them.
- **client-only-module**: The module MUST carry the `"use client"` directive, because it holds module state and calls React hooks.
- **no-provider**: The store MUST work without a Provider or Context: every reader sees the same module-level state.

### Reading the preferences

- **lazy-snapshot**: The first read of the snapshot MUST load the prefs with `readStoredAppearance()` and hold the result; later reads MUST return that same object until a commit replaces it.
- **snapshot-stability**: The snapshot returned between commits MUST be the identical object (reference equality), as `useSyncExternalStore` requires.
- **server-snapshot**: The server snapshot MUST be `APPEARANCE_DEFAULTS`, so server rendering and the first client render agree.
- **hook-shape**: `useAppearancePreferences()` MUST return an object `{ prefs, set }` that keeps its identity while `prefs` is unchanged; `set` MUST keep its identity for the lifetime of the component.
- **hook-subscribes**: A component using the hook MUST re-render after every commit that replaces the snapshot.
- **subscribe-unsubscribe**: `subscribe(listener)` MUST add the listener to a set, and the function it returns MUST remove that listener.

### Writing the preferences

- **set-merges**: `set(patch)` MUST commit the current snapshot with `patch` spread over it, so unspecified fields keep their value.
- **set-caches**: `set(patch)` MUST write the merged prefs to `localStorage` under `APPEARANCE_STORAGE_KEY`.
- **set-not-validated**: `set(patch)` MUST NOT validate or normalise the patch; the `Partial<AppearancePrefs>` type is the only guard. (Stored values are normalised on read by `readStoredAppearance`; patches are not.)
- **adopt-wholesale**: `adoptAppearance(prefs)` MUST replace the held prefs with `prefs` entirely, not merge, and MUST write them to `localStorage`.
- **adopt-not-validated**: `adoptAppearance` MUST NOT normalise its argument. The caller is expected to pass a complete `AppearancePrefs`; the in-repo caller `AppearanceSync` runs `normalizeAppearance` first.
- **reset-defaults**: `resetAppearance()` MUST replace the held prefs with a fresh copy of `APPEARANCE_DEFAULTS` (colour mode `auto`, `compact` spacing, every other pref at its default).
- **reset-clears-cache**: `resetAppearance()` MUST remove the `localStorage` entry rather than overwrite it, so the next visitor on a shared browser does not inherit the previous user's theme through the pre-paint script.
- **commit-order**: Every commit MUST, in this order: replace the held prefs, write or clear the cache, paint the document if allowed, then notify every listener.
- **notify-sync**: Listeners MUST be called synchronously inside the commit, in set insertion order.
- **cache-failure-silent**: A failed `localStorage` write or removal (private mode, quota) MUST NOT stop the commit: the held prefs, the paint and the notification still happen. `writeStoredAppearance` and `clearStoredAppearance` swallow the error with an explanatory comment, so the failure is not signalled.

### Painting the document

- **paint-call**: When a commit paints, it MUST call `applyAppearance(document.documentElement, next, systemDark)` where `systemDark` is the OS dark-scheme query's `matches`, or `false` when no query exists.
- **paint-needs-document**: A commit MUST NOT paint when `document` is undefined (server); it still updates state, cache and listeners.
- **paints-rule**: The store MUST paint only when the site is unscoped or at least one scope is mounted: always on a site that never mounted a scope, and only while a scope is mounted on a site that has.
- **colour-mode-everywhere**: Colour mode MUST be honoured in every environment; the store applies no environment-based lock (the comment on `applyAppearance` records that production once pinned dark).

### OS colour-scheme following

- **os-listener-once**: At module load, on the client, the store MUST attach exactly one `change` listener to the `(prefers-color-scheme: dark)` media query, shared by the whole app and never removed.
- **os-listener-guards**: The module MUST NOT throw at load when `window` is undefined, when `window.matchMedia` is not a function, or when the query has no `addEventListener` (Safari before 14 has only `addListener`). In those hosts there is no OS signal, and `auto` resolves to light.
- **os-change-repaint**: On an OS change the store MUST repaint only when the held prefs exist, their colour mode is `auto`, and painting is allowed by the paints rule.
- **os-change-explicit-mode**: On an OS change the store MUST NOT repaint when the colour mode is `light` or `dark`.
- **os-change-unread**: On an OS change before any snapshot has been read (nothing held), the store MUST do nothing.
- **os-other-prefs-css**: Reduced motion and contrast MUST NOT need JavaScript on an OS change; the CSS `@media` queries handle them, so only the `dark` class is re-resolved.

### Scopes

- **scope-mount-arms**: `mountAppearanceScope()` MUST mark the site as scoped for the rest of the page's life and increment the mounted count.
- **scope-first-paint**: When the mount takes the count from 0 to 1, it MUST paint the snapshot the store holds now (reading the cache if nothing is held yet), so a commit made while no scope was mounted becomes visible.
- **scope-nested**: Mounts MUST nest: with two scopes mounted, painting continues until both have released.
- **scope-last-release-clears**: The release that takes the count to 0 MUST call `clearAppearance(document.documentElement)`.
- **scope-release-once**: The release function MUST count only once; calling it again MUST do nothing.
- **scope-unmounted-no-paint**: While no scope is mounted on a scoped site, a commit MUST still update the held prefs and the cache and notify listeners, but MUST NOT paint `<html>`.
- **scope-unscoped-paints**: A site that never mounts a scope MUST keep painting on every commit and every OS change.
- **scope-component**: `AppearanceScope` MUST render nothing (`null`) and MUST mount a scope in a layout effect with an empty dependency list, releasing it on unmount.
- **scope-needs-document**: `mountAppearanceScope` MUST be called only where `document` exists (a layout effect). Called with no `document`, it throws; no guard is provided.

