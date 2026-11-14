
- **Empty or missing storage** (MUST): with no stored value the mode is `defaultMode`; with `defaultMode` omitted it is `auto`.
- **Unrecognised stored value** (MUST): a stored string that is not `light`, `dark` or `auto`, for example an empty string, is ignored and the fallback chain continues to the legacy key and then `defaultMode`.
- **Unreadable storage** (MUST): when `localStorage` throws on read, write or remove (disabled storage, quota, privacy mode), the error is caught and discarded; state and document effects continue and only persistence is lost. See `storage-failure-silent`.
- **Non-auto defaultMode loses the auto choice** (MUST): because `auto` is persisted by removing the key, a provider whose `defaultMode` is `light` or `dark` restores that default on the next load even when the user last chose `auto`.
- **Legacy key resurrects after auto** (MUST): with the default `storageKey`, choosing `auto` removes `adh-sdk:color-mode` but not `agentic-toolkit:color-mode`, so a surviving legacy value is read again on the next load.
- **Server render and hydration** (MUST): on the server the initial mode is `defaultMode` and `systemDark` is false; the client initializer reads real storage and the real media query, so the first client render can differ from the server markup.
- **Cross-tab changes** (not provided): the provider has no `storage` event listener, so a choice made in another tab is not picked up until reload.
- **Both appearance systems mounted** (precondition): the two systems write different keys and attributes and the source does not guard against mounting both, so the document would carry both sets.
- **Unmount** (MUST): listeners are removed, but the `dark` class, `data-appearance-mode` attribute and stored value remain.
- **Concurrent calls** (MUST): `setMode` and `cycle` use React state updates; `cycle` uses the functional updater, so several `cycle()` calls in one batch each advance the mode.
- **Invalid mode through `setMode`** (not validated): an untyped caller can pass any string; it becomes `mode`, `resolved` becomes that string, and it is written to storage and discarded as invalid on the next load.
- **Network and offline**: not applicable; the provider performs no network access.

