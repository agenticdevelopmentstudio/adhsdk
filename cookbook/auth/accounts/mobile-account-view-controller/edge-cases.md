
- **Empty summary** (MUST): With no message and no shown user, an empty account summary gives no footer, not an empty one.
- **Message with a user** (MUST): A message replaces the footer even while a user is shown.
- **No signup URL** (MUST): Signup is hidden and the signup action does nothing.
- **Busy after signed in** (MUST): The last shown user stays on screen with controls disabled, so signing out does not flash the signed-out rows.
- **Busy from signed out** (MUST): Login and Signup stay visible but disabled.
- **Signed out clears the last user** (MUST): After the account returns to signed out, the previous user is no longer shown.
- **Second observer** (MUST): If another party sets the account's change callback, this screen stops receiving changes; the account holds a single slot.
- **Render before view load** (MUST): Rows are computed but the table is not reloaded until the view loads.
- **Sign-out failure**: The sign-out task discards any result. Any error is only visible through the account's message and state; the screen does nothing else with it.
- **Concurrent access**: The screen is main-actor confined; render, selection handlers and the account's callback all run on the main actor, and the sign-out task starts from the selection handler.
- **Offline or disconnected**: Not applicable: the screen performs no network calls itself; connectivity is the account's concern and reaches the screen only as account state and message.
- **Boundary values**: Not applicable: the screen has no numeric or size inputs; row count is at most three, because the user row never appears with Login or Signup.
- **Weakly held anchor**: The sign-in anchor wraps this screen weakly; if the screen is gone before the account uses it, the anchor holds nothing.

