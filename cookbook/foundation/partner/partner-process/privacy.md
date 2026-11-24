
- **Data handled**: The conversation text sent on stdin, the decoded messages from stdout, the stderr text, and the environment the caller passes, which can hold credentials.
- **Storage**: None by this type; the channel keeps stderr text in memory for `standardErrorText()`.
- **Transmission**: Over local pipes to the `claude` process only; what that process sends onward is outside this type.
- **Retention**: In-memory until the actor and channel are released.

