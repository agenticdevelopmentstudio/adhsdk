
- **Data collected**: The bytes of a terminal stream (keystrokes and program output), which can include secrets, and the privacy words in the filter.
- **Storage**: In memory only: the patterns and the held bytes of the current instance; nothing is persisted.
- **Transmission**: None; the type performs no network access. Its output goes to the caller.
- **Retention**: Held bytes live until the next `feed` or `flush`; the patterns live as long as the instance.
- **Purpose**: Concealing real words in output and revealing aliases in input, so a half-matched word is never emitted before its other half arrives.

