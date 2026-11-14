
- **Data collected**: None. A channel value can hold arbitrary caller-supplied
  numbers or strings, but nothing in `Channels`, `Scheduler`, or `Tweens`
  treats any value as a credential, token, or personal identifier, collects
  it, or transmits it.
- **Storage**: In-memory only, for the lifetime of the owning `Channels`/
  `Scheduler`/`Tweens` instance; nothing here writes to disk. (`ChannelValue`'s
  `Codable` conformance lets a caller elsewhere serialize a snapshot, but
  serialization and persistence are outside these three files.)
- **Transmission**: None. No network call exists in `Channels.swift`/
  `channels.ts`, `Scheduler.swift`/`scheduler.ts`, or `Tweens.swift`/`tween.ts`.
- **Retention**: For the lifetime of the instance; there is no persistence to
  retain beyond that.

