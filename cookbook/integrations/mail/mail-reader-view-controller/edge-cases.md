
- **Empty subject**: MUST show "(no subject)" (#requirements/subject-line).
- **Empty `to` list**: the recipients line reads "To: " with nothing after it; the source adds no fallback text.
- **Empty `cc` list**: MUST append nothing to the recipients line (#requirements/cc-suffix).
- **Empty-string HTML body**: the remote-content bar is shown for it because the check is only whether the HTML is nil, yet the text fallback page is what loads, so the button then reloads the same text page. The source does not special-case it.
- **Nil HTML and nil text**: the snippet is used (#requirements/text-fallback-source). An empty snippet gives an empty page.
- **Very long headers**: the sender, recipients and date lines MUST truncate at the tail; the subject wraps and is at most the header width minus 32 points.
- **Unparseable date**: MUST show the original string unchanged (#requirements/date-line).
- **Boundary, same id republished**: the body MUST NOT reload (#requirements/same-message-no-reload). A message with a new id MUST reload even if its body is identical.
- **Boundary, scheme case**: `HTTPS://` and `Mailto:` MUST be treated as `https` and `mailto` for link opening, and `ABOUT:` as the reader's own page.
- **Concurrent access**: the controller is main-actor isolated, and each model value starts its own task. The header always reflects the latest value, and the stale-load-guard drops a body load whose message is no longer shown. Two quick publishes of the same new message reload the body once: the first records the id before any await, so the second is not new.
- **Error, rule list compile fails**: MUST load with the policy prefix alone (#requirements/rule-list-failure-tolerated). The failure is swallowed with no log or user message, and the next load tries to compile again. The source does not say whether that silence is intended.
- **Error, body load fails**: the controller sets no failure handler on the web view, so a failed load shows no message and no error state.
- **Remote content allowed**: the policy and the rule list are both gone, so only the navigation rules stop a page's own navigations (#requirements/own-page-only).
- **Offline or disconnected**: not applicable to the reader itself; it makes no network requests while blocked, and once remote content is allowed the web view's loads fail silently when the network is down. The message comes from the model, which reads local state.
- **Dropped link scheme**: a link whose scheme is not `http`, `https` or `mailto` MUST do nothing and show no confirmation.
- **Nil open message while remote allowed**: the remote-allowed flag is not cleared until the next different message is shown.

