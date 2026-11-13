
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| mail-reader-view-controller-001 | blocking-policy-prefix | MailReaderDocumentTests `aBlockedDocumentOpensWithAPolicyThatAllowsNothingRemote`: HTML body with an `img` pointing at `https://t.example.com/open.gif`, blocking on | The document starts with `<meta http-equiv="Content-Security-Policy"`, contains `default-src 'none'`, and contains neither `https:;` nor `img-src *` |
| mail-reader-view-controller-002 | allowed-no-policy, html-as-sent | MailReaderDocumentTests `loadingRemoteImagesDropsThePolicy`: HTML body `<html><body>hi</body></html>`, blocking off | The document equals the body exactly |
| mail-reader-view-controller-003 | text-escaped, text-fallback-source | MailReaderDocumentTests `aTextBodyIsEscaped`: no HTML, text body `<script>alert(1)</script> & co`, blocking on | The document contains `&lt;script&gt;alert(1)&lt;/script&gt; &amp; co` and does not contain `<script>` |
| mail-reader-view-controller-004 | text-fallback-source | Source behavior: no HTML, no text body, snippet "Lunch at noon" | The page shows "Lunch at noon" inside the `pre` element |
| mail-reader-view-controller-005 | html-as-sent, text-fallback-source | Source behavior: empty-string HTML, text body "plain" | The text fallback page with "plain" is shown, not the empty HTML |
| mail-reader-view-controller-006 | blocking-policy-prefix | Source behavior: blocking on, any body | The prefix is exactly the policy text `default-src 'none'; img-src data: cid:; media-src data:; font-src data:; style-src 'unsafe-inline'` inside the meta tag |
| mail-reader-view-controller-007 | link-opens-externally | Source behavior: user clicks a link to `https://example.com/a` | The URL opens in the default browser and the reader's navigation is cancelled |
| mail-reader-view-controller-008 | link-opens-externally | Source behavior: a link to `MAILTO:a@example.com` | The URL is opened by the system and the reader's navigation is cancelled |
| mail-reader-view-controller-009 | link-other-schemes-dropped, link-never-in-reader | Source behavior: a link to `smb://host/share` | The navigation is cancelled and nothing is opened |
| mail-reader-view-controller-010 | fragment-in-place | Source behavior: in-frame link to `about:blank#section` | The navigation is allowed and the message scrolls in place; nothing opens externally |
| mail-reader-view-controller-011 | own-page-only | Source behavior: a meta refresh or form submit to `https://evil.example/` that is not a link activation | The navigation is cancelled |
| mail-reader-view-controller-012 | own-page-only | Source behavior: the reader's own `loadHTMLString` navigation to an `about:` URL, not a link | The navigation is allowed |
| mail-reader-view-controller-013 | navigation-without-url | Source behavior: a navigation request whose URL is nil | The navigation is cancelled |
| mail-reader-view-controller-014 | none-hides-message-views, none-placeholder-text, none-clears-body | Source behavior: the model's open message becomes nil | Header, separator and body are hidden; "No message selected" is shown; an empty HTML string is loaded |
| mail-reader-view-controller-015 | subject-line | Source behavior: message with subject "" | The subject line reads "(no subject)" |
| mail-reader-view-controller-016 | recipients-line, cc-suffix | Source behavior: to `a@x.com`, `b@x.com`; cc empty | The recipients line reads "To: a@x.com, b@x.com" |
| mail-reader-view-controller-017 | cc-suffix | Source behavior: to `a@x.com`; cc `c@x.com`, `d@x.com` | The recipients line reads "To: a@x.com   Cc: c@x.com, d@x.com" |
| mail-reader-view-controller-018 | same-message-no-reload | Source behavior: the model republishes message `m1` with the UNREAD label removed while `m1` is shown | The header lines update and the body is not reloaded |
| mail-reader-view-controller-019 | new-message-resets-remote, load-remote-scoped | Source behavior: remote allowed for `m1`, then `m2` opens | `m2` loads with the blocking policy and the remote-content bar shown when `m2` has HTML |
| mail-reader-view-controller-020 | remote-bar-shown-for-html | Source behavior: a message with a nil HTML body opens | The remote-content bar is hidden |
| mail-reader-view-controller-021 | load-remote-action | Source behavior: activate "Load Remote Images" on a message with HTML | The bar hides and the body reloads without the policy prefix and without the rule list |
| mail-reader-view-controller-022 | load-remote-no-message | Source behavior: activate "Load Remote Images" with the model's open message nil | Nothing changes |
| mail-reader-view-controller-023 | stale-load-guard | Source behavior: message `m1` opens, and `m2` opens before the rule list finishes compiling | Only `m2`'s body is loaded |
| mail-reader-view-controller-024 | rule-list-failure-tolerated | Source behavior: rule-list compilation returns nil | The body loads with the blocking policy prefix and no rule list |
| mail-reader-view-controller-025 | no-coder-init | Source behavior: construct from an archive | `init(coder:)` traps with "init(coder:) has not been implemented" |
| mail-reader-view-controller-026 | scripts-off | Source behavior: a message whose HTML body contains a script that writes to the page | The script does not run |
| mail-reader-view-controller-027 | rule-list-applied | Source behavior: blocking on, rule list compiled, HTML with `<img src="http://t.example/p.gif">` | The image request is blocked by the rule list |
| mail-reader-view-controller-028 | date-line | Source behavior: message date "not-a-date" | The date line shows "not-a-date" |
| mail-reader-view-controller-029 | observe-open-message | Source behavior: a message is already open when the view loads | The reader shows it as soon as the view has loaded |

