
**Decision**: The status sentence is available as a static function of explicit values as well as an instance property.
**Rationale**: The source comment explains that the panel renders from the value a `@Published` property publishes, and that value arrives before the property itself changes, so an observer reading `self` would see stale values. The static function lets the observer compute the sentence from the published value. A port whose change event fires after the set does not need the split.
**Approved**: pending

**Decision**: `failureReason` takes precedence over every other value in the status sentence, but `url` ignores it.
**Rationale**: The sentence has to say the endpoint is not running when it failed, whatever a stale port says. `url` is defined only by `port`; the host is expected to leave `port` nil on failure, per the `port` comment "nil until started, or when it failed".
**Approved**: pending

**Decision**: The model holds values and derives text; it does not start the endpoint, read the Claude Code config or validate anything.
**Rationale**: Per the doc comment the host's automation feature fills it and the panel reads it. Keeping it passive lets the panel be tested with any combination of values, as `AutomationSettingsPanelTests` does.
**Approved**: pending

**Decision**: The model is `@MainActor` and publishes the bearer token as a plain `String?`.
**Rationale**: The panel is main-thread UI, so isolating the model there avoids locking. The token is published only so the panel can build the registration command; the model adds no protection for it, so where it is persisted and who can read it is decided by the host feature and the instance's holders.
**Approved**: pending

