
Vectors AC-001 to AC-003 and AC-006 are derived from `AccountUserTests` and `AccountPresentationAnchorTests` in `AccountsTests.swift`. The others are derived from the declarations in `Account.swift`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| AC-001 | account-user-initials-words | `AccountUser(id: "1", name: "ada lovelace byron", email: "a@b.c", avatarURL: nil).initials` (test `twoWords`) | `"AL"` |
| AC-002 | account-user-initials-email | name `"   "`, email `"zed@b.c"` (test `blankName`) | `"Z"` |
| AC-003 | account-user-initials-placeholder | name `""`, email `""` (test `nothing`) | `"?"` |
| AC-004 | account-user-initials-words | name `"Prince"`, email `"p@x.y"` | `"P"` (a single word gives one letter, no email letter added) |
| AC-005 | account-user-initials-email | name `""`, email `"zed@b.c"` | `"Z"` |
| AC-006 | anchor-weak-reference, anchor-nil-after-release | Build an anchor from an `NSObject`, then release the object (test `weak`) | `anchor.object` is non-nil before release and `nil` after |
| AC-007 | account-state-equatable | `AccountState.signedIn(u1) == AccountState.signedIn(u2)` where `u1` and `u2` have equal fields | `true` |
| AC-008 | account-state-equatable | `AccountState.busy == AccountState.signedOut` | `false` |
| AC-009 | account-on-change-single-slot | Assign `onChange` twice with different closures, then change `state` on a conformer | Only the second closure runs |
| AC-010 | account-restore-idempotent | Call `restore()` twice on a conformer whose stored login is good | One check runs; `state` leaves `.restoring` once |
| AC-011 | account-signup-url | A conformer with `signupURL == nil` | The accounts UI hides Signup |
| AC-012 | no-validation | `AccountUser(id: "", name: "", email: "", avatarURL: nil)` | Construction succeeds with all fields stored as given |

