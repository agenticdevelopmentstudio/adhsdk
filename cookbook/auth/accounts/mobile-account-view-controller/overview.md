
MobileAccountViewController is the iOS twin of the macOS account detail panel. It shows one account's sign-in as a single-section inset-grouped table. While signed in it shows who is signed in and a Logout row. While signed out it shows a Login row and, when the account has a signup URL, a Signup row. While the stored login is being checked, or the account is busy, it shows a spinner row.

What is visible comes from `AccountDisplay`, the platform-free rules shared with the macOS panel. The controller keeps no copy of the account's state beyond the last `AccountDisplay` and the rows derived from it. It is the account's one observer and asks the account to restore its stored login when the view first loads.

