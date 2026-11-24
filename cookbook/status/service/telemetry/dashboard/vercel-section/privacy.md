
- **Data collected**: Aggregate site statistics (page view and visitor counts, country, referrer host, path and device type per project) read from Vercel Web Analytics. No individual visitor is identified.
- **Storage**: In memory, in the sectioned-dashboard cache; the domain cache keeps project domain names for one hour.
- **Transmission**: The API token is sent as a bearer token to `api.vercel.com`; the token is not logged or placed in the returned section.
- **Retention**: Until the next refresh replaces the section; nothing is persisted by this module.

