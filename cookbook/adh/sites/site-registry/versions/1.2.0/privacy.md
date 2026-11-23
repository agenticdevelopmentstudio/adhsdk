
- **Data collected**: This component reads and returns only site metadata (ids,
  labels, hosts, environment flags, route lists, brand-story classifications) that
  is itself source-controlled configuration, not user data. The persona and registry
  path builders accept a caller-supplied slug (a public handle a registrant chose)
  and percent-encode it into a path; no credential, token, or other secret value is
  read or handled anywhere in this component. The legal URLs are fixed public addresses.
- **Storage**: This component persists nothing at runtime; every value is either a
  constant computed once at load or the result of a pure function with no side
  effect.
- **Transmission**: Not applicable: this component performs no networking of its
  own. The return-origin list's output is consumed by a separate process elsewhere;
  that transmission is outside this component.
- **Retention**: Not applicable: nothing here is retained beyond the lifetime of
  the process that loaded the registry.

