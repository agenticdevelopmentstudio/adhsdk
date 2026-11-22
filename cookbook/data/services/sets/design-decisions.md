
**Decision**: Writes convert a 422 `set_refused` into a typed `SetRefusedError` carrying the rule, limits, containers and holder count, and leave every other error untouched.
**Rationale**: The file header says it exists "so a pane can say which rule and which limits". Rethrowing every other error unchanged keeps the transport's 401, 403 and 5xx handling in one place.
**Approved**: pending

**Decision**: `asSetRefusedError` identifies the error by duck-typing on `.status` and `.body` through `httpStatus`, not by `instanceof`.
**Rationale**: The doc comment says a host's own auth error class is read the same; two `AuthHttpError` classes can coexist when a host layers its own client over this package.
**Approved**: pending

**Decision**: Request bodies send only the fields given (`undefined` is dropped, `null` and empty values are kept), except that `personalCustomerId` is sent only when truthy.
**Rationale**: Edit is a true partial: "what is left out stays as it is" (`SetPatch` doc comment). A personal set's customer is "fixed once made" (`SetInput`), so an empty or null value is never worth sending.
**Approved**: pending

**Decision**: Containment and values are replaced wholesale on their own routes, not patched through `edit`.
**Rationale**: The doc comments say "Replace the sets it contains" and "Replace its permissions and limits", and the backend checks rules 3, 6 and 8 against the whole list at once. `SetPatch` is limited to `slug`, `name`, `description` and `isDefault`.
**Approved**: pending

**Decision**: Edit is a POST rather than a PUT or PATCH.
**Rationale**: The route table in the file header lists "edit (POST)", and the test asserts the method; the backend defines the verb, and a port must match it.
**Approved**: pending

**Decision**: The client does not validate set values, containment, rule numbers or ids before sending.
**Rationale**: The backend's resolver owns the rules (3, 4, 6, 8, 9) and refuses a bad write with a named rule; duplicating them on the client would drift. The cost is a round trip for an invalid write.
**Approved**: pending

**Decision**: `toSetsAnswer` reads `null` or `undefined` as `null` and `{ error: "unresolved" }` as its own case, and `isEffectiveSets` is the type guard that separates the three.
**Rationale**: The doc comment says absence means "an older backend, or a realm where sets do not apply", and `UnresolvedSets` means the backend could not compute the answer; callers must tell "no sets" from "could not compute".
**Approved**: pending

**Decision**: `validUntil` is omitted from the mapped answer when the wire key is absent, and kept as `null` when the wire value is `null`.
**Rationale**: `EffectiveSets.validUntil` is "absent on `/auth/me`"; the conditional spread preserves that absence, so a consumer can tell "not reported" from "never changes".
**Approved**: pending

**Decision**: `revoke` does not use the `write` wrapper that converts refusals.
**Rationale**: The call goes straight to `authedRequest`. The backend's revoke route never answers a 422 `set_refused`, so there is nothing to convert, and the header's "every write here" covers the writes that can be refused.
**Approved**: pending

**Decision**: `grants` returns the backend's order and `list` sorts by name on the client with `localeCompare`.
**Rationale**: The doc comment says grants arrive "newest first" from the backend, while sets have no stated order and the pane wants them by name. `localeCompare` is locale-dependent, so two machines may order accented names differently.
**Approved**: pending

