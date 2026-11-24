
- **Null / empty input**: An empty `token` is not rejected; `directory` is built from the component `.` followed by `partner`, so the result is `/h/./partner` for a home of `/h` (URL path joining keeps the `.` component). An empty `jobID` gives the directory name `adkitchen-partner-`. The type does not guard either (MUST NOT validate, per no-validation).
- **Boundary values**: A `token` or `jobID` that contains a path separator or `..` is joined as written and can place the result outside the intended directory. The type neither detects nor refuses it; the caller owns the check, and `skillFile(jobID:)` takes a raw string, so nothing in the type stops a separator in the job ID from adding path levels.
- **Concurrent access**: The type is an immutable value; copies are safe to read from any thread or actor (it is `Sendable`).
- **Error states**: Nothing can fail; no property or function throws or returns an optional.
- **Offline / disconnected state**: Not applicable: the type performs no network or file access.
- **Cancellation**: Not applicable: every member is a synchronous computation with no suspension point.

