Every vector is asserted by a test whose title starts with its id: `appearance.test.ts` covers all but appearance-016 and appearance-017, which `clearAppearance.test.ts` covers. The store tests (`appearanceScope.test.ts`, `AppearanceScope.test.tsx`) exercise apply and clear through the store as well.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| appearance-001 | defaults-values, normalize-non-object | `normalizeAppearance(null)` | Equals `APPEARANCE_DEFAULTS`, as a different object |
| appearance-002 | normalize-per-field | `normalizeAppearance({ colorMode: "dark", contrast: "high", textSize: "huge", focusOutlines: true })` | `colorMode: dark`, `contrast: high`, `focusOutlines: true`; `textSize` stays `default`; others default |
| appearance-003 | normalize-per-field | `normalizeAppearance({ focusOutlines: "true", underlineLinks: 1 })` | Both stay `false` |
| appearance-004 | normalize-non-object, normalize-no-throw | `normalizeAppearance("dark")` and `normalizeAppearance(0)` | Defaults, no throw |
| appearance-005 | normalize-drops-unknown | `normalizeAppearance({ theme: "x", spacing: "spacious" })` | `spacing: spacious`; result has exactly the seven keys |
| appearance-006 | read-missing, storage-key | Empty `localStorage`, `readStoredAppearance()` | Defaults |
| appearance-007 | read-normalizes | `localStorage["adh:appearance"] = '{"colorMode":"light","spacing":"nope"}'` | `colorMode: light`, `spacing: compact` |
| appearance-008 | read-failure | `localStorage["adh:appearance"] = "{not json"` | Defaults, no throw |
| appearance-009 | write-failure | `localStorage.setItem` throws a quota error; `writeStoredAppearance(prefs)` | Returns without throwing |
| appearance-010 | write-serializes, clear-stored | Write `prefs`, then `clearStoredAppearance()` | Key holds `JSON.stringify(prefs)` after the write; key absent after the clear |
| appearance-011 | apply-resolves-dark | `applyAppearance(el, { ...defaults, colorMode: "auto" }, true)` | `el` has class `dark`, `data-color-mode="auto"` |
| appearance-012 | apply-resolves-dark | `applyAppearance(el, { ...defaults, colorMode: "light" }, true)` | No `dark` class, `data-color-mode="light"` |
| appearance-013 | apply-enum-attributes, apply-bool-attributes | `applyAppearance(el, defaults, false)` | `el` has only `data-color-mode="auto"`; no other `data-*` attribute |
| appearance-014 | apply-enum-attributes, apply-bool-attributes | `applyAppearance(el, { ...defaults, reduceMotion: "on", contrast: "extra-high", spacing: "spacious", underlineLinks: true }, false)` | `data-reduce-motion="on"`, `data-contrast="extra-high"`, `data-spacing="spacious"`, `data-underline-links="always"`; no `data-focus-outlines` |
| appearance-015 | apply-enum-attributes | Apply a non-default `contrast`, then apply `contrast: default` | `data-contrast` is removed |
| appearance-016 | clear-undoes-apply | An `html` element with class `font-a font-b` and `lang="en"`; `applyAppearance(el, { colorMode: "dark", reduceMotion: "on", contrast: "high", textSize: "large", spacing: "spacious", focusOutlines: true, underlineLinks: true }, true)`, then `clearAppearance(el)` | After apply `outerHTML` differs from the original; after clear it equals the original `<html class="font-a font-b" lang="en"></html>` |
| appearance-017 | clear-undoes-prepaint, clear-removes-all | An `html` element with `data-color-mode="auto"` and class `dark`; `clearAppearance(el)` | `data-color-mode` is absent and the `dark` class is gone |
| appearance-018 | prepaint-resolve-dark, prepaint-colormode-attribute | Run the script with `{"colorMode":"dark"}` stored | `dark` class on `<html>`, `data-color-mode="dark"` |
| appearance-019 | prepaint-resolve-dark, prepaint-colormode-attribute | Run the script with nothing stored and `matchMedia` reporting dark | `dark` class on `<html>`, `data-color-mode="auto"` |
| appearance-020 | prepaint-attributes | Run the script with `{"contrast":"default","textSize":"large","focusOutlines":false}` stored | `data-text-size="large"` set, with `data-color-mode="auto"` (always written); no `data-contrast`, no `data-focus-outlines` |
| appearance-021 | prepaint-swallows-errors | Run the script with the literal text `null` stored | No exception escapes; `<html>` is left without the `dark` class and without `data-color-mode` |
| appearance-022 | prepaint-no-validation | Run the script with `{"contrast":"bogus"}` stored | `data-contrast="bogus"` is written |
| appearance-023 | prepaint-position, prepaint-plugin-name | `appearancePrepaint().transformIndexHtml()` | One tag, `script`, `children` equal to `APPEARANCE_PREPAINT_SCRIPT`, `injectTo: "head"`; plugin `name` is `adh-appearance-prepaint` |
| appearance-024 | enum-pref-defaults-shared, bool-prefs-shared | `Object.isFrozen` on each of the two exports | `true` for both |
| appearance-025 | read-ssr-guard, write-ssr-guard, clear-stored | No `window`; `readStoredAppearance()`, `writeStoredAppearance(prefs)`, `clearStoredAppearance()` | The read returns a value equal to the defaults but not the same object as `APPEARANCE_DEFAULTS`; the write and clear do nothing and do not throw |
| appearance-026 | apply-idempotent | `applyAppearance(el, prefs, true)` called twice with the same `el` and `prefs` (`colorMode: "dark"`, `contrast: "high"`) | `outerHTML` after the second call equals `outerHTML` after the first |
| appearance-027 | apply-system-injected | `matchMedia` replaced with a function that throws; `applyAppearance(el, { ...defaults, colorMode: "auto" }, true)` | No exception; `el` has class `dark` |
| appearance-028 | colormode-not-in-enum-list | `Object.keys(ENUM_PREF_DEFAULTS)` | `["reduceMotion", "contrast", "textSize", "spacing"]`, with no `colorMode` |
| appearance-029 | write-does-not-normalize | `writeStoredAppearance({ ...defaults, colorMode: "bogus" })`, then read the raw `localStorage` value and call `readStoredAppearance()` | The raw value contains `"colorMode":"bogus"`; the read returns `colorMode: auto` |
| appearance-030 | normalize-returns-copy | `const a = normalizeAppearance({ colorMode: "dark" }); a.spacing = "spacious"`, then `normalizeAppearance(null)` | `APPEARANCE_DEFAULTS.spacing` is still `compact`, and the second result's `spacing` is `compact` |
