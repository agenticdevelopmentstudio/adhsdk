
- **Empty content after trim**: If fetched content is all whitespace, `content.trim()` evaluates to falsy; component shows empty state (not error).
- **Fetch succeeds but JSON missing content key**: Response is `{}` or has no `content` field; code defaults to empty string (`body.content ?? ''`); empty state is shown.
- **Network error during fetch**: `.catch()` catches the error; if `!active` is true (unmount race), error is dropped silently; otherwise error state is shown with original error message.
- **Unmount during fetch**: `active` flag is set to false in the cleanup function; `.then()` and `.catch()` check `!active` and drop results silently; no state update occurs after unmount.
- **Re-select same document during error state**: User clicks Retry; `reloadToken` increments, triggering re-fetch; same URL is fetched again.
- **Controller abort vs. timeout abort**: `AbortSignal.any([controller.signal, AbortSignal.timeout(timeoutMs)])` combines both; timeout produces a `DOMException` with `name === 'TimeoutError'`, which is distinct from controller.abort() (checked via `controller.signal.aborted`).
- **Non-JSON response body**: If `res.json()` throws, the promise is rejected with an `Error`; `.catch()` catches it and shows that error's own `message` (e.g., a `SyntaxError` from a malformed body). The generic "Failed to load paper." fallback is unreachable from this path — it only applies to a thrown non-`Error` value, which `res.json()` never produces.
- **Very short timeout renders "0s"**: The timeout message rounds `timeoutMs / 1000` with no minimum clamp, so a `timeoutMs` under 500 renders "Timed out loading paper after 0s." — an accurate but rough message the component does not correct.
- **Null or missing hit properties**: Component assumes `hit.author.slug` and `hit.publicRoute` exist and are strings; no null checks are present in source; passing undefined/null will result in invalid URLs or fetch failure.
- **Very large content**: MarkdownRenderer and rehype-sanitize process the full content; no streaming or chunking is performed.
- **Custom endpoint template**: If `source.endpoints.content` is provided, it overrides the default (`DEFAULT_CONTENT_ENDPOINT`, `/public/users/:slug/papers/:route`); template must include `:slug` and `:route` placeholders or they will not be replaced.

