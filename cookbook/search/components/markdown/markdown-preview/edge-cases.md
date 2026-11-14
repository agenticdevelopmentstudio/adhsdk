
- **Empty content after trim**: Whitespace-only content shows the empty state, not the error state.
- **Fetch succeeds but JSON missing content key**: Response is `{}` or has no `content` field; it is treated as empty content and the empty state is shown (not the error state).
- **Network error during fetch**: The error state is shown with the original error message. A failure of a request that was abandoned by unmount or by a document change shows nothing.
- **Unmount during fetch**: The in-flight request is aborted and no state update occurs after unmount.
- **Retry after an error**: Clicking Retry re-fetches the same URL for the same document and returns to the loading state.
- **Abandoned request vs. timeout**: A timeout shows the timeout error state. An abort caused by unmount or a document change never shows an error (see the React/Web note for how the two are told apart).
- **Non-JSON response body**: The error state shows the parser's own message (e.g., a `SyntaxError` message for a malformed body). The generic "Failed to load paper." fallback is unreachable from this path; it only applies to a thrown non-`Error` value, which JSON parsing never produces.
- **Very short timeout renders "0s"**: The timeout message rounds `timeoutMs / 1000` with no minimum clamp, so a `timeoutMs` under 500 renders "Timed out loading paper after 0s." — an accurate but rough message the component does not correct.
- **Null or missing hit properties**: Component assumes `hit.author.slug` and `hit.publicRoute` exist and are strings; no null checks are present in source; passing undefined/null will result in invalid URLs or fetch failure.
- **Very large content**: MarkdownRenderer and rehype-sanitize process the full content; no streaming or chunking is performed.
- **Custom endpoint template**: If `source.endpoints.content` is provided, it overrides the default (`DEFAULT_CONTENT_ENDPOINT`, `/public/users/:slug/papers/:route`); template must include `:slug` and `:route` placeholders or they will not be replaced.

