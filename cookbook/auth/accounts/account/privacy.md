
- **Data collected**: `AccountUser` holds a user `id`, `name`, `email` and an optional avatar URL, which are personal data.
- **Storage**: The types hold the values in memory only; they do not persist them. A conformer's `restore()` may read a stored login, such as from the Keychain, as the doc comment says.
- **Transmission**: The types transmit nothing.
- **Retention**: A value lives as long as its holder; `AccountUser` values are immutable.

