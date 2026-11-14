
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mobile-account-001 | title-from-account, restore-on-load, status-row-text | Account named "Stub Hub" in the restoring state; load the view (test `loading_restoresTheAccount_andShowsTheCheckingRow`) | Restore count is 1; rows are one status row with text "Checking sign-in…"; title is "Stub Hub" |
| mobile-account-002 | row-order, login-row, signup-row, summary-footer | Signed-out account with a signup URL and summary "Sign in to the stub." (test `signedOut_showsLoginAndSignup_withTheSummaryAsFooter`) | Rows are Login then Signup; footer is "Sign in to the stub." |
| mobile-account-003 | user-row, logout-row, no-footer | Account becomes signed in as Ada (test `signedIn_showsTheUserAndLogout`) | Rows are the user row then Logout; footer is absent |
| mobile-account-004 | status-row-spinner, status-row-text, disabled-action-color, highlight-gating | Signed in, then busy (test `busyWhileSignedIn_keepsTheUser_andAddsASpinner`) | Rows are the user row, a status row with no custom text (shown as "Working…"), then Logout; controls are disabled (the test asserts only this); by the source, Logout is not highlightable |
| mobile-account-005 | message-footer | Account message "The hub turned the login down." and signed-out state (test `aMessage_replacesTheFooter`) | Footer is "The hub turned the login down." instead of the summary |
| mobile-account-006 | login-action, signup-action | Call login and signup with an open-URL closure that records its argument (test `login_presentsTheAccountsSignIn_andSignupOpensItsURL`) | Sign-in presentation count is 1; the recorded URL equals the account's signup URL |
| mobile-account-007 | signup-no-url, row-order | Signed-out account whose signup URL is nil | Rows are Login only; calling signup does not invoke the open-URL closure |
| mobile-account-008 | select-gating, highlight-gating | Busy account with no earlier user; select the Login row | No sign-in is presented; the row does not highlight |
| mobile-account-009 | inert-rows | Signed-in account; select the user row | No account action runs and the row is deselected |
| mobile-account-010 | logout-action | Signed-in account; select Logout | The account's sign-out runs; the account moves to signed out and rows become Login and Signup |
| mobile-account-011 | observe-account, no-reload-before-load | Create the controller and change the account state before loading the view | The account's callback is not yet set, so nothing re-renders; loading the view renders the current state once |
| mobile-account-012 | no-coder-init | Create the screen from a decoder | Creation is unavailable at compile time; if forced at run time the process terminates with "init(coder:) is not supported" |

