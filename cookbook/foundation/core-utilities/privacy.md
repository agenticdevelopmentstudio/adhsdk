
The secret store is the one utility in this ingredient that handles sensitive
data; the other five collect, store, and transmit nothing.

- **Data handled**: the secret string values a caller passes to `set` —
  arbitrary caller-supplied text such as an API key or credential. The
  store never inspects, parses, or transforms the value itself.
- **Storage**: the system's credential store, scoped by `service` and
  optionally `accessGroup`. An item written while an access group is set or
  `usesDataProtectionKeychain` is true is additionally marked accessible
  only after the device's first unlock, and never synced off-device. An
  item written with neither is stored with the credential store's default
  accessibility class.
- **Transmission**: none. The store performs no networking; a caller that
  later transmits a retrieved secret does so outside this component's
  boundary.
- **Retention**: indefinite. A stored item persists until a caller calls
  `delete` or the OS/user removes it independently — the store defines no
  TTL or automatic expiry (see `keychain-secret-lifetime-caller-controlled`
  above).

