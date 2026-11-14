
The only test beside the source that exercises the provider is `AppearanceModeToggle.test.tsx` in the controls package, which wraps a toggle in `ColorModeProvider`; vectors 001 and 002 derive from its behavior and the rest from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| color-mode-001 | initial-mode-default, cycle-order | `AppearanceModeToggle.test.tsx` "exposes an aria-label that changes after a click": empty storage, system light, default props; the toggle calls `cycle()` once | `mode` goes `auto` to `dark`; the consumer's rendered label differs before and after |
| color-mode-002 | context-value-shape, hook-requires-provider | `AppearanceModeToggle.test.tsx` "renders a button with the awt-appearance-mode-toggle class" (the toggle renders inside `ColorModeProvider`); the same consumer rendered with no provider (derived from the source, not tested) | inside: `useColorMode` returns the context value; outside: throws `useColorMode must be used within a <ColorModeProvider>` |
| color-mode-003 | initial-mode-from-storage, invalid-stored-value-ignored | `localStorage['adh-sdk:color-mode']` is `dark`, then is `purple` | first render mode is `dark`; with `purple` the mode is `auto` |
| color-mode-004 | initial-mode-from-legacy-key, legacy-key-only-for-default, legacy-key-not-cleaned | only `localStorage['agentic-toolkit:color-mode']` is `light`; once with the default key and once with `storageKey="x"` | default key: mode `light` and `adh-sdk:color-mode` becomes `light`, legacy key untouched; custom key: mode `auto` |
| color-mode-005 | resolve-auto-from-system, dark-class | mode `auto`, `matchMedia('(prefers-color-scheme: dark)').matches` is true | `resolved` is `dark`, `document.documentElement` has class `dark`, `data-appearance-mode` is `auto` |
| color-mode-006 | system-change-listener | mode `auto`; the media query fires `change` with `matches: false` after being true | `resolved` becomes `light` and the `dark` class is removed |
| color-mode-007 | resolve-explicit-mode, appearance-mode-attribute | `defaultMode="light"` while the system is dark | `resolved` is `light`, no `dark` class, `data-appearance-mode` is `light` |
| color-mode-008 | persist-explicit-mode, persist-auto-removes | `setMode('dark')` then `setMode('auto')` | storage holds `dark` after the first call; the key is absent after the second |
| color-mode-009 | cycle-order, cycle-fallback | `cycle()` called four times from `auto` | modes are `dark`, `light`, `auto`, `dark` |
| color-mode-010 | cycle-event | `window.dispatchEvent(new CustomEvent('awt:appearance-cycle'))` from `auto` | mode becomes `dark` |
| color-mode-011 | changed-event | provider mounts, then `setMode('light')` | `awt:appearance-changed` is dispatched once on mount and once after the change |
| color-mode-012 | storage-failure-silent | `localStorage.getItem` and `setItem` throw | provider renders with `defaultMode`, `setMode` still updates state and the document, no exception reaches the caller |
| color-mode-013 | no-window-initial-mode, no-document-effects | server render with `window` undefined | mode is `defaultMode`, `systemDark` is false, no document access occurs |

