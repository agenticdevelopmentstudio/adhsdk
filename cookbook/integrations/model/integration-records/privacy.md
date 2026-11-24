
- **Data collected**: the records hold a user's mail data (`fromAddress`, `toAddresses`, `ccAddresses`, `subject`, `snippet`, `bodyText`, `bodyHtml`, attachment names), the connected account (`externalAccountId`, `displayName`), the granted `scopes`, and the OAuth `clientId` on `ProviderConfig`.
- **Storage**: the records define the columns only; they hold no tokens or secrets, and the database file and its protection belong to the store.
- **Transmission**: the records do not transmit anything.
- **Retention**: `deletedAt` and `isDeleted` mark soft deletion on the rows that carry them; `ActionLog` has no deletion marker. When rows are purged is decided by the store.

