
**Decision**: The poll interval is 5 seconds while the body says `refreshing` and 60 seconds otherwise.
**Rationale**: The comment in the source says both routes "answer at once with what the backend has and refresh behind the response, so a client watches them fill in." A fast poll is only worth its cost while something is filling in.
**Approved**: pending

**Decision**: A read in its error state is polled every 60 seconds even when its retained body says `refreshing`.
**Rationale**: The `refetchMs` doc comment: a failed read keeps the last body, and a body taken mid-refresh still says `refreshing`, so judging by the body alone would poll a failing backend every 5 seconds for as long as it fails. Nothing is filling in while the read fails.
**Approved**: pending

**Decision**: The analytics read keeps the previous range's body as placeholder data while a new range loads; the errors read has no placeholder.
**Rationale**: Source comment: "Keep the last chart up while another range loads, instead of flashing skeletons." The errors dashboard has a single key, so there is no previous key to show.
**Approved**: pending

**Decision**: The error message comes from the backend's body when it has one, else `status <code>`.
**Rationale**: `errorMessage` in `api/client.ts` reads both shapes the backend sends (`{ error: { message } }` from its error handler and `{ error: "..." }` from a route). Showing the backend's own words, such as `invalid range`, is more useful than a bare status code.
**Approved**: pending

**Decision**: The `range` is interpolated into the path without encoding or validation.
**Rationale**: The type `AnalyticsRange` allows only `"24h"`, `"7d"` and `"30d"`, none of which needs encoding (a port that accepts a looser type MAY encode), and the source leaves checking any other value to the backend, whose error the read would surface through the non-ok path. This avoids a second copy of the validation, at the cost of a round trip for a bad value.
**Approved**: pending

**Decision**: The `enabled` option exists so the board shell can fetch and poll only the topic that is open.
**Rationale**: `BoardShell.tsx` passes `enabled: topic === "errors"` and `enabled: topic === "analytics"`, so a hidden dashboard costs no requests; the views themselves call the reads with no options because they only mount when their topic is shown.
**Approved**: pending

**Decision**: No retry, staleness, timeout or persistence policy is set in this module.
**Rationale**: The module takes the shared cache's defaults, so one place sets the dashboard's retry and staleness behavior. A port must supply those defaults separately, which Platform Notes call out. A hung request has no ceiling, which is deliberate, prudent debt: it is worth paying down if a dashboard is ever observed stuck fetching, and the intended fix is an abort signal passed through the client's raw request operation (or a client-level timeout) that ends the request and lets the read enter its error state.
**Approved**: pending

