
- **Relative path.** Input: `rawJSON(path: "billing/context")` (no leading
  `/`). Rejected before any network activity with
  `RawRequestError.invalidPath`. MUST — `raw-path-must-be-absolute`,
  `RawJSONTests.rejectsRelativePath`.
- **Query values containing reserved characters.** Input: a query value
  containing `+`, `&`, `=`, `?`, or `#` (e.g. `"a b"`, or a value that is
  itself a URL). Percent-encoded against `urlQueryAllowed` minus those six
  characters, so they cannot be mistaken for query-string syntax once
  embedded. MUST — `raw-query-sorted-and-percent-encoded`.
- **`path` that already contains a literal `?` plus a non-empty `query`.**
  The two are joined with `&`, never a second `?`. MUST —
  `raw-query-appended-correctly`.
- **Caller-supplied header name the HTTP field grammar rejects** (e.g.
  contains a space or control character). Dropped silently rather than
  thrown — the source's own doc comment states this is deliberate ("a
  transport detail, not a place to crash a sign-in"), since the one real
  caller needing arbitrary headers must not have an unrelated malformed
  header abort the whole request. MUST — `raw-invalid-header-name-dropped`.
- **Caller-supplied `Accept` or `Content-Type` header.** Replaces the
  default of the same name, because caller headers are applied after the
  defaults. MUST — `raw-caller-headers-override-defaults`.
- **No response body on a success status** (e.g. a 204-shaped response).
  `RawResponse.body` is `Data()`, never thrown or left as an optional. MUST
  — `raw-nil-body-yields-empty-data`.
- **Response body at or beyond the 16 MiB cap.** The collection step itself
  throws before the status code is even inspected — a large body on an
  error status never reaches `RawRequestError.http`; the caller instead sees
  whatever error `Data(collecting:upTo:)` throws. MUST —
  `raw-response-body-capped` interacting with `raw-error-status-throws-http`
  (the size check runs strictly before the status check).
- **Duplicate response header names differing only by original casing.**
  Canonicalized and collapsed to the last one `response.headerFields`
  iterates — an earlier value with the same canonical name is discarded
  with no warning. MUST — `raw-response-headers-last-wins`.
- **A `rawJSON` call on a client whose session is an API-token session, or
  whose JWT session has no refresh token.** The refresh decision itself is
  `hub-client-auth`'s (`SessionRefreshMiddleware`'s exemption/no-refresh
  guards); from `ADHClient`'s perspective, `rawJSON` behaves exactly as it
  would for a typed call in the same situation, because both share the one
  `middlewares` array. MUST — `raw-and-typed-share-identical-auth`.
- **Two `ADHClient`s built independently from the same `SessionStore`**
  (e.g. two view models sharing one Keychain-backed session). Both route
  every request, typed or raw, through the identical store reference; the
  process-wide coalescing of a concurrent refresh across the two is
  `hub-client-auth`'s `RefreshCoordinator.shared` contract, not something
  either `ADHClient` instance implements itself. MUST —
  `credential-and-session-storage-delegated`.

