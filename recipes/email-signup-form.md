---
id: 46b0cb5d-bd0c-45d0-ab14-95054e1c59ab
title: Email Signup Form
domain: adhsdk://recipes/email-signup-form
type: ingredient
version: 1.1.1
status: review
language: en
created: '2026-09-22'
modified: '2026-09-25'
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: Embeddable waitlist signup form with anti-abuse protection and customizable
  copy.
platforms:
- typescript
- web
tags:
- form
- signup
- email-capture
- embedded
depends-on: []
related: []
references:
- https://www.w3.org/WAI/WCAG21/Understanding/target-size.html
- https://tailwindcss.com/docs
- https://react.dev/reference/react/useId
approved-by: ''
approved-date: ''
---

# Email Signup Form

## Overview

The Email Signup Form is an embeddable React component that collects email addresses (and optionally names) for a waitlist or mailing list. It is designed for third-party websites: the component has no internal coupling to any backend other than two public endpoints (list configuration and signup submission) and can be embedded with only a public key and an API base URL. The form includes anti-abuse protection via a honeypot field and a server-side nonce aging mechanism, and communicates failures to developers through console logging rather than user-facing error details.

## Behavioral Requirements

- **load-config-on-mount**: Component MUST fetch list configuration from the server when mounted, using a GET request to `{apiBaseUrl}/public/signup-lists/{publicKey}` with a 10-second timeout.
- **timeout-config-request**: Component MUST treat config fetch failure due to timeout (after 10,000ms) as a retriable error in the `unavailable` state.
- **handle-config-not-ok**: Component MUST treat any HTTP response with status not 2xx as a configuration load failure and enter the `unavailable` state.
- **parse-config-json**: Component MUST parse the config response as JSON and extract the fields `name`, `description`, `status`, `nonce`, and optionally `minAgeMs`.
- **reject-malformed-config**: Component MUST treat a config response body that cannot be parsed as JSON as a configuration load failure — logged through the same failure path as a non-2xx response — and enter the `unavailable` state.
- **adopt-config-with-timestamp**: Component MUST record the timestamp when configuration is successfully received, for use in nonce age calculations.
- **show-loading-state**: Component MUST display "Loading…" text while the initial config request is in flight.
- **show-closed-state**: Component MUST display "{list name} is closed to new signups right now." when config.status is not "open", and MUST NOT render a form in this state.
- **show-unavailable-state**: Component MUST display "Signups are unavailable right now." with a clickable "Try again" button when the config fetch fails, allowing the user to retry without a page reload.
- **show-ready-state**: Component MUST render the signup form when config is loaded and status is "open".
- **validate-email-locally**: Component MUST validate the email address against the pattern `/^[^\s@]+@[^\s@]+\.[^\s@]+$/` before submission.
- **reject-invalid-email**: Component MUST display the validation error "Enter a valid email address." and MUST NOT submit when email fails local validation. The email input is also `required` and `type="email"`, and the `<form>` has no `noValidate`, so for a real user click on the submit button, the browser's own native constraint validation runs first: for an empty field or one that fails the browser's `type="email"` check, the browser blocks the `submit` event with its own message, and this handler (and the message above) never runs. The component's own message is reachable by a real click only for input that passes the browser's check but fails the stricter local pattern (e.g. `"a@b"`), or by any submit that bypasses native validation (a synthetic/programmatic `submit` event).
- **trim-email-before-submit**: Component MUST trim whitespace from the email value before both validation and submission.
- **trim-name-before-submit**: Component MUST trim whitespace from the name value before submission (if collectName is true).
- **wait-for-nonce-age**: Component MUST wait until the nonce age (time since config.nonce was received) exceeds config.minAgeMs before submitting, if minAgeMs is specified.
- **add-timing-buffer**: Component MUST add 250ms to any nonce age wait to account for `setTimeout`'s lower-bound rounding and other measurement noise — not for clock differences between client and server; the elapsed-duration measurement used by **wait-for-nonce-age** is already immune to clock skew on its own.
- **enter-submitting-state**: Component MUST set phase to "submitting" and disable the submit button before sending the POST request.
- **post-submission**: Component MUST POST the signup data to `{apiBaseUrl}/public/signup-lists/{publicKey}/signups` with method "POST", Content-Type "application/json", and body containing email, name (if provided), nonce, website (honeypot), and sourceUrl.
- **include-honeypot-in-post**: Component MUST send the honeypot field value to the server in the POST body as `website`, on every submission — empty for a legitimate visitor, non-empty only if something else filled it in.
- **include-source-url**: Component MUST capture and send `window.location.href` as `sourceUrl` in the POST body, unless running on the server (SSR).
- **handle-submission-ok**: Component MUST enter the "done" state and display the success message when the POST response status is 2xx.
- **handle-submission-error**: Component MUST catch POST errors (any status not 2xx, network failure, or timeout) and display "Something went wrong. Please try again." with a generic error message.
- **return-to-ready-on-error**: Component MUST return to the "ready" state after an error, allowing the user to retry.
- **refresh-nonce-on-error**: Component MUST fetch a fresh config (with a new nonce) after a submission error, in case the original nonce has expired.
- **suppress-server-error-details**: Component MUST NOT display server error reasons or HTTP status codes to the visitor; errors MUST NOT leak anti-abuse gate details.
- **log-failures-to-console**: Component MUST log configuration-load failures and nonce-refresh failures (the two console-visible failure paths; a submission failure by itself is not separately logged — see the Logging section) to the browser console with the public key included, for developer debugging only.
- **log-with-prefix**: Component MUST prefix all console error messages with `[EmailSignupForm]` for easy identification.
- **render-email-label**: Component MUST render a visible `<label>` with text "Email address" for the email input field.
- **render-name-label-when-enabled**: Component MUST render a visible `<label>` with text "Name" for the name input field when collectName is true.
- **mark-email-required**: Component MUST set the `required` attribute on the email input.
- **set-email-type**: Component MUST set type="email" on the email input.
- **set-name-autocomplete**: Component MUST set autoComplete="name" on the name input.
- **set-email-autocomplete**: Component MUST set autoComplete="email" on the email input.
- **mark-email-invalid-on-validation-error**: Component MUST set `aria-invalid="true"` on the email input when a validation error exists, and set it to false when there is no error.
- **associate-error-with-field**: Component MUST set `aria-describedby` on the email input to reference the error message when a validation error exists.
- **render-honeypot-hidden**: Component MUST render the honeypot input with `aria-hidden="true"`, `tabIndex={-1}`, and CSS positioning that removes it from the visual and tab order flow (e.g., `position: absolute; left: -9999px`).
- **opt-out-honeypot-autofill**: Component MUST apply autofill opt-out properties to the honeypot field to prevent password managers from filling it.
- **mark-error-alert**: Component MUST set `role="alert"` on the error message container.
- **display-error-when-present**: Component MUST render an error message only when an error object exists, MUST NOT pre-render an empty error container.
- **use-unique-ids**: Component MUST generate unique instance-scoped IDs for all inputs and labels using React.useId(), to support multiple forms on the same page.
- **mark-submit-disabled-during-submit**: Component MUST set the `disabled` attribute on the submit button when phase is "submitting".
- **mark-submit-busy**: Component MUST set `aria-busy="true"` on the submit button when the form is submitting.
- **change-submit-label-on-submit**: Component MUST change the button text to "Signing up…" when submitting.
- **show-success-message**: Component MUST display the successMessage text when phase is "done".
- **replace-form-on-success**: Component MUST render only the success message (not the form) when phase is "done".
- **focus-success-message**: Component MUST programmatically focus the success message container — which exposes `tabIndex={-1}` so it is focusable — to ensure screen readers announce it.
- **set-success-role-status**: Component MUST set `role="status"` on the success message container to indicate it is a status update.
- **title-fallback**: Component MUST display the provided `title` prop when supplied, and MUST fall back to `config.name` when it is not (`title ?? config?.name`); this is unconditional, not a soft preference.
- **description-fallback**: Component MUST display the provided `description` prop when supplied, and MUST fall back to `config.description` when it is not.
- **button-label-default**: Component MUST use the provided `buttonLabel` prop when supplied, and MUST default to "Sign up" when it is not.
- **success-message-default**: Component MUST use the provided `successMessage` prop when supplied, and MUST default to "Thanks for signing up! Check your inbox for a confirmation." when it is not.
- **collect-name-default**: Component MUST default `collectName` to `true` when the prop is not specified.
- **apply-classname**: Component MAY apply the provided className prop to the root element for styling customization.
- **handle-missing-min-age**: Component MAY handle backends that do not return minAgeMs by treating it as undefined and submitting without a nonce age delay.

## Appearance

- **Form spacing**: 12px vertical gap between sections (web: Tailwind `gap-3`)
- **Field spacing**: 4px vertical gap between label and input (web: Tailwind `gap-1`)
- **Border radius**: 6px on all inputs and buttons (web: Tailwind `rounded-md`)
- **Input padding**: 12px horizontal × 8px vertical on inputs (web: Tailwind `px-3 py-2`)
- **Button padding**: 16px horizontal × 8px vertical (web: Tailwind `px-4 py-2`)
- **Font size**: Form sections 14px, heading 18px (web: Tailwind `text-sm` / `text-lg`)
- **Font weight**: Heading 500 (medium), button 500 (medium)
- **Text color**: Primary text at full opacity against the host page's background; secondary text at 70% opacity on the description, 60% opacity on the footer disclosure
- **Border**: 1px solid, platform-default border color, on inputs and buttons
- **Disabled state opacity**: 50% on submit button when disabled (web: Tailwind `disabled:opacity-50`)
- **Loading text**: 14px, 60% opacity
- **Error text**: 14px, red (web: Tailwind `text-red-600`)

## States

| State | Appearance change |
|-------|------------------|
| Loading | Shows "Loading…" text at 60% opacity; no form |
| Ready | Full form visible with email and optional name fields; submit button enabled |
| Submitting | Submit button disabled and at 50% opacity; button text changes to "Signing up…"; aria-busy="true" |
| Done | Form hidden; success message displayed with focus |
| Closed | Message "{list name} is closed to new signups right now." (`config?.name ?? "This list"`: falls back to "This list" only when config.name is `null` or missing/`undefined`; an empty-string `config.name` renders as a blank subject, e.g. " is closed to new signups right now.") ; no form |
| Unavailable | Error message "Signups are unavailable right now." with a "Try again" button |

## Accessibility

- Role: The component itself does not have a role; it contains a `<form>` element which is implicitly a form.
- Labels: All form inputs (name, email) MUST have associated `<label>` elements; labels MUST NOT use placeholders in place of labels.
- Email validation: aria-invalid MUST be set to true when a validation error exists; aria-describedby MUST reference the error message.
- Error announcement: Error messages MUST have role="alert" so screen readers announce them when they appear. The alert element is only mounted once an error occurs — it is not present in the DOM beforehand — so some browser/screen-reader combinations may not announce it as reliably as a region that exists from the start.
- Success announcement: The success message MUST have role="status" and programmatic focus (via `tabIndex={-1}` on the container) to ensure announcement — see **focus-success-message**.
- Submit button state: aria-busy="true" MUST be set when submitting to indicate to screen readers the button is working.
- Honeypot: The honeypot input MUST be hidden from both visual and assistive tech via aria-hidden="true" and removed from tab order via tabIndex={-1}.
- Touch target: The input and button heights follow from the component's Tailwind padding (`py-2` plus `text-sm` line-height), which comes to roughly 36px — below the 44px WCAG 2.5.5 target size. See Compliance (`touch-target-size`, marked `failed`).
- Autofill: The honeypot field MUST opt out of password manager autofill using the exact per-vendor attributes `autoComplete="off"`, `data-form-type="other"`, `data-1p-ignore="true"`, `data-lpignore="true"`, `data-bwignore="true"`, and `data-protonpass-ignore="true"`.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| esf-001 | load-config-on-mount, show-loading-state | Mount component with valid publicKey and apiBaseUrl | Component displays "Loading…" text initially |
| esf-002 | parse-config-json, show-ready-state | Config fetch returns 200 with status "open" | Component renders form with email field and optional name field |
| esf-003 | timeout-config-request, show-unavailable-state | Config fetch hangs beyond 10,000ms | Component enters unavailable state and displays "Try again" button |
| esf-004 | handle-config-not-ok, show-unavailable-state | Config fetch returns 404 or 500 | Component enters unavailable state; console error logged with public key |
| esf-005 | show-closed-state | Config fetch returns 200 with status "closed" | Component displays "{list name} is closed to new signups right now." with no form |
| esf-006 | validate-email-locally, reject-invalid-email | User enters "notanemail" and clicks submit | The browser's native constraint validation (`type="email"`) blocks the `submit` event first and shows its own bubble ("Please include an '@' in the email address…"); the component's handler does not run and its "Enter a valid email address." message does not appear. The component's own check and message are exercised only by a value that passes native `type="email"` but fails the stricter local pattern (e.g. "a@b"), or by a submit that bypasses native validation |
| esf-007 | validate-email-locally | User enters "user@example.com" | Form passes validation check |
| esf-008 | trim-email-before-submit | User enters "  user@example.com  " | Email is trimmed before validation and submission |
| esf-009 | wait-for-nonce-age, add-timing-buffer | Config returned with minAgeMs 3000; user submits after 1000ms | Submission waits `(3000 - 1000) + 250` = 2250ms before sending |
| esf-010 | enter-submitting-state, mark-submit-disabled-during-submit | User clicks submit with valid email | Submit button becomes disabled and shows "Signing up…" text |
| esf-011 | post-submission, include-honeypot-in-post, include-source-url | User submits with email="test@example.com", name="Alice", honeypot="" | POST body contains email, name, nonce, website: "", sourceUrl |
| esf-012 | handle-submission-ok, show-success-message | POST returns 200 | Component enters done state and displays successMessage |
| esf-013 | focus-success-message | Submission succeeds | Success message container receives focus |
| esf-014 | handle-submission-error, suppress-server-error-details | POST returns 400 or 500 | Component displays generic error "Something went wrong. Please try again." (no status code shown) |
| esf-015 | return-to-ready-on-error | Submission fails | Component returns to ready state; form is visible and submit button is re-enabled |
| esf-016 | refresh-nonce-on-error | Submission fails and returns to ready | A new config fetch is initiated; nonce timestamp is updated |
| esf-017 | mark-email-invalid-on-validation-error | Validation error occurs | Email input has aria-invalid="true"; aria-describedby references error message |
| esf-018 | mark-email-invalid-on-validation-error | Form is valid or error is cleared | Email input has aria-invalid="false" |
| esf-019 | render-honeypot-hidden | Inspect DOM | Honeypot input has tabIndex=-1, aria-hidden="true", and CSS position: absolute; left: -9999px |
| esf-020 | use-unique-ids | Mount two instances on the same page | Each instance has distinct label-to-input associations; no duplicate IDs |
| esf-021 | collect-name-default | Mount component without collectName prop | Name field is rendered |
| esf-022 | apply-classname | Mount with className="custom-class" | Root element has the custom-class applied |
| esf-023 | title-fallback | Mount with title="Join our list" | Heading displays "Join our list" instead of config.name |
| esf-024 | button-label-default | Mount with buttonLabel="Subscribe" | Submit button displays "Subscribe" instead of "Sign up" |
| esf-025 | log-failures-to-console, log-with-prefix | Config fetch fails | Browser console contains error starting with "[EmailSignupForm]" and includes the public key |
| esf-026 | reject-malformed-config | Config fetch returns 200 with a body that is not valid JSON | Component logs the failure and enters the unavailable state |
| esf-027 | trim-name-before-submit | User enters "  Alice  " as name and submits | Name is trimmed to "Alice" before submission |
| esf-028 | set-name-autocomplete, set-email-autocomplete | Inspect DOM | Name input has autoComplete="name"; email input has autoComplete="email" |
| esf-029 | mark-error-alert | Validation error occurs | Error message element has role="alert" |
| esf-030 | handle-missing-min-age | Config returned without minAgeMs | Submission proceeds immediately with no nonce-age wait |
| esf-031 | include-source-url | Component renders during SSR (no `window`) | sourceUrl is omitted from the POST body; no exception is thrown |
| esf-032 | description-fallback | Mount with description="Custom description" | Description displays "Custom description" instead of config.description |
| esf-033 | success-message-default | Mount without successMessage prop | Success state displays the default "Thanks for signing up! Check your inbox for a confirmation." message |
| esf-034 | show-unavailable-state | Click "Try again" after config fetch fails | Phase returns to loading, and the config fetch is retried |

## Edge Cases

- **Empty or missing list name**: If the server returns `config.name` as `null` or an empty string and no `title` prop is supplied, the heading renders no text — an empty `<h3>` for `""`, nothing at all for `null` (React renders `null` as nothing). There is no fallback placeholder heading text in the component. `config.description` (or the `description` prop), if present, still renders normally underneath.
- **Multiple embeds on same page**: Each instance generates unique IDs via React.useId(); form submissions from one instance do not affect others.
- **Retry before the nonce refresh completes**: After a submission error, the phase returns to `ready` and the error message displays immediately — it is not held pending the follow-up config refresh, which continues in the background (see **refresh-nonce-on-error**). If the visitor clicks submit again before that refresh resolves, the retry proceeds using whichever nonce is currently held in state (the same one that just failed, unless the refresh has already landed); it clears the previous error and is a normal submission subject to the same nonce-age wait, and may itself fail and trigger another refresh.
- **Double submit**: The submit button is disabled (`disabled={busy}`) the instant the phase becomes `submitting`, and `submit()` independently returns immediately if `phase !== "ready"`. A rapid double-click therefore cannot send two POST requests; the second invocation is a no-op.
- **Nonce expiration mid-session**: If a tab remains open past the server's nonce lifetime — a backend-defined duration, referenced in source comments as `audience/nonce.ts` `MAX_AGE_MS`, but not a value this component hardcodes or depends on — a retry uses the stale nonce, the server rejects it, an error is shown, and a refresh fetches a new nonce. This MUST succeed; the visitor is not stuck.
- **Clock skew between client and server**: The nonce age is measured as a duration from the receive timestamp (Date.now()), not as a comparison between server and client clocks, so a visitor's skewed clock cannot shorten the required wait.
- **Extended form-fill delay**: A visitor who takes 8 seconds to fill the form before submitting will submit immediately upon clicking, with no additional wait. The required wait is `(minAgeMs − elapsed) + 250`ms whenever `minAgeMs − elapsed` is positive, and `0` otherwise; once the visitor's own form-filling time already exceeds `minAgeMs`, that difference is negative and the wait is `0`. This edge case is about elapsed time, not connection speed — nothing here depends on network quality.
- **Network failure during POST**: Any error during the POST (timeout, connection refused, non-2xx status) is treated identically: the component shows "Something went wrong" and returns to ready.
- **Honeypot-tripped submission**: Per the component's own source comments, the backend returns a uniform `200 OK` for a honeypot-tripped submission so the response is indistinguishable from a real success (`publicSignup.ts`: non-empty `website` ⇒ uniform 200, nothing written). The component therefore proceeds to the `done` phase and displays the success message exactly as it would for a legitimate signup — nothing on the page indicates that the submission was silently discarded.
- **Password manager autofilling honeypot**: The honeypot field has autofill opt-out properties; if a password manager ignores these and fills the field anyway, the server treats any non-empty value as a bot submission and silently rejects it.
- **Validation error persists until the next submit**: Editing the email field after a validation error does not itself clear the error — `error` is only reset to `null` inside `submit()`, at the point a resubmission passes local validation. The message and the `aria-invalid`/`aria-describedby` state therefore remain on screen while the visitor is still typing, until they submit again.
- **Success message persists until unmount**: Once the component enters the done state, it displays only the success message. The component does NOT automatically reset or navigate; the parent is responsible for removing or replacing the component.
- **Empty email field**: The email input is `required` and `type="email"`, and the `<form>` has no `noValidate`, so a real user click on submit with the field empty is intercepted by the browser's own native constraint validation before the `submit` event fires: the browser shows its own message ("Please fill out this field."), the component's `submit()` handler never runs, and no `aria-invalid`/`aria-describedby`/`role="alert"` state appears. The component's own "Enter a valid email address." message only appears for a submit that bypasses native validation (a synthetic/programmatic `submit` event — the sole route the test suite exercises) or for input that passes the browser's `type="email"` check but fails the component's own stricter pattern (e.g. "a@b").

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| publicKey | string | (required) | The list's public key from the hub's Embed panel. Must match a key on the backend. |
| apiBaseUrl | string | (required) | The base URL of the two public endpoints, with no trailing slash. May be an absolute origin (https://api.example.com) or a relative path (/api). |
| title | string | undefined (uses config.name) | Overrides the list name displayed as the form heading. |
| description | string | undefined (uses config.description) | Overrides the list description displayed below the heading. |
| buttonLabel | string | "Sign up" | Overrides the submit button text. |
| successMessage | string | "Thanks for signing up! Check your inbox for a confirmation." | Overrides the success state message. |
| collectName | boolean | true | Whether to render a name input field. |
| className | string | undefined | Custom CSS class names to apply to the root element. |

## Deep Linking

Not applicable: Email Signup Form is an embedded component within a page, not a top-level destination with its own URL scheme or deep-link pattern.

## Localization

Not fully externalized. `title`, `description`, `buttonLabel`, and `successMessage` are overridable via props, so a consuming app can localize those four strings. Every other user-facing string is a hardcoded English literal with no override mechanism: "Loading…", "Enter a valid email address.", "Something went wrong. Please try again.", "Signups are unavailable right now.", "Try again", "Email address", "Name", "Signing up…", and the footer disclosure "We'll only email you about this. Unsubscribe any time." See Compliance (`string-externalization`, `no-hardcoded-strings`).

## Accessibility Options

Document which accessibility display options (Rule 15) this component responds to:

| Option | Behavior |
|--------|----------|
| Reduce Motion | Not applicable — the component has no animations or motion effects to reduce. |
| Increase Contrast | Not implemented. The disabled submit button relies on a fixed 50% opacity reduction (`disabled:opacity-50`) regardless of the system's increase-contrast setting; there is no dedicated high-contrast styling path. |
| Differentiate Without Color | Largely satisfied incidentally: the error state is conveyed through message text (not color alone) plus `role="alert"` and `aria-invalid`, so a visitor who cannot perceive the red (`text-red-600`) still reads the same words. There is no separate color-only indicator, such as a border-color-only invalid state, that would fail if color were removed. |

## Feature Flags

Not applicable: The component itself contains no internal feature flags. The backend may gate the feature via the ecosystem's email-signup flag (referenced in the source comments), but this is not exposed to the component.

## Analytics

Not applicable: the component emits no analytics events and exposes no `onSuccess`/`onError` (or any other) callback props. A parent application wanting telemetry has no hook into this version of the component beyond observing the rendered DOM from outside.

## Privacy

- **Data collected**: Email address (required), name (optional, if collectName is true), page URL (sourceUrl).
- **Storage**: The component does not store data locally. Data is transmitted to the backend immediately upon submission.
- **Transmission**: Email, name, and sourceUrl are transmitted in a POST body via HTTP/HTTPS to the backend endpoint. The request includes the signed nonce for anti-abuse verification.
- **Retention**: Retention is determined by the backend list configuration and the hub. The component has no control over retention.
- **Honeypot**: The honeypot field's value is always sent to the backend as `website` — empty for a legitimate visitor, non-empty only if something else (a bot, or a password manager that ignored the opt-out) filled it in. The server's anti-abuse gate treats any non-empty value as a bot signal and silently rejects the submission without writing it; an empty value is never treated as suspicious.

## Logging

Subsystem: Application console (developer-facing only)

| Event | Level | Message Format |
|-------|-------|-----------------|
| Config load failure | error | `[EmailSignupForm] could not load the signup list for public key "{publicKey}": {reason}` |
| Config refresh failure | error | `[EmailSignupForm] could not refresh the signup nonce for public key "{publicKey}": {reason}` |

## Platform Notes

- **React/Web**: The component is a functional React component using hooks (`useState`, `useRef`, `useCallback`, `useEffect`, `useId`) — it uses no React context. Styling is applied via Tailwind CSS utility classes; applications must have Tailwind configured. The component does not depend on any external UI library (buttons and inputs are bare HTML elements with CSS classes). It uses the `cn` utility (`clsx` + `tailwind-merge`, merging conditional Tailwind classes) and opts the honeypot out of autofill with the exact attributes `autocomplete="off"`, `data-form-type="other"`, `data-1p-ignore="true"`, `data-lpignore="true"`, `data-bwignore="true"`, and `data-protonpass-ignore="true"`. Source: `packages/web/packages/ui/src/components/email-signup-form.tsx`.
- **SwiftUI**: Start from a `Form` container with `TextField` for email and optional name input. SwiftUI's async/await patterns replace the useEffect-based config fetching; use `Task` in `.onAppear`. Replace phase states with an `@State` property. Implement the honeypot as a hidden `TextField` with `.hidden()`. Render the heading as a plain `Text` styled with `.font(.headline)` inside the form — not `.navigationTitle`, which addresses the enclosing screen's navigation bar, not an embedded form heading. Handle the 10-second timeout using `URLSession` with `.timeoutInterval`. `sourceUrl` has no direct SwiftUI equivalent; substitute whatever the host app uses to identify the current screen (a route name or deep-link path), or omit the field. A DOM-crawling honeypot has no native analog — bots don't walk a `View` tree the way they walk HTML — so this defense is better dropped on this platform in favor of the nonce-age check alone.
- **Compose**: Use `Box` or `Column` for layout with `spacedBy = 12.dp`. Replace phase states with `MutableState` or ViewModel-backed state. Implement email validation with the same regex (`EMAIL_RE`). Use `TextField` for email/name inputs and `Button` for submit — there is no `BasicButton` in Compose. The honeypot is a `TextField` conditionally excluded from the composable tree rather than `.hidden()`. Handle async config fetch and POST with coroutines in a `ViewModel` or `LaunchedEffect`. Substitute a host-supplied route/screen identifier for `sourceUrl`; as with SwiftUI, the honeypot pattern does not translate to a non-DOM UI and should be dropped in favor of nonce aging alone.
- **AppKit / UIKit**: Use `NSStackView` (AppKit) or `UIStackView` (UIKit) for layout — not `NSForm`, which is deprecated. Replace React state management with properties and delegation (`UITextFieldDelegate`, `URLSessionDelegate`). Implement the loading state with `NSProgressIndicator` (AppKit) or `UIActivityIndicatorView` (UIKit). The honeypot is a hidden `NSTextField` / `UITextField` with `.isHidden = true`, positioned off-screen or given zero size. Use `URLSession` for config and submission fetches with a 10-second timeout. Substitute a host-supplied identifier for `sourceUrl`; the DOM honeypot has no native equivalent and should be dropped in favor of nonce aging alone.
- **WinUI 3**: Use `StackPanel` with `Spacing="12"` for the form container. Use `TextBox` for email and name fields, bound to ViewModel properties via data binding. Implement phase states with a `VisualStateManager` that swaps visibility of form vs. loading vs. error states — not a `Pivot`'s `SelectedIndex`, which is for user-navigable tabs, not internal phase switching. Use `Button` for submit with a binding to an `ICommand` that handles submission. The honeypot is a `TextBox` with `Visibility="Collapsed"`. Handle async config and POST via `HttpClient` with `Timeout = TimeSpan.FromSeconds(10)`. Implement the nonce-age wait with `Task.Delay`. Validation errors are shown as `TextBlock` elements bound to the error state. Substitute a host-supplied identifier for `sourceUrl`; the DOM honeypot has no native equivalent and should be dropped in favor of nonce aging alone.

## Design Decisions

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
**Rationale**: Those reasons describe the anti-abuse gate, and leaking which defense tripped is an attack surface. Developers see the real error in the console; visitors see only "Something went wrong."
**Approved**: pending

**Silent Config Refresh on Submission Error**
**Decision**: A failed submission does not surface a second error to the visitor; instead, it silently refreshes the nonce.
**Rationale**: If the refresh itself fails, the visitor still has the form, and retrying (with a stale nonce) is still better than showing a dead end. This trades silent nonce staleness for a form that remains usable.
**Approved**: pending

**Honeypot over CSRF Tokens**
**Decision**: The component uses a honeypot (a form field invisible to humans) rather than CSRF token validation.
**Rationale**: CSRF tokens require a shared session or state between the page and backend. A public endpoint has no session, so a honeypot is the only bot defense available at this layer (the server layer separately enforces nonce aging and IP rate limits).
**Approved**: pending

**sourceUrl Captures window.location.href**
**Decision**: The POST body's `sourceUrl` field is `window.location.href` (undefined during SSR).
**Rationale**: The backend stores this as the consent record's provenance, proving the address opted in at this specific page. This is necessary for compliance and dispute resolution.
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

## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | failed | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | passed | Accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | passed | Accessibility |
| [input-sanitization](agenticdevelopercookbook://compliance/security#input-sanitization) | partial | Security |
| [secure-transport](agenticdevelopercookbook://compliance/security#secure-transport) | partial | Security |
| [secure-log-output](agenticdevelopercookbook://compliance/security#secure-log-output) | passed | Security |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy and Data |
| [consent-before-collection](agenticdevelopercookbook://compliance/privacy-and-data#consent-before-collection) | passed | Privacy and Data |
| [no-pii-in-logs](agenticdevelopercookbook://compliance/privacy-and-data#no-pii-in-logs) | passed | Privacy and Data |
| [data-retention-policy](agenticdevelopercookbook://compliance/privacy-and-data#data-retention-policy) | failed | Privacy and Data |
| [third-party-disclosure](agenticdevelopercookbook://compliance/privacy-and-data#third-party-disclosure) | partial | Privacy and Data |
| [abuse-prevention](agenticdevelopercookbook://compliance/user-safety#abuse-prevention) | passed | User Safety |
| [safe-defaults](agenticdevelopercookbook://compliance/user-safety#safe-defaults) | passed | User Safety |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | partial | Internationalization |
| [text-expansion-tolerance](agenticdevelopercookbook://compliance/internationalization#text-expansion-tolerance) | passed | Internationalization |
| [unicode-support](agenticdevelopercookbook://compliance/internationalization#unicode-support) | passed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

Statuses rest on the component source (`email-signup-form.tsx`) and its `lib/autofill.ts` / `lib/utils.ts` helpers: what the source directly shows — Tailwind class output, ARIA attributes, `console.error` calls, the trim/regex logic, the absence of any callback props — is marked `passed` or `failed`; anything that depends on the host page or the backend (background color and root font size for contrast/dynamic-type, the TLS scheme of `apiBaseUrl`, retention policy owned by the hub) is marked `partial` or, where the component plainly does nothing about it (retention, string externalization), `failed`. `separation-of-concerns` is `passed` because the nonce/timing/submission state machine is isolated in named helpers and effects rather than tangled into the JSX; `unit-test-coverage` is `passed` because `emailSignupForm.test.tsx` renders `EmailSignupForm` directly and exercises its phases with meaningful assertions.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Mike Fullerton | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only names and reconsidered should-/may- keywords on merits; corrected Compliance statuses/links and expanded categories beyond Accessibility; reformatted Design Decisions into Decision/Rationale/Approved blocks; fixed Appearance measurements and made them platform-neutral; corrected Platform Notes APIs (SwiftUI heading, Compose button, AppKit/UIKit form, WinUI 3 phase switching) and added sourceUrl/honeypot native guidance; resolved Closed-state, Privacy, and timing-buffer internal contradictions; rewrote garbled edge cases and added missing ones (double submit, retry during refresh, honeypot-tripped success); filled frontmatter references and Accessibility Options; added missing test vectors. |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Documented native constraint validation gating real user submits (empty/invalid email never reaches the component check); fixed Closed-state ?? fallback to note it misses empty-string names. Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: passed). |
