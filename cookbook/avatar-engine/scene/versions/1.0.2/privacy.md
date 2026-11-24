
- **Data collected**: None. Scene construction, `compose`, and
  `crop`/`cropList` operate only on already-authored character-configuration
  data (node ids, colours, shapes) and animation channel values; no user
  data passes through either file.
- **Storage**: Not applicable — neither file persists anything; a `Scene`
  and the `DisplayList` it produces are in-memory-only values.
- **Transmission**: Not applicable — neither file performs network I/O.
- **Retention**: Not applicable — nothing is retained beyond the caller's
  own references to the returned values.

