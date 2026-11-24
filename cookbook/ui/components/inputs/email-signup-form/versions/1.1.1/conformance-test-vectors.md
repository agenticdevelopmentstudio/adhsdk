
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

