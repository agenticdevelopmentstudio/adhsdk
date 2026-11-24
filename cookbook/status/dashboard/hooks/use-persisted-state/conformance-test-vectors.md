
Vectors 001–003 are the assertions in `use-persisted-state.dom.test.tsx` (the third drives it through the source-filter state); the rest are derived from the source. Run in a browser-like environment with clean storage before each case.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| pstate-001 | set-persists, hydrate-decoded, boolean-decoder | test "restores a value set in an earlier mount": mount with key `k`, initial `false`, `decodeBoolean`; set `true`; unmount; mount again with the same arguments | the second mount's value is `true` |
| pstate-002 | hydrate-unrecognised, boolean-decoder | test "keeps the default for a stored value the decoder doesn't recognise": storage holds `"yes"` (JSON string) under `k`; mount with initial `false` and `decodeBoolean` | value stays `false` |
| pstate-003 | set-key-bound, set-persists, hydrate-decoded | test "persists each pane's source filter under its own key": toggle `glitchtip` off through the source filter under key `src-activity`, remount | `src-activity` no longer has `glitchtip` selected, and `src-problems` still has it |
| pstate-004 | hydrate-missing-key, initial-first-render | storage empty; mount with initial `7` | value is `7`, and storage is still empty after mount |
| pstate-005 | hydrate-bad-json | storage holds the text `{oops` under `k`; mount with initial `false` | value is `false`, no exception |
| pstate-006 | hydrate-storage-unavailable | the storage read throws; mount with initial `false` | value is `false`, no exception |
| pstate-007 | set-functional-update | mount with initial `0`; in one batch call the setter with `p => p + 1` twice | value is `2` and storage holds `2` |
| pstate-008 | set-write-failure | the storage write throws; mount with initial `false`; call the setter with `true` | value is `true`, no exception |
| pstate-009 | encode-default, set-persists | mount with initial `false` and no `encode`; set `true` | storage holds the text `true` |
| pstate-010 | set-persists, hydrate-decoded | mount with `encode` mapping a set to an array and a `decode` mapping an array back to a set; set the set `{a, b}`; remount | storage holds `["a","b"]` and the second mount's value is a set containing `a` and `b` |
| pstate-011 | boolean-decoder | `decodeBoolean` called with `true`, `false`, `"true"`, `1`, `null` | `true`, `false`, `undefined`, `undefined`, `undefined` |
| pstate-012 | key-change-rehydrates, key-change-keeps-value | mount with key `a` and value set to `true`; re-render with key `b` that has no stored entry | value is `true` in the source, which keeps the old key's value (a port MAY reset instead); with a stored `false` under `b` it becomes `false` |
| pstate-013 | decode-read-once | mount with an inline `decode`; re-render several times with a new inline `decode` and the same `key` | storage is read once and the value is unchanged by the re-renders |
| pstate-014 | hydrate-decode-throws | `decode` throws on the stored value; mount | value stays at `initial`, no exception |
| pstate-015 | set-persists-same-value | mount with initial `false`; storage is cleared; call the setter with `false` | storage holds the text `false` after the call, even though the value did not change |
| pstate-016 | set-encode-captured | mount with an inline `encode` that wraps the value in an array; re-render with the same `key` and an `encode` that wraps it in an object; call the setter with `1` | storage holds the text `[1]`, from the `encode` of the render that created the setter |
| pstate-017 | set-key-bound | mount with key `a`; capture the setter; re-render with key `a`, then with key `b`; call the captured setter and the current setter | the setter's identity is the same across the re-render with key `a` and different after the change to `b`; the captured setter writes to `a` |
| pstate-018 | set-updater-throws | mount with initial `0`; call the setter with an updater that throws | the exception is not caught by the state, no write happens for that call (the throw unmounts the hook's tree, so there is no value left to read) |
| pstate-019 | hydrate-once-per-key | mount with key `k`, re-render three times with the same key, then change the key to `j` | storage is read once for `k` and once more for `j`, and not on the re-renders |
| pstate-020 | hydrate-no-write | storage holds `true` under `k`; mount with `decodeBoolean` and initial `false` | the value becomes `true`, and no write call is made to storage during hydration |
| pstate-021 | per-instance-state | two mounts with the same key; call one setter with `true` | the other mount's value stays `false`; storage holds `true` |
| pstate-022 | no-cross-tab-sync | mount with key `k`; dispatch a storage change event for `k` with a new value | the value does not change |
