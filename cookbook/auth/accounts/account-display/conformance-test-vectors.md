
Vectors 001 to 007 mirror the tests in `AccountDisplayTests` (`restoring_showsTheStatusLineAndSpinner_andNoButtons`, `signedOut_showsLoginAndSignup_onlyWithASignupURL`, `signedIn_showsTheUserAndLogout`, `busyAfterSignedIn_keepsShowingTheUser_withControlsDisabled`, `busyFromSignedOut_keepsTheSignedOutControls`, `signedOut_forgetsTheLastUser`). Vectors 008 to 014 are derived from the initializer and are not asserted by those tests. `U` is a user such as id `u1`, name `Ada Lovelace`.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| account-display-001 | status-text, spinner, no-controls-while-restoring, shown-user-otherwise | state `.restoring`, message `nil`, hasSignupURL true, lastUser `nil` (test: `restoring_showsTheStatusLineAndSpinner_andNoButtons`) | showsStatusText true, showsSpinner true, showsLogin/showsSignup/showsLogout false, shownUser `nil`. |
| account-display-002 | login-visibility, signup-visibility, logout-visibility | state `.signedOut`, hasSignupURL true, lastUser `nil` (test: `signedOut_showsLoginAndSignup_onlyWithASignupURL`) | showsLogin true, showsSignup true, showsLogout false. |
| account-display-003 | signup-visibility | state `.signedOut`, hasSignupURL false, lastUser `nil` (same test) | showsLogin true, showsSignup false. |
| account-display-004 | shown-user-signed-in, logout-visibility, controls-enabled, spinner | state `.signedIn(U)`, hasSignupURL true, lastUser `nil` (test: `signedIn_showsTheUserAndLogout`) | shownUser `U`, showsLogout true, showsLogin false, showsSignup false, showsSpinner false, controlsEnabled true. |
| account-display-005 | shown-user-busy, controls-enabled, spinner, status-text | state `.busy`, hasSignupURL true, lastUser `U` (test: `busyAfterSignedIn_keepsShowingTheUser_withControlsDisabled`) | shownUser `U`, showsLogout true, showsLogin false, showsSpinner true, showsStatusText false, controlsEnabled false. |
| account-display-006 | login-visibility, signup-visibility, controls-enabled | state `.busy`, hasSignupURL true, lastUser `nil` (test: `busyFromSignedOut_keepsTheSignedOutControls`) | shownUser `nil`, showsLogin true, showsSignup true, showsLogout false, controlsEnabled false. |
| account-display-007 | shown-user-otherwise, message-passthrough | state `.signedOut`, message `Signed out`, hasSignupURL false, lastUser `U` (test: `signedOut_forgetsTheLastUser`) | shownUser `nil`, message `Signed out`. |
| account-display-008 | shown-user-signed-in | state `.signedIn(U)`, lastUser a different user `V` | shownUser `U`, not `V`. |
| account-display-009 | shown-user-otherwise, no-controls-while-restoring | state `.restoring`, lastUser `U` | shownUser `nil`, showsLogout false. |
| account-display-010 | enabled-is-independent-of-visibility | state `.restoring` | controlsEnabled true while every button is hidden. |
| account-display-011 | restoring-text | read `AccountDisplay.restoringText` | `Checking sign-in…`. |
| account-display-012 | message-passthrough | state `.signedIn(U)`, message `nil`, then message `` (empty) | message `nil` in the first, empty string in the second (not coerced to `nil`). |
| account-display-013 | account-initializer | a main-actor account whose state is `.signedOut`, message `Try again`, signupURL non-nil, with lastUser `nil` | Equal to the state initializer called with `.signedOut`, `Try again`, hasSignupURL true, `nil`. |
| account-display-014 | account-initializer | the same account with signupURL `nil` | showsSignup false. |

