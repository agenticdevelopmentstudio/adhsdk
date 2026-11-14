
### Data shapes

- **prefs-shape**: `AppearancePrefs` MUST have exactly seven fields: `colorMode`, `reduceMotion`, `contrast`, `textSize`, `spacing`, `focusOutlines` and `underlineLinks`.
- **color-mode-values**: `colorMode` MUST be one of `auto`, `light`, `dark`.
- **reduce-motion-values**: `reduceMotion` MUST be one of `auto`, `on`, `off`.
- **contrast-values**: `contrast` MUST be one of `default`, `high`, `extra-high`.
- **text-size-values**: `textSize` MUST be one of `default`, `small`, `large`, `extra-large`.
- **spacing-values**: `spacing` MUST be one of `compact`, `comfortable`, `spacious`.
- **boolean-pref-values**: `focusOutlines` and `underlineLinks` MUST be booleans.
- **defaults-values**: `APPEARANCE_DEFAULTS` MUST be `colorMode: auto`, `reduceMotion: auto`, `contrast: default`, `textSize: default`, `spacing: compact`, `focusOutlines: false`, `underlineLinks: false`.
- **enum-pref-defaults-shared**: `ENUM_PREF_DEFAULTS` MUST map `reduceMotion` to `auto`, `contrast` to `default`, `textSize` to `default` and `spacing` to `compact`, and MUST be frozen. These are the values that mean "leave the attribute off".
- **bool-prefs-shared**: `BOOL_PREFS` MUST list `focusOutlines` and `underlineLinks`, and MUST be frozen.
- **storage-key**: `APPEARANCE_STORAGE_KEY` MUST be `adh:appearance`.
- **single-definition**: `applyAppearance`, `clearAppearance` and the pre-paint script MUST iterate the same `ENUM_PREF_DEFAULTS` and `BOOL_PREFS` lists, so adding a preference in one place updates all three. Source: the comments on `ENUM_PREF_DEFAULTS` and `PREPAINT_ATTR_LINES`.
- **colormode-not-in-enum-list**: `colorMode` MUST NOT appear in `ENUM_PREF_DEFAULTS`. It is handled separately because it sets a class as well as an attribute.

### normalizeAppearance

- **normalize-returns-copy**: `normalizeAppearance(raw)` MUST return a new `AppearancePrefs` object that starts as a copy of `APPEARANCE_DEFAULTS`, and MUST NOT mutate `APPEARANCE_DEFAULTS`.
- **normalize-non-object**: `normalizeAppearance` MUST return the defaults when `raw` is falsy or not an object (`null`, `undefined`, a string, a number, `false`, `0`).
- **normalize-per-field**: `normalizeAppearance` MUST accept each field independently, copying a field only when its value is a member of that field's allowed set (or a boolean for the two boolean fields), and MUST leave every other field at its default.
- **normalize-drops-unknown**: `normalizeAppearance` MUST ignore keys that are not one of the seven preference names.
- **normalize-no-throw**: `normalizeAppearance` MUST NOT throw for any input.

### Storage cache

- **read-ssr-guard**: `readStoredAppearance()` MUST return a copy of the defaults when `window` is undefined.
- **read-normalizes**: `readStoredAppearance()` MUST read `localStorage` under `APPEARANCE_STORAGE_KEY`, parse the value as JSON, and return it passed through `normalizeAppearance`.
- **read-missing**: `readStoredAppearance()` MUST return the defaults when the key is absent or empty.
- **read-failure**: `readStoredAppearance()` MUST return a copy of the defaults when storage access or JSON parsing throws. The failure is not reported.
- **write-serializes**: `writeStoredAppearance(prefs)` MUST store `JSON.stringify(prefs)` under `APPEARANCE_STORAGE_KEY`.
- **write-ssr-guard**: `writeStoredAppearance` MUST do nothing when `window` is undefined.
- **write-failure**: `writeStoredAppearance` MUST NOT throw when storage throws (private mode, quota). The write is dropped and the failure is not reported. Source: the comment `ignore (private mode / quota)`.
- **write-does-not-normalize**: `writeStoredAppearance` MUST write the object it is given without normalizing it; normalization happens on read.
- **clear-stored**: `clearStoredAppearance()` MUST remove the `APPEARANCE_STORAGE_KEY` entry. It MUST do nothing when `window` is undefined and MUST NOT throw when storage throws.
- **cache-not-truth**: The stored value MUST be treated as a per-browser cache of the signed-in user's preferences, which live on the server. Source: the comments on `clearStoredAppearance` and the pre-paint script. The cache is cleared on sign-out so it does not outlive the session on a shared browser; the caller, not this module, triggers that.

### applyAppearance

- **apply-resolves-dark**: `applyAppearance(el, prefs, systemPrefersDark)` MUST toggle the `dark` class on `el` to `systemPrefersDark` when `prefs.colorMode` is `auto`, to `true` when it is `dark`, and to `false` when it is `light`.
- **apply-colormode-attribute**: `applyAppearance` MUST always set `data-color-mode` to the value of `prefs.colorMode`, including `auto`.
- **apply-enum-attributes**: For each key in `ENUM_PREF_DEFAULTS`, `applyAppearance` MUST set the matching `data-*` attribute (the camelCase key mapped to kebab case, for example `reduceMotion` to `data-reduce-motion`) to the preference value when it differs from the default, and MUST remove the attribute when it equals the default.
- **apply-bool-attributes**: For each key in `BOOL_PREFS`, `applyAppearance` MUST set the matching `data-*` attribute to `always` when the preference is `true`, and MUST remove it when `false`.
- **apply-system-injected**: `applyAppearance` MUST NOT read `matchMedia` itself; the caller passes `systemPrefersDark`. Source: the doc comment, so the hook and the pre-paint script do not each re-read it.
- **apply-all-environments**: `applyAppearance` MUST honor the stored color mode in every environment, production included, with no environment lock. Source: the doc comment records that colour mode was once pinned dark outside local, staging and testing and that the pin was removed.
- **apply-idempotent**: Calling `applyAppearance` repeatedly with the same arguments MUST leave the element in the same state.

### clearAppearance

- **clear-removes-all**: `clearAppearance(el)` MUST remove the `dark` class, delete `data-color-mode`, and delete every `data-*` attribute for every key in `ENUM_PREF_DEFAULTS` and `BOOL_PREFS`.
- **clear-undoes-apply**: After `applyAppearance` followed by `clearAppearance`, the element MUST be byte-for-byte what it was before `applyAppearance`, including unrelated classes and attributes. Source: `clearAppearance.test.ts`.
- **clear-undoes-prepaint**: `clearAppearance` MUST also remove the attributes the pre-paint script writes for default values (`data-color-mode` set to `auto`, and the `dark` class).
- **clear-purpose**: `clearAppearance` exists for sites that mount the preferences on only some routes; a client navigation keeps the same `<html>`, so without it the preferences would follow the reader onto a page that never asked for them.

### Pre-paint script

- **prepaint-iife**: `APPEARANCE_PREPAINT_SCRIPT` MUST be a self-contained IIFE string that reads `localStorage` under `APPEARANCE_STORAGE_KEY`, parses the JSON, and applies the preferences to `document.documentElement` synchronously.
- **prepaint-resolve-dark**: The script MUST set the `dark` class to `false` for stored `light`, `true` for stored `dark`, and to the result of `matchMedia("(prefers-color-scheme: dark)").matches` for anything else, including no stored value.
- **prepaint-colormode-attribute**: The script MUST set `data-color-mode` to the stored `colorMode`, or to `auto` when it is absent or empty.
- **prepaint-attributes**: The script MUST set each enum attribute only when the stored value is present and differs from that key's default, set each boolean attribute to `always` only when truthy, and delete the attribute otherwise. Its attribute statements MUST be generated from `ENUM_PREF_DEFAULTS` and `BOOL_PREFS`.
- **prepaint-no-validation**: The script MUST NOT validate stored values against the allowed sets; it writes any non-default stored string as the attribute value. Stored data is normalized later by `normalizeAppearance` when the store reads it. This differs from `applyAppearance`, which is only ever handed normalized preferences.
- **prepaint-swallows-errors**: The script MUST wrap its whole body in a try/catch that discards the error. If storage is unavailable, or the stored JSON is invalid or is the literal `null`, the script stops where it failed and leaves whatever it had already applied (nothing, for those cases) so the page renders with system defaults.
- **prepaint-position**: The `appearancePrepaint()` Vite plugin MUST inject the script as an inline `<script>` at the end of `<head>` (`injectTo: "head"`), not the start, so `<meta charset>` stays within the first 1024 bytes the browser scans for the encoding.
- **prepaint-plugin-name**: The plugin MUST be named `adh-appearance-prepaint`.

### Concurrency and side effects

- **single-threaded**: All functions are synchronous and run on the browser main thread; they have no async operations and need no locking.
- **side-effects**: `applyAppearance` and `clearAppearance` mutate only the element passed in. The storage functions touch only `localStorage` under `adh:appearance`. Nothing makes a network call; server sync is outside this module.

