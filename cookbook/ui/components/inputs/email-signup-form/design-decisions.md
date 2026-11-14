
**10-Second Config Timeout**
**Decision**: A hung config request becomes a retriable `unavailable` state after 10 seconds, instead of leaving the form on "Loading…" forever.
**Rationale**: A hung request would otherwise keep the form on "Loading…" forever, taking up real estate on the visitor's page with no affordance to recover. 10 seconds is generous enough for slow mobile connections but short enough that nobody stares at a spinner for a minute.
**Approved**: pending

**Nonce Age Enforcement at Client**
**Decision**: The client waits out any remaining nonce-age floor (`minAgeMs`) before submitting, measured as a duration from when the nonce was received, plus a 250ms buffer.
**Rationale**: The server requires a minimum age for the nonce to prevent rapid-fire bot submissions. Measuring the age as a duration from client receive time (not a server timestamp comparison) makes the wait immune to clock skew; a visitor whose clock is off still measures real elapsed time. The 250ms buffer accounts for `setTimeout`'s lower-bound rounding and other timing noise, not for clock differences.
**Approved**: pending

**Generic Server Errors**
**Decision**: The component does not expose server error reasons (e.g., "invalid submission", "rate limit") to the visitor.
**Rationale**: Those reasons describe the anti-abuse gate, and leaking which defense tripped is an attack surface. Visitors see only "Something went wrong." A submission failure is not logged to the console (only config-load and nonce-refresh failures are), so the generic message is the only record on the client.
**Approved**: pending

**Silent Config Refresh on Submission Error**
**Decision**: A failed submission does not surface a second error to the visitor; instead, it silently refreshes the nonce.
**Rationale**: If the refresh itself fails, the visitor still has the form, and retrying (with a stale nonce) is still better than showing a dead end. This trades silent nonce staleness for a form that remains usable.
**Approved**: pending

**Honeypot and Nonce Aging over CAPTCHA**
**Decision**: The component uses a honeypot (a form field invisible to humans) plus nonce aging rather than a CAPTCHA or similar challenge.
**Rationale**: A challenge such as a CAPTCHA adds friction and a third-party dependency to an embeddable form. The honeypot catches content-filling bots, and the client-side nonce-age wait defeats rapid-fire submissions; the server separately enforces nonce aging and IP rate limits. (CSRF tokens are a different defense, against forged cross-site requests, and need a session that a public endpoint does not have.)
**Approved**: pending

**sourceUrl Captures window.location.href**
**Decision**: The POST body's `sourceUrl` field is `window.location.href` (undefined during SSR), including any query string or fragment.
**Rationale**: The backend stores this as the consent record's provenance, proving the address opted in at this specific page. This is necessary for compliance and dispute resolution. The full href can carry tokens or personal data in a query string or fragment, so a host page that puts such values in its URL should know they are sent; the component does not strip them.
**Approved**: pending

**No Optimistic Submission**
**Decision**: The form does not optimistically show a success state while the POST is in flight; it waits for the server response.
**Rationale**: A stale nonce or a backend outage could reject the submission. Showing success prematurely and then failing is worse than waiting for confirmation.
**Approved**: pending

**Separate "Closed" and "Unavailable" States**
**Decision**: `closed` and `unavailable` are kept as distinct, mutually exclusive phases.
**Rationale**: `closed` means the list loaded and is not accepting signups (a durable answer); `unavailable` means the backend never answered (retriable). Collapsing them would have the form claim a perfectly open list is closed whenever the backend happens to be down.
**Approved**: pending

**Labels Instead of Placeholders**
**Decision**: Email and name fields use real `<label>` elements, never placeholder-only text.
**Rationale**: Placeholder text vanishes when the user starts typing and is not reliably announced by assistive tech. Real labels stay visible and accessible.
**Approved**: pending

**Instance-Scoped IDs**
**Decision**: Every input/label ID is derived from a per-instance `React.useId()` value.
**Rationale**: Multiple forms on the same page each get unique IDs, so labels and inputs from one form do not interfere with another.
**Approved**: pending

**Rendered aria-invalid for Both True and False States**
**Decision**: `aria-invalid` is always rendered on the email input, as either `true` or `false`, never omitted.
**Rationale**: The field's validation state is always readable by assistive tech and tests, not just its failure half. This is more maintainable than conditionally rendering the attribute.
**Approved**: pending

**Closed-State Name Fallback**
**Decision**: The Closed state renders `config?.name ?? "This list"`, so an empty-string `config.name` produces a blank subject instead of "This list".
**Rationale**: This records what the source does today and treats it as a known defect, not a goal. A port may use an empty-name-aware fallback (`||`) without breaking any other requirement.
**Approved**: pending

**Accepted Accessibility and Localization Gaps**
**Decision**: The touch-target size (about 36px), Increase Contrast handling, string externalization and hardcoded English strings are known gaps that this version leaves open.
**Rationale**: The component ships as a self-contained embed with fixed English copy and Tailwind defaults; closing these gaps needs a localization layer and larger control sizing, which are changes to the component itself. The Compliance table records each as `failed` or `partial` so that no reader mistakes them for passes.
**Approved**: pending
