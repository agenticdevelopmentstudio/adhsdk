
- **Data handled**: The user's alias and real-text pairs; the real text is the sensitive side (a name or word the user keeps from a program or page), and `serialized` writes both sides in clear text.
- **Storage**: None by the component; `Pair` is `Codable` and the text form is a string, and where either is kept is the caller's choice.
- **Transmission**: None; it performs no network access.
- **Retention**: None beyond the lifetime of the value the caller holds.

