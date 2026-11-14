
Vectors 001 to 005 are the cases asserted in `AccountRegistryTests` (`AccountsTests.swift`, suite "AccountRegistry"); the rest follow the source directly.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| account-registry-001 | accounts-order, init-silent | `AccountRegistry(accounts: [a, b])`, ids "a" and "b" (test "keeps accounts in the order given") | `accounts.map(\.id)` is `["a", "b"]` |
| account-registry-002 | add-appends, add-notifies, init-default-empty | Empty registry with a counting `onChange`; `add` account "a" (test "add appends and reports a change") | `accounts.map(\.id)` is `["a"]`; the count is 1 |
| account-registry-003 | add-idempotent, add-duplicate-silent | Registry holding "a"; counting `onChange`; `add` a second account with id "a" (test "add ignores an id already present and reports nothing") | `accounts.count` is 1; the count is 0 |
| account-registry-004 | remove-by-id, remove-notifies | Registry holding "a", "b"; counting `onChange`; `remove(id: "a")` (test "remove drops the account and reports a change") | `accounts.map(\.id)` is `["b"]`; the count is 1 |
| account-registry-005 | remove-unknown-noop | Registry holding "a"; counting `onChange`; `remove(id: "zzz")` (test "remove of an unknown id is a silent no-op") | `accounts.count` is 1; the count is 0 |
| account-registry-006 | add-idempotent | Registry holding object X with id "a"; `add` a different object Y with id "a" | `accounts` still holds X only |
| account-registry-007 | identity-by-id, add-appends | Registry holding "a"; `add` "b" then `add` "a" again | `accounts.map(\.id)` is `["a", "b"]`; `onChange` fired once |
| account-registry-008 | init-stores-as-given | `AccountRegistry(accounts: [a1, a2])` where both have id "a" | `accounts.count` is 2; `onChange` not called |
| account-registry-009 | remove-by-id | Initializer given two accounts with id "a" then `remove(id: "a")` | Only the first is removed; `accounts.count` is 1 |
| account-registry-010 | remove-no-teardown | Registry holding a stub that records `signOut()` calls; `remove` its id | The stub records zero `signOut()` calls |
| account-registry-011 | on-change-synchronous | `onChange` records `accounts.count`; `add` account "a" to an empty registry | The recorded count is 1 |
| account-registry-012 | on-change-slot | Assign closure A, then closure B; `add` a new account | Only B runs |
| account-registry-013 | on-change-scope | Registry holding account "a"; the account's own `onChange` fires (state change) | The registry's `onChange` is not called |

