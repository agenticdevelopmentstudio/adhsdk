
- **Data collected**: A service's name, provider kind, base URL and API key, and the per-model
  switches.
- **Storage**: Server side. The API key is sent on create and on save only when typed and is never
  read back: the row carries only whether a key exists, and the field shows a masked placeholder. The
  client keeps the list in an in-memory cache; the draft key lives in component state only.
- **Transmission**: To the hub API over the data client; the API key input is a password field.
- **Retention**: Not determinable from source: retention is a backend matter.

