---
id: ac5b0100-ea5d-4abf-a9aa-11a477878514
title: "MailReaderViewController"
type: ingredient
version: 1.0.2
status: review
language: en
created: 2026-11-13
modified: 2026-11-15
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Mail reader pane: headers over a script-free web view that blocks remote loads and opens links externally."
platforms:
  - swift
  - macos
tags:
  - mail
  - appkit
  - webview
  - privacy
depends-on:
  - b3edb32d-7473-464b-acfb-c19cdd44e99e
related:
  - 018e4a69-cbeb-4105-8f39-dae3e6f7d8ec
  - 26473390-9629-40f0-ae98-32ccab2fc5da
  - 83a5a5e0-3337-4aff-aef8-40a7393dabfe
references: []
approved-by: ""
approved-date: ""
---

# MailReaderViewController

## Overview

The reader pane of the mail window. It shows the open message's headers (subject, sender, recipients, date) above the message body, and a placeholder reading "No message selected" when no message is open. A host puts it in the reader slot of the mail window and gives it the shared `MailBrowserModel`; it reads the model's open message and holds no mail logic of its own.

The body is shown in a web view with JavaScript off and every remote load blocked, so opening a message never tells its sender it was read (tracking pixels) and never runs the message's scripts. A "Load Remote Images" button lifts the block for the message on screen only. Links open in the default browser, never inside the reader. The privacy and navigation rules are the purpose of this component; the headers are a plain label stack.

## Behavioral Requirements

- **model-required**: The component MUST be constructed from a mail browser model and MUST read the open message from that model.
- **no-coder-init**: The component MUST NOT support construction from an archive; `init(coder:)` MUST trap.
- **observe-open-message**: The component MUST react on the main queue to every value the model publishes for its open message, including the value already present when the view loads.
- **none-hides-message-views**: When the open message is nil, the component MUST hide the header, the separator and the body view and MUST show the placeholder.
- **none-placeholder-text**: The placeholder MUST read "No message selected".
- **none-clears-body**: When the open message is nil, the component MUST load an empty HTML string with no base URL into the body view.
- **message-shows-views**: When a message is open, the component MUST show the header, the separator and the body view and MUST hide the placeholder.
- **subject-line**: The subject line MUST show the message subject, or "(no subject)" when the subject is empty.
- **from-line**: The sender line MUST show the message's `from` string unchanged.
- **recipients-line**: The recipients line MUST read "To: " followed by the `to` addresses joined by a comma and a space.
- **cc-suffix**: When the message has at least one `cc` address, the recipients line MUST append three spaces, "Cc: " and the `cc` addresses joined by a comma and a space; when `cc` is empty it MUST append nothing.
- **date-line**: The date line MUST show the model's full-date formatting of the message date, which returns the original string when the date cannot be parsed.
- **same-message-no-reload**: When the model republishes the message already on screen (same `id`, for example after marking it read), the component MUST update the header lines and MUST NOT reload the body.
- **new-message-resets-remote**: When a different message becomes open, the component MUST reset remote content to blocked for it.
- **remote-bar-shown-for-html**: When a different message becomes open, the component MUST show the remote-content bar if and only if the message has a non-nil, non-empty HTML body, the same test as **html-as-sent**. The source tests only for a non-nil HTML body; see the known gap in Edge Cases.
- **remote-bar-copy**: The remote-content bar MUST show the note "Remote images are blocked to protect your privacy." and a button titled "Load Remote Images".
- **load-remote-action**: Activating "Load Remote Images" MUST allow remote content for the open message, hide the remote-content bar and reload the body without the blocking policy and without the content rule list.
- **load-remote-scoped**: Allowing remote content MUST apply only to the message on screen; opening a different message MUST block remote content again.
- **load-remote-no-message**: Activating "Load Remote Images" while the model has no open message MUST do nothing.
- **scripts-off**: The body view MUST run with JavaScript disabled for page content.
- **no-persistent-data**: The body view MUST use a non-persistent website data store.
- **blocking-policy-prefix**: When remote content is blocked, the document MUST begin with a Content-Security-Policy meta tag whose policy is exactly `default-src 'none'; img-src data: cid:; media-src data:; font-src data:; style-src 'unsafe-inline'`.
- **allowed-no-policy**: When remote content is allowed, the document MUST NOT carry that policy prefix.
- **html-as-sent**: When the message has a non-empty HTML body, the document MUST use that HTML as sent.
- **text-fallback-source**: When the HTML body is nil or empty, the document MUST be built from the text body, or from the snippet when the text body is nil.
- **text-escaped**: The text fallback MUST replace `&` with `&amp;`, `<` with `&lt;` and `>` with `&gt;` before placing the text in the page, and the page MUST NOT contain an unescaped `<script>` from the text.
- **text-page-style**: The text fallback page MUST declare `color-scheme: light dark`, wrap the text in a `pre` element with wrapping whitespace, and use a 13px system sans-serif font with a 16px body margin.
- **rule-list-applied**: When remote content is blocked and the content rule list is available, the component MUST install a rule list that blocks URLs beginning with `http://`, `https://`, `ws://`, `wss://` and `ftp://`.
- **rule-list-cleared**: Before every body load the component MUST remove all content rule lists it previously installed.
- **rule-list-per-scheme**: The rule list MUST use one rule per scheme family (`^https?://`, `^wss?://`, `^ftp://`) because WebKit's content-blocker regular expression has no alternation.
- **rule-list-compiled-once**: The component MUST compile the rule list at most once per process while compilation succeeds, under the identifier "mail-reader-block-remote".
- **rule-list-failure-tolerated**: When the rule list fails to compile, the component MUST still load the body with the blocking policy prefix.
- **stale-load-guard**: When the open message has changed while the rule list compiled, the component MUST NOT load the earlier message's body.
- **link-opens-externally**: A link activation, or a request with no target frame, to a URL whose scheme is `http`, `https` or `mailto` (compared case-insensitively) MUST open in the system's default handler for that URL.
- **link-never-in-reader**: A link activation, or a request with no target frame, MUST NOT navigate the reader, whatever its scheme, except the in-frame fragment link of fragment-in-place.
- **link-other-schemes-dropped**: A link to any other scheme (`smb`, `vnc`, `ssh` or an app's own) MUST be cancelled and MUST NOT be opened.
- **fragment-in-place**: A link within the same frame (the target frame is not nil) to the reader's own page, meaning an `about:` URL, that carries a non-empty fragment MUST be allowed so the message scrolls in place.
- **own-page-only**: Any navigation that is not a link activation and has a target frame MUST be allowed only when its URL scheme is `about` (compared case-insensitively) and MUST be cancelled otherwise.
- **navigation-without-url**: A navigation request with no URL MUST be cancelled.
- **body-accessibility-id**: The body view MUST carry the accessibility identifier "mail.reader.body".
- **header-selectable**: The subject, sender, recipients and date text MUST be selectable.
- **header-truncation**: The sender, recipients and date lines MUST truncate at the tail when too long. They MUST yield width first: each sets a low horizontal content compression resistance priority (`defaultLow`), so they compress before the subject and the remote-content bar.
- **fixed-constants**: The external link schemes (`http`, `https`, `mailto`), the blocking policy text from **blocking-policy-prefix** and the rule list identifier "mail-reader-block-remote" are fixed constants. An implementation MUST NOT expose them as settings.
- **localized-strings**: A port MUST take every user-visible string from the keys in Localization and MUST NOT use literals. The source uses literals today.

## Appearance

- **Corner radius**: Not applicable: the controller draws no rounded shape; the web view and system labels draw themselves.
- **Padding**: The header stack has edge insets of 14 top, 16 left, 10 bottom and 16 right points, 4 points between rows, and 8 points after the subject and after the date line. The remote-content bar has 8 points between its note and button. The text fallback page has a 16px body margin.
- **Font**: Subject 18 point system font, semibold, wrapping. Sender line in the default label font. Recipients line in the default label font. Date line in the small system font size. The remote-content note in the small system font size. The "Load Remote Images" button at small control size. Text fallback body 13px system sans-serif.
- **Background**: Not applicable: no background is set; the window and the web page supply their own.
- **Foreground/Text**: The recipients line, date line and remote-content note use the system secondary label color. The sender and subject use the default label color. The placeholder uses the secondary label color.
- **Border**: A system separator rule between the header and the body, hidden with the header.
- **Shadow**: Not applicable: none set.
- **Min/Max size**: The subject is at most the header width minus 32 points. The placeholder is centered in the pane both ways. The body fills the pane below the separator. The source sets no minimum size; the host's pane minimum (360 points in the mail window) is set outside this component.

Layout from top to bottom: header, separator, body. The remote-content bar is the last row of the header.

## States

| State | Appearance change |
|-------|------------------|
| Default | Same as Empty until the model publishes a message. |
| Pressed | Not applicable: the controller has no pressed state of its own; the "Load Remote Images" button uses the system pressed look. |
| Disabled | Not applicable: no control in the controller is ever disabled in source. |
| Focused | Not applicable: the controller sets no focus styling; focus drawing is the system's for the button and web view. |
| Loading | Not applicable: the controller shows no loading indicator while the body loads. |
| Empty | No message open: header, separator and body hidden; "No message selected" centered. |
| Message, remote blocked | Headers and body shown; remote-content bar shown when the message has an HTML body. |
| Message, remote allowed | Headers and body shown; the remote-content bar hidden; the body loaded without the policy or rules. |
| Message, text only | Headers and the text fallback page shown; the remote-content bar hidden. |

## Accessibility

- **role**: The header lines are system labels and the action is a system push button; the controller sets no role or trait of its own.
- **body-identifier**: The body view MUST expose the identifier "mail.reader.body" for assistive and automated lookup.
- **header-identifiers**: The header lines MUST carry the identifiers `mail.reader.subject`, `mail.reader.from`, `mail.reader.recipients` and `mail.reader.date`; the placeholder carries `mail.reader.placeholder` and the remote-content button `mail.reader.load-remote`.
- **button-label**: The remote-content action MUST be labeled by its visible title "Load Remote Images".
- **keyboard-path**: The "Load Remote Images" button and the selectable header text use standard system controls, so they take part in the system key view loop; the controller adds no shortcut of its own.
- **small-button-target**: NEEDS REVIEW: Not implemented in source. The button is set to small control size and the source states no minimum target size; a design decision on whether that size meets the platform minimum is needed, settled by measuring the rendered button against the Apple Human Interface Guidelines.
- **state-announcement**: NEEDS REVIEW: Not implemented in source. Nothing announces a change of open message, the hiding of the remote-content bar, or the end of the body load to assistive technology; whether the system's own announcements for the web view suffice is settled by testing with VoiceOver.

## Conformance Test Vectors

Rows whose Test column names no test are derived from the source and have no test behind them; an implementer writes the test.

| ID | Requirements | Test | Input | Expected |
|----|-------------|------|-------|----------|
| mail-reader-view-controller-001 | blocking-policy-prefix | `MailReaderDocumentTests.aBlockedDocumentOpensWithAPolicyThatAllowsNothingRemote` | HTML body with an `img` pointing at `https://t.example.com/open.gif`, blocking on | The document starts with `<meta http-equiv="Content-Security-Policy"`, contains `default-src 'none'`, and contains neither `https:;` nor `img-src *` |
| mail-reader-view-controller-002 | allowed-no-policy, html-as-sent | `MailReaderDocumentTests.loadingRemoteImagesDropsThePolicy` | HTML body `<html><body>hi</body></html>`, blocking off | The document equals the body exactly |
| mail-reader-view-controller-003 | text-escaped, text-fallback-source | `MailReaderDocumentTests.aTextBodyIsEscaped` | no HTML, text body `<script>alert(1)</script> & co`, blocking on | The document contains `&lt;script&gt;alert(1)&lt;/script&gt; &amp; co` and does not contain `<script>` |
| mail-reader-view-controller-004 | text-fallback-source | none: derived from source | no HTML, no text body, snippet "Lunch at noon" | The page shows "Lunch at noon" inside the `pre` element |
| mail-reader-view-controller-005 | html-as-sent, text-fallback-source | none: derived from source | empty-string HTML, text body "plain" | The text fallback page with "plain" is shown, not the empty HTML |
| mail-reader-view-controller-006 | blocking-policy-prefix | none: derived from source | blocking on, any body | The prefix is exactly the policy text `default-src 'none'; img-src data: cid:; media-src data:; font-src data:; style-src 'unsafe-inline'` inside the meta tag |
| mail-reader-view-controller-007 | link-opens-externally | none: derived from source | user clicks a link to `https://example.com/a` | The URL opens in the default browser and the reader's navigation is cancelled |
| mail-reader-view-controller-008 | link-opens-externally | none: derived from source | a link to `MAILTO:a@example.com` | The URL is opened by the system and the reader's navigation is cancelled |
| mail-reader-view-controller-009 | link-other-schemes-dropped, link-never-in-reader | none: derived from source | a link to `smb://host/share` | The navigation is cancelled and nothing is opened |
| mail-reader-view-controller-010 | fragment-in-place | none: derived from source | in-frame link to `about:blank#section` | The navigation is allowed and the message scrolls in place; nothing opens externally |
| mail-reader-view-controller-011 | own-page-only | none: derived from source | a meta refresh or form submit to `https://evil.example/` that is not a link activation | The navigation is cancelled |
| mail-reader-view-controller-012 | own-page-only | none: derived from source | the reader's own `loadHTMLString` navigation to an `about:` URL, not a link | The navigation is allowed |
| mail-reader-view-controller-013 | navigation-without-url | none: derived from source | a navigation request whose URL is nil | The navigation is cancelled |
| mail-reader-view-controller-014 | none-hides-message-views, none-placeholder-text, none-clears-body | none: derived from source | the model's open message becomes nil | Header, separator and body are hidden; "No message selected" is shown; an empty HTML string is loaded |
| mail-reader-view-controller-015 | subject-line | none: derived from source | message with subject "" | The subject line reads "(no subject)" |
| mail-reader-view-controller-016 | recipients-line, cc-suffix | none: derived from source | to `a@x.com`, `b@x.com`; cc empty | The recipients line reads "To: a@x.com, b@x.com" |
| mail-reader-view-controller-017 | cc-suffix | none: derived from source | to `a@x.com`; cc `c@x.com`, `d@x.com` | The recipients line reads "To: a@x.com   Cc: c@x.com, d@x.com" |
| mail-reader-view-controller-018 | same-message-no-reload | none: derived from source | the model republishes message `m1` with the UNREAD label removed while `m1` is shown | The header lines update and the body is not reloaded |
| mail-reader-view-controller-019 | new-message-resets-remote, load-remote-scoped | none: derived from source | remote allowed for `m1`, then `m2` opens | `m2` loads with the blocking policy and the remote-content bar shown when `m2` has HTML |
| mail-reader-view-controller-020 | remote-bar-shown-for-html | none: derived from source | a message with a nil HTML body opens | The remote-content bar is hidden |
| mail-reader-view-controller-021 | load-remote-action | none: derived from source | activate "Load Remote Images" on a message with HTML | The bar hides and the body reloads without the policy prefix and without the rule list |
| mail-reader-view-controller-022 | load-remote-no-message | none: derived from source | activate "Load Remote Images" with the model's open message nil | Nothing changes |
| mail-reader-view-controller-023 | stale-load-guard | none: derived from source | message `m1` opens, and `m2` opens before the rule list finishes compiling | Only `m2`'s body is loaded |
| mail-reader-view-controller-024 | rule-list-failure-tolerated | none: derived from source | rule-list compilation returns nil | The body loads with the blocking policy prefix and no rule list |
| mail-reader-view-controller-025 | no-coder-init | none: derived from source | construct from an archive | `init(coder:)` traps |
| mail-reader-view-controller-026 | scripts-off | none: derived from source | a message whose HTML body contains a script that writes to the page | The script does not run |
| mail-reader-view-controller-027 | rule-list-applied | none: derived from source | blocking on, rule list compiled, HTML with `<img src="http://t.example/p.gif">` | The image request is blocked by the rule list |
| mail-reader-view-controller-028 | date-line | none: derived from source | message date "not-a-date" | The date line shows "not-a-date" |
| mail-reader-view-controller-029 | observe-open-message | none: derived from source | a message is already open when the view loads | The reader shows it as soon as the view has loaded |
| mail-reader-view-controller-030 | own-page-only | none: derived from source | a meta refresh to `about:blank` that is not a link activation | The source allows the navigation; whether it should is undecided |
| mail-reader-view-controller-031 | remote-bar-shown-for-html | none: derived from source | a message with an empty-string HTML body opens | The remote-content bar is hidden (the source shows it; known gap) |
| mail-reader-view-controller-032 | small-button-target | none: derived from source | Measure the rendered "Load Remote Images" button against the Apple Human Interface Guidelines minimum target | The size is recorded and the review item settled |
| mail-reader-view-controller-033 | state-announcement | none: derived from source | With VoiceOver on, open a message, activate "Load Remote Images" and let the body finish loading | Whether VoiceOver announces each change is recorded and the review item settled |

## Edge Cases

- **Empty subject**: MUST show "(no subject)" (#requirements/subject-line).
- **Empty `to` list**: the recipients line reads "To: " with nothing after it; the source adds no fallback text.
- **Empty `cc` list**: MUST append nothing to the recipients line (#requirements/cc-suffix).
- **Empty-string HTML body**: the remote-content bar MUST be hidden, because the text fallback page loads and there is nothing remote to allow (#requirements/remote-bar-shown-for-html). Known gap: the source shows the bar, because its check is only whether the HTML is nil, so the button then reloads the same text page.
- **Nil HTML and nil text**: the snippet is used (#requirements/text-fallback-source). An empty snippet gives an empty page.
- **Very long headers**: the sender, recipients and date lines MUST truncate at the tail; the subject wraps and is at most the header width minus 32 points.
- **Unparseable date**: MUST show the original string unchanged (#requirements/date-line).
- **Boundary, same id republished**: the body MUST NOT reload (#requirements/same-message-no-reload). A message with a new id MUST reload even if its body is identical.
- **Boundary, scheme case**: `HTTPS://` and `Mailto:` MUST be treated as `https` and `mailto` for link opening, and `ABOUT:` as the reader's own page.
- **Concurrent access**: the controller is main-actor isolated, and each model value starts its own task. The header always reflects the latest value, and the stale-load-guard drops a body load whose message is no longer shown. Two quick publishes of the same new message reload the body once: the first records the id before any await, so the second is not new.
- **Error, rule list compile fails**: MUST load with the policy prefix alone (#requirements/rule-list-failure-tolerated). The failure is swallowed with no log or user message, and the next load tries to compile again. The source does not say whether that silence is intended.
- **Error, body load fails**: the controller sets no failure handler on the web view, so a failed load shows no message and no error state.
- **Meta refresh to `about:blank`**: a navigation the message starts by itself to an `about:` URL passes the own-page test, so the source allows it and the message is replaced by a blank page under the real headers. Whether only the reader's own `loadHTMLString` navigation should pass is undecided (mail-reader-view-controller-030).
- **Remote content allowed**: the policy and the rule list are both gone, so only the navigation rules stop a page's own navigations (#requirements/own-page-only).
- **Offline or disconnected**: not applicable to the reader itself; it makes no network requests while blocked, and once remote content is allowed the web view's loads fail silently when the network is down. The message comes from the model, which reads local state.
- **Dropped link scheme**: a link whose scheme is not `http`, `https` or `mailto` MUST do nothing and show no confirmation.
- **Nil open message while remote allowed**: the remote-allowed flag is not cleared until the next different message is shown.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| model | MailBrowserModel | required | The shared model whose open message the reader shows; given at construction. |

Internal constants, not configurable: the external link schemes, the blocking policy text and the rule list identifier are fixed in the source (`externalSchemes` is a static constant); see **fixed-constants**.

## Deep Linking

Not applicable: the reader opens no deep links and has no address of its own; it opens only the links inside a message in the system's default handler.

## Localization

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| mail.reader.placeholder | No message selected | Placeholder when no message is open |
| mail.reader.noSubject | (no subject) | Subject line for an empty subject |
| mail.reader.toPrefix | To: | Prefix of the recipients line |
| mail.reader.ccPrefix | Cc: | Cc part of the recipients line |
| mail.reader.remoteNote | Remote images are blocked to protect your privacy. | Note in the remote-content bar |
| mail.reader.loadRemote | Load Remote Images | Button title |

The keys are the contract for ports (see **localized-strings**); the source uses the English text as literals, not keys. The date line is formatted by the model's locale-aware date formatting.

## Accessibility Options

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable: the controller runs no animation. |
| Increase Contrast | The secondary text uses the system secondary label color, which the system adjusts; the controller sets no contrast values of its own. |
| Differentiate Without Color | Not applicable: the controller conveys no state by color alone; the remote-content state is shown by the bar's presence and text. |

## Feature Flags

Not applicable: the source reads no feature flag; the reader always applies its blocking rules.

## Analytics

Not applicable: the source records no analytics event.

## Privacy

- **Data collected**: None by the reader. Its purpose is to stop the message's sender from collecting a read signal.
- **Storage**: Nothing is persisted: the body view's website data store is non-persistent. The compiled content rule list is kept by WebKit's rule list store under "mail-reader-block-remote".
- **Transmission**: While remote content is blocked, the reader makes no request to any remote host; the policy and the rule list both stop it. After "Load Remote Images", the message's remote loads leave the device, for that message only.
- **Retention**: Not applicable: the reader keeps no data beyond the on-screen message.

## Logging

Not applicable: the source writes no log; the swallowed rule list failure produces no log line.

## Platform Notes

- **SwiftUI**: Host a `WKWebView` in an `NSViewRepresentable` (macOS) or `UIViewRepresentable` (iOS) with the same configuration: `allowsContentJavaScript` false and `.nonPersistent()`. Build the header as a `VStack(alignment: .leading)` of `Text` with `.textSelection(.enabled)`, `.lineLimit(1)` and `.truncationMode(.tail)`, and switch on `model.openedMessage` for the placeholder. Keep the navigation delegate in a coordinator; use `Link` or `openURL` to open external links. Reuse the policy string and the content rule list unchanged.
- **Compose**: Use `AndroidView` around `WebView` with `settings.javaScriptEnabled = false`, `settings.blockNetworkLoads = true` while blocked (set it to false for "Load Remote Images"), and `loadDataWithBaseURL(null, html, "text/html", "utf-8", null)`. Cancel navigation in `shouldOverrideUrlLoading` and open `http`, `https` and `mailto` with an `ACTION_VIEW` intent only. There is no content rule list; the CSP meta tag and `blockNetworkLoads` replace it. Use `Text` with `maxLines = 1` and `TextOverflow.Ellipsis` for the header lines, wrapped in `SelectionContainer`.
- **React/Web**: Render the body in a sandboxed `iframe` with `srcdoc` and a `sandbox` attribute that omits `allow-scripts` and `allow-same-origin`; prepend the same CSP meta tag to `srcdoc` when blocked. A sandboxed frame cannot navigate the top page. Because the sandbox lacks `allow-same-origin`, the parent cannot intercept clicks, so a sanitizer rewrites anchors to `target="_blank"` with `rel="noopener noreferrer"` and drops non-`http`, `https` and `mailto` schemes; add `allow-popups` and `allow-popups-to-escape-sandbox` to the `sandbox` attribute so those links open. The remote-content bar is a `button` that rebuilds `srcdoc` without the policy.
- **AppKit / UIKit**: The source is `macOS/Features/Integrations/Mail/MailReaderViewController.swift`, an `NSViewController` and `WKNavigationDelegate` built in `loadView` from `NSStackView`, `NSBox` and `NSTextField`, and subscribed to `model.$openedMessage` in `viewDidLoad`. It is specific to AppKit in using `NSWorkspace.shared.open` and `NSTextField(wrappingLabelWithString:)`. On UIKit, use `UIStackView`, `UILabel` (numberOfLines 0 for the subject), `UIApplication.shared.open` for links, and `WKWebView` unchanged; `WKContentRuleListStore` and the delegate's async `decidePolicyFor` work the same on iOS 15 and later.
- **WinUI 3**: Use a `Grid` with three rows (`Auto` header, `Auto` separator, `*` body) and a centered `TextBlock` placeholder; drive visibility with `VisualStateManager` states `EmptyState`, `BlockedState` and `AllowedState` so the header, `Border` separator (1 pixel), `WebView2` and the remote-content bar change together. The header is a `StackPanel` with `Padding` 16,14,16,10 and `Spacing` 4; `TextBlock` for the subject (`FontSize` 18, `FontWeight` `SemiBold`, `TextWrapping` `Wrap`, `IsTextSelectionEnabled` true), and one-line `TextBlock` for the rest with `TextTrimming` `CharacterEllipsis` and `Foreground` bound to `TextFillColorSecondaryBrush`. The remote-content bar is a horizontal `StackPanel` with a `TextBlock` and a `Button` with `Content` "Load Remote Images". Body: `WebView2`; after `EnsureCoreWebView2Async`, set `CoreWebView2.Settings.IsScriptEnabled = false`, create it with an in-private profile (`CoreWebView2ControllerOptions.IsInPrivateModeEnabled`) for the non-persistent store, and show content with `NavigateToString` (limited to about 2 MB, which the source does not face). WebView2 has no content rule list; add `AddWebResourceRequestedFilter("*", CoreWebView2WebResourceContext.All)` and, in `WebResourceRequested`, answer `http`, `https`, `ws`, `wss` and `ftp` requests with `CreateWebResourceResponse` set to status 403 while blocked, and prepend the same CSP meta tag. Cancel in `NavigationStarting` by setting `Cancel` true unless the request is the reader's own `NavigateToString` page: record the navigation ID of each `NavigateToString` call the reader makes and allow only a navigation with that ID (its reported URI is a `data:` address, not `about`, so the `about:` test does not apply). Handle `NewWindowRequested` by setting `Handled` true. Open `http`, `https` and `mailto` links with `Launcher.LaunchUriAsync` and drop all other schemes. Set `AutomationProperties.AutomationId` to "mail.reader.body" on the `WebView2`, `AutomationProperties.Name` on the button, and keep the button at the default `MinHeight` of 32 epx so the target meets Fluent 2 guidance.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| macos | `packages/apple/AgenticDeveloperHubSDK/macOS/Features/Integrations/Mail/MailReaderViewController.swift` | confirmed (1.0.2) |
| ios | (planned) | planned |
| web | (planned) | planned |
| android | (planned) | planned |
| windows | (planned) | planned |

## Design Decisions

**Decision**: The body is shown with JavaScript off, a non-persistent data store and every remote load blocked until the user asks for them.
**Rationale**: Opening a message must never tell its sender it was read through tracking pixels, and must never run its scripts.
**Approved**: pending

**Decision**: Remote blocking is done twice: a Content-Security-Policy meta tag at the start of the document and a content rule list.
**Rationale**: The policy is the block itself, not a backup: it holds even if the content rule list fails to compile. The rule list is compiled once per process and the policy needs none.
**Approved**: pending

**Decision**: The policy is placed first in the document, and the document is the sender's HTML as sent.
**Rationale**: The HTML parser places a leading meta tag in the head, and a policy the message brings can only narrow this one.
**Approved**: pending

**Decision**: The rule list uses three rules, one per scheme family, not one rule with alternation.
**Rationale**: WebKit's content-blocker regular expression has no alternation.
**Approved**: pending

**Decision**: "Load Remote Images" applies to the message on screen only and is cleared when a different message opens.
**Rationale**: The block is lifted for the message on screen only, so one trusted message never makes the next one load trackers.
**Approved**: pending

**Decision**: Only a different message id reloads the body; a republished message with the same id updates the header alone.
**Rationale**: A label change (marking read) republishes the message, and reloading only for a different one keeps the scroll position and avoids a flash.
**Approved**: pending

**Decision**: Links open in the system's default handler only for `http`, `https` and `mailto`, and every other scheme is dropped.
**Rationale**: Any other scheme (smb, vnc, ssh, an app's own) would launch its handler from one click with none of the confirmation a browser shows.
**Approved**: pending

**Decision**: Every navigation the message starts by itself (meta refresh, form submit, frame) is cancelled; only the reader's own `about:` page loads.
**Rationale**: Such a navigation would put a sender-chosen page under the real message headers with no address bar, and the policy and rule list block loads, not navigations, and are gone once remote content is allowed.
**Approved**: pending

**Decision**: An in-frame `#section` link to the reader's own page is allowed.
**Rationale**: It scrolls the message in place; it is the one link the reader keeps.
**Approved**: pending

**Decision**: A stale body load is dropped after the rule list compiles.
**Rationale**: The message may have changed while the rules compiled, and an earlier message's body must not replace the later one.
**Approved**: pending

**Decision**: Known gap: the source shows the remote-content bar for an empty-string HTML body, and a failed rule list compile or body load shows no message.
**Rationale**: Technical debt: the source tests only for a nil HTML body (the requirement **remote-bar-shown-for-html** asks for non-empty), and it has no failure handler or log. Pay it down when the reader next changes: fix the bar test first, and add a failure state once the product decides what a failed body load shows.
**Approved**: pending

**Decision**: Known gap: the source's strings are literals, and `init(coder:)` traps.
**Rationale**: Technical debt: the strings cannot be localized without a code change, and the controller cannot be loaded from a nib or storyboard. Pay down the strings when a second locale ships, by moving them to the keys in Localization; the trap stays until a nib-built reader is wanted.
**Approved**: pending

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | best-practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | best-practices |
| [adc.check.best-practices.explicit-error-handling](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0813f93d-65e6-5559-8d81-422b37af430a) | partial | best-practices |
| [adc.check.security.input-sanitization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7d737e1-b124-5f9a-b1c2-0ca1b96eeb8a) | passed | security |
| [adc.check.internationalization.no-hardcoded-strings](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c8f9f270-e8cb-57b9-a48f-296d6f260b3a) | failed | internationalization |
| [adc.check.platform-compliance.native-controls-preference](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d49de883-3811-54ed-b227-c2d807cac551) | passed | platform-compliance |

The reader keeps all mail state in the model and only maps its open message to labels and a web view, with the policy and navigation decisions in small static functions, so separation of concerns passes. Unit coverage is partial: `MailReaderDocumentTests` covers the document the reader builds (the policy prefix, the as-sent HTML and the escaped text), while no test covers the link and navigation rules, the rule list, the same-message reload rule or the header lines. Error handling is partial: the rule list compile failure is swallowed by design, with the policy as the real block, but a failed body load has no visible state. Input sanitization passes because message text is escaped and remote loads, scripts and self-started navigations are blocked. The strings are literals, which fails the hardcoded-strings check. The headers, button, separator and web view are system controls.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.2 | 2026-11-15 | Mike Fullerton | Accessibility identifiers for UI tests and automation |
| 1.0.1 | 2026-11-14 | Mike Fullerton | Required the remote-content bar only for a non-empty HTML body (source deviation recorded as a known gap), added fixed-constants and localized-strings requirements with localization keys, gave the known-gap decisions payoff conditions, dropped source-comment attribution from rationales, split test names into their own vector column, and added vectors for meta refresh to about:blank, empty HTML and the two review items. |
