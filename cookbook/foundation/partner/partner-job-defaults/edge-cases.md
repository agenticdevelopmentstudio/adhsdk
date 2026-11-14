
- **Fresh install, no jobs stored**: The controller seeds each job in `all` that the store lacks (see the controller's `jobs()`); the seeded code-reviews job starts disabled (MUST).
- **Store read fails**: The controller falls back to `all` and logs the failure; the defaults are therefore always available without storage (MUST be pure, per pure-constants).
- **Retired job left behind**: An install that once had the general job keeps its row, file and skill until the coordinator calls the installer's removal with `retiredGeneralID`; `all` never re-creates it (MUST).
- **Reset to default**: Replacing a job's steps or guidelines with `codeReviews()` values restores the original text exactly, because the values are reproducible (MUST).
- **Placeholders left unfilled**: These constants hold placeholders unresolved. `PartnerStepTemplate.fill` leaves an unknown placeholder as written, so a value the review service does not supply is typed literally.
- **Empty reviewer model and no superseding commits**: `ReviewService.fill` drops the `--model {model}` option from every step when the reviewer-model setting is empty, so the terminal step then reads `claude --dangerously-skip-permissions`; and `{superseded}` is filled with `none` when no later commit touched the files (a fact of the review service, not of this type).
- **Command placeholders vs terminal quoting**: Values filled into the terminal step are shell-quoted and values filled into Claude steps are not (a fact of `PartnerStepTemplate`, not of this type).
- **Concurrent access**: Not applicable — every member is a constant or builds a new value, so there is nothing shared to race on.
- **Network, timeouts, offline, boundary values**: Not applicable — the namespace performs no I/O; the 1800-second interval is the one numeric default.

