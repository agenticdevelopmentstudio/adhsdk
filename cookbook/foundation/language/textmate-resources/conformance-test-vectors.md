
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| textmate-resources-001 | check-mode | `--check` against a missing or stale `--out` | exit 1, the differing paths listed. |
| textmate-resources-002 | check-mode, deterministic-output | `--check` right after a build into `--out` | exit 0, `up to date`. |
| textmate-resources-003 | licence-filter | `tm-grammars` 1.32.22, `tm-themes` 1.12.12 | 218 grammars kept, 42 dropped (none, NOASSERTION, GPL-3.0, GNU, MPL-2.0); 64 themes kept, `aurora-x` (GPL-3.0) dropped. |
| textmate-resources-004 | bundle-api, highlight-output | the README's `node -e` smoke test on Swift with Dark+ | `let` at `[0, 3]` coloured `#569CD6`, every line has runs. |
| textmate-resources-005 | bundle-api | the same bundle and `onig.wasm` in a bare `JSContext` without the JIT entitlement | Swift text highlights with non-empty colour runs. |

