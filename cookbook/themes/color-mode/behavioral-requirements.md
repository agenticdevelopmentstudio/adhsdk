
### Types and exports

- **color-mode-type**: `ColorMode` MUST be exactly one of `auto`, `light` or `dark`.
- **resolved-color-mode-type**: `ResolvedColorMode` MUST be exactly one of `light` or `dark`, never `auto`.
- **context-value-shape**: The value returned by `useColorMode` MUST carry `mode` (a `ColorMode`), `resolved` (a `ResolvedColorMode`), `setMode(mode)` and `cycle()`.
- **provider-props**: `ColorModeProvider` MUST accept `children`, an optional `storageKey` and an optional `defaultMode`.
- **client-only-module**: The module MUST be marked `'use client'`, so a server-component framework treats it as client code.

### Initial mode

- **initial-mode-from-storage**: On first render the provider MUST use the value stored under `storageKey` when it is exactly `light`, `dark` or `auto`.
- **initial-mode-from-legacy-key**: When `storageKey` equals the default `adh-sdk:color-mode` and nothing valid is stored under it, the provider MUST read the pre-rename key `agentic-toolkit:color-mode` and use its value when valid.
- **legacy-key-only-for-default**: The provider MUST NOT read `agentic-toolkit:color-mode` when a custom `storageKey` is supplied.
- **initial-mode-default**: When no valid stored value is found, the provider MUST use `defaultMode`, which defaults to `auto`.
- **invalid-stored-value-ignored**: A stored value other than `light`, `dark` or `auto` MUST be treated as absent.
- **no-window-initial-mode**: When `window` is undefined (server render), the stored-value read MUST return nothing, so the initial mode is `defaultMode`.

### Resolution

- **resolve-explicit-mode**: When `mode` is `light` or `dark`, `resolved` MUST equal `mode`.
- **resolve-auto-from-system**: When `mode` is `auto`, `resolved` MUST be `dark` if the media query `(prefers-color-scheme: dark)` matches and `light` otherwise.
- **system-dark-initial**: The provider MUST read the media query once during the first render, and MUST treat the system as not dark when `window` is undefined.
- **system-change-listener**: The provider MUST subscribe to `change` events on the `(prefers-color-scheme: dark)` media query after mount and update `resolved` when `mode` is `auto`.
- **system-listener-cleanup**: The provider MUST remove its media query listener on unmount.

### Document effects

- **dark-class**: The provider MUST add the class `dark` to `document.documentElement` when `resolved` is `dark` and remove it when `resolved` is `light`.
- **appearance-mode-attribute**: The provider MUST set `data-appearance-mode` on `document.documentElement` to the current `mode` (`auto`, `light` or `dark`), not to the resolved value.
- **no-attribute-removal**: The provider MUST NOT remove the `dark` class or `data-appearance-mode` attribute when it unmounts; the source has no cleanup for them.
- **changed-event**: After each change of `mode` or `resolved`, including the first effect run on mount, the provider MUST dispatch a `CustomEvent` named `awt:appearance-changed` on `window`.
- **no-document-effects**: When `document` is undefined the provider MUST skip the class and attribute writes, and when `window` is undefined it MUST skip the event dispatch.

### Persistence

- **persist-explicit-mode**: When `mode` is `light` or `dark`, the provider MUST write it to `localStorage` under `storageKey`.
- **persist-auto-removes**: When `mode` is `auto`, the provider MUST remove `storageKey` from `localStorage` rather than write `auto`.
- **persist-on-first-render**: The persistence effect runs on mount as well as on change, so a mode chosen from the default or the legacy key MUST be written (or removed) under `storageKey` immediately after the first render.
- **legacy-key-not-cleaned**: The provider MUST NOT write to or remove `agentic-toolkit:color-mode`; the legacy key is read only.
- **storage-failure-silent**: A throwing `localStorage` read, write or remove MUST be caught and ignored (the source marks each catch `/* ignore */`), with no log or other signal; the choice then fails to persist while state and document effects continue.

### Operations

- **set-mode**: `setMode(mode)` MUST replace the current mode with the given `ColorMode`; the source performs no validation of the argument beyond its TypeScript type.
- **cycle-order**: `cycle()` MUST advance the mode through the fixed order `auto`, `dark`, `light`, then back to `auto`.
- **cycle-fallback**: When the current mode is not found in the cycle order, `cycle()` MUST fall back to `auto`.
- **cycle-event**: The provider MUST listen on `window` for an event named `awt:appearance-cycle` and call `cycle()` for each one received, after mount.
- **cycle-event-cleanup**: The provider MUST remove the `awt:appearance-cycle` listener on unmount.
- **stable-callbacks**: `cycle` MUST keep a stable identity across renders, and the context value MUST be memoized on `mode`, `resolved` and `cycle`.

### Consumption

- **hook-requires-provider**: `useColorMode` MUST throw an `Error` with the message `useColorMode must be used within a <ColorModeProvider>` when called outside a provider.
- **single-appearance-system**: A document MUST NOT mount both this provider and the newer appearance system, which uses `adh:appearance` and `data-color-mode`; the source documents this as a caller precondition and does not detect a violation.

### Ordering and concurrency

Not applicable: the provider is a React client component whose state changes run on the single JavaScript thread; effects for one `mode` or `resolved` change run in declaration order (document writes, then persistence), and no operation is asynchronous.

