
- **Data handled**: Configuration ids only (random UUIDs); no name, value or secret is stored.
- **Storage**: `UserDefaults`, in plain text, under the ledger key.
- **Transmission**: None; the ledger sends nothing.
- **Retention**: An id stays until a recorded push lists it in `removedConfigIds`; nothing expires it.

