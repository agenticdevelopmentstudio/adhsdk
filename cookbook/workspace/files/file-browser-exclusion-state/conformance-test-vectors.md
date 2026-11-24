
The source has no tests beside it, and a search of the package's tests finds
none that construct this type; the vectors below are derived from the
assertions the source itself makes.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| exclusion-001 | default-hides-excluded | Construct with no argument | `hidesExcludedContent` is `true` |
| exclusion-002 | init-stores-given-value, init-does-not-notify | Assign `onChange` after constructing with `hidesExcludedContent: false` | `hidesExcludedContent` is `false`; the callback was never called |
| exclusion-003 | on-change-nil-by-default, nil-callback-is-noop | Construct, read `onChange`, then set `hidesExcludedContent = false` | `onChange` was `nil`; value is now `false`; no failure |
| exclusion-004 | change-notifies-owner, notify-after-store | `onChange` records `(arg, state.hidesExcludedContent)`; set `hidesExcludedContent = false` from `true` | One call recorded, `(false, false)` |
| exclusion-005 | same-value-is-silent | State is `true`; set `hidesExcludedContent = true` | `onChange` is not called |
| exclusion-006 | change-notifies-owner | Set `false`, then `true` | Two calls, in order `false` then `true` |
| exclusion-007 | publishes-for-observers, publisher-fires-for-equal-values | Subscribe to `$hidesExcludedContent`, drop the first value, set `true` while already `true` | The subscriber receives one value; `onChange` is not called |
| exclusion-008 | publisher-fires-before-store | Subscriber reads `hidesExcludedContent` synchronously inside its sink while the value changes from `true` to `false` | The read returns `true` (the old value) |
| exclusion-009 | shared-by-reference | Two holders keep one instance; one holder sets `false` | The other holder reads `false` |
| exclusion-010 | callback-replaceable | Set `onChange` to closure A, change the value, replace it with closure B, change it again | A is called once for the first change, B once for the second |
| exclusion-011 | main-actor-isolated, notify-is-synchronous | Change the value from a main-actor test | `onChange` has already run when the assignment statement returns |
| exclusion-012 | no-persistence-here | Change the value with no `onChange` set, then construct a fresh instance | The fresh instance is `true`; nothing was stored |

