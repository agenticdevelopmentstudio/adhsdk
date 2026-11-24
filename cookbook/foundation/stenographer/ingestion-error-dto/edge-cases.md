
- **Never retried**: `retryCount` is 0 and `lastRetriedAt` is nil; the shape MUST carry both.
- **Placeholder reason**: a file quarantined before reason capture has a placeholder `reason`; the daemon writes `unknown (quarantined before reason capture)`.
- **Empty drop file**: see `#requirements/log-status-lost`.
- **Unknown status**: a `status` outside the five values still decodes, since the type is a String; see `#requirements/unknown-status`.
- **Empty batch**: Retry All over an empty errors directory sets `total` 0; `running` is true only until the batch finishes, then false with every count at 0.
- **Counts out of step**: `recovered` plus `stillFailing` may not equal `processed`, mid-batch or after it, because a file that vanished is processed but neither recovered nor failing; nothing here enforces the sum.
- **Batch already running**: starting Retry All while a manual or periodic batch runs starts nothing and returns the live progress; a periodic batch that finds a manual one running does nothing.
- **Re-quarantined filename**: a filename recorded as `recovered` or `cleared` and then failing again takes the new quarantine time and a nil `resolvedAt`.
- **Concurrent access**: all three are immutable `Sendable` values; a progress value is a snapshot, so a poll reads whatever the batch had reached.
- **Error and offline states**: no I/O here; a timed-out caller is what the async batch avoids, and an unreachable daemon is the client's failure.

