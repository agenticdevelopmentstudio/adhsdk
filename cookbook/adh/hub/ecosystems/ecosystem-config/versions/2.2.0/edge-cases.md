
- **Path deeper than one segment**: sign-in apps, feature flags, server bags, and
  storage tokens MUST return an empty result for any path longer than one segment;
  user auth MUST return an empty result for any non-empty path at all (it has no
  detail-lookup segment to descend into).
- **Unmatched id/key at depth one**: a path segment id matching no existing entity
  MUST return an empty result for all four list-based topics.
- **Malformed JSON in a server bag's value field**: the value-parsing step MUST
  discard the specific decode-error text and surface only the fixed invalid-JSON
  message, on both create and detail save.
- **Server-side duplicate after client pre-check passes**: a conflict error from
  create for flags, bags, or sign-in apps MUST be caught and re-thrown with the same
  friendly message the client-side pre-check uses, so the user sees identical
  wording regardless of which check caught the duplicate.
- **Case-insensitive sign-in-app leaf collision**: a new leaf that differs only in
  case from an existing one (e.g. "kiosk" vs. an existing "Kiosk") MUST be rejected
  by **signinapps-duplicate-leaf-check**, even though the raw strings are not equal.
- **Origin with credentials, a path, or a non-http(s) scheme**: each MUST be
  rejected by the origin-validation step with its own specific message and MUST NOT
  reach the network.
- **Re-rendering the detail currently showing a revealed secret**: MUST NOT drop the
  secret - the secret-expiry check's same-detail guard leaves it untouched; only
  navigating to a *different* destination drops it.
- **A value outside the shared error taxonomy thrown during storage-token create**:
  MUST be converted to a generic unexpected error reading "Couldn't create the
  token. Please try again.", discarding the original error's own message text - a deliberate divergence from the shared
  error-wrapping step's usual behavior of preserving as much detail as possible (see
  Design Decisions).
- **A feature-flag key containing a reserved character (e.g. `:`)**: see
  **flags-key-charset-unrestricted** - it SHOULD be rejected, but no given
  implementation rejects it yet, and it is later embedded unescaped in a
  colon-delimited composite id.
- **Path segments containing special characters**: the alternate client's
  path-encoding step MUST percent-encode every ecosystem id, flag key, bag key, and
  sign-in-app id interpolated into a request path, so a key/id with `/`, `?`, or
  similar cannot corrupt the request path even though no character-set validation
  rejects such a key upstream.
- **The create body's own ecosystem-id field left unset while a scope parameter is
  also given**: neither implementation reconciles the two channels;
  **dual-scoping-channels** documents that the rail always leaves the body field
  unset and relies on the parameter/query channel exclusively.

- **Turning "Only listed people" on with an empty sign-up list**: the save sends
  the sign-up list's own emails, an empty list, which means nobody may sign in. The
  backend keeps the sign-up entries equal to the list written, so the form MUST
  never send an empty draft list of its own that would erase every entry.
- **A sign-up list entry for an email already listed**: adding it changes its role
  and set rather than adding a second row; removing an entry never takes back a
  role or set it already granted.
- **A set edit the backend refuses**: the pane shows the refusal's rule, limits and
  affected sets in its own words.
- **A workspace that cannot be resolved**: every pane reads a missing ecosystem id
  as an empty ecosystem, so the gate MUST NOT let a failed resolution fall through
  to a pane that would then show "no server bags" for an ecosystem it never found.
- **A follower turned on while its parent is off**: the sync-tables write succeeds
  and the row comes back `overridden` but not `enabled`. The pane shows the server's
  answer rather than the requested state.
- **Switching ecosystems with rows selected**: the admin console clears the
  selection with the ecosystem, because resource ids are the same in every
  ecosystem and a kept selection would write to one the user has not looked at.

