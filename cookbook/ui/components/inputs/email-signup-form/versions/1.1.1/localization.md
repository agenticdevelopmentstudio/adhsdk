
Not fully externalized. `title`, `description`, `buttonLabel`, and `successMessage` are overridable via props, so a consuming app can localize those four strings. Every other user-facing string is a hardcoded English literal with no override mechanism: "Loading…", "Enter a valid email address.", "Something went wrong. Please try again.", "Signups are unavailable right now.", "Try again", "Email address", "Name", "Signing up…", and the footer disclosure "We'll only email you about this. Unsubscribe any time." See Compliance (`string-externalization`, `no-hardcoded-strings`).

