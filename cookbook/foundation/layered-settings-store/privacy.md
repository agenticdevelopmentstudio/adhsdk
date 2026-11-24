
- **Data collected**: None by this code; it carries whatever values the caller stores, including secure values.
- **Storage**: Non-secure values live in the injected overrides provider. Secure values are never copied into the overrides: they live only in the fallback store's secure provider.
- **Transmission**: None; the store performs no network access.
- **Retention**: Overrides last as long as the overrides provider keeps them; the store deletes none on its own.

