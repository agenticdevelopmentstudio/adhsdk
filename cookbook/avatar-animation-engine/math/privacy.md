
- **Data collected**: None. The four modules operate only on caller-supplied
  hex strings, ease names, transform numbers, and PRNG seeds/arrays — no
  user identity, credential, or device data is read.
- **Storage**: Not applicable — no persistence of any kind occurs in these
  files; a `Prng` instance's state lives only in process memory for its
  lifetime.
- **Transmission**: Not applicable — no network calls exist in this module.
- **Retention**: Not applicable — nothing is retained beyond the calling
  function's or object's lifetime.

