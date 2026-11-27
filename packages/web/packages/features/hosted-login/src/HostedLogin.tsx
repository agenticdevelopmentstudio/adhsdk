import type { ReactElement } from "react";
import { fetchHostedLoginContext, type HostedLoginContext } from "./loginContext";

/** The hosted login page's query string, as Hydra and the backend's redirects set it. */
export interface HostedLoginParams {
  login_challenge?: string;
  error?: string;
  mfa?: string;
  mfa_token?: string;
  mode?: string;
  verify?: string;
  verify_token?: string;
  code_sent?: string;
}

/**
 * Map the backend's `error` markers to user copy. Unknown → a generic fallback — this
 * page must never render a raw code.
 *
 * `signup_closed` / `invite_required` / `email_taken` / `weak_password` / `invalid_email`
 * / `social_signin_failed` are the customer-realm sign-up/sign-in refusals
 * (customerSignup.ts `CustomerSignupError` / `LoginPageError`); `email_taken` also gets a
 * "Sign in instead" link rendered alongside it below, since that refusal means an
 * account already exists.
 */
const ERROR_MESSAGES: Record<string, string> = {
  invalid_credentials: "Invalid email/username or password.",
  login_disabled: "Sign-in is currently limited to administrators. Please check back soon.",
  invalid_code: "That code didn’t match. Try again.",
  mfa_expired: "Your sign-in session expired. Please start again.",
  too_many_attempts: "Too many attempts. Please wait a few minutes and try again.",
  signup_closed: "Sign-up is closed for this app right now. Please check back later.",
  invite_required: "This app is invite-only. Ask whoever invited you for an invitation link.",
  email_taken: "An account with that email already exists.",
  weak_password: "Choose a stronger password (at least 8 characters).",
  invalid_email: "Enter a valid email address.",
  social_signin_failed: "That sign-in method didn’t work. Please try again or use email and password.",
  password_disabled: "Email and password sign-in isn't available for this app. Use another sign-in method.",
  // The sign-up email code step (provider.ts `/signup/verify` and `/signup/verify/send`).
  verify_code_invalid: "That code didn’t match. Check the email and try again.",
  verify_code_expired: "That code has expired. Send a new one.",
  verify_rate_limited: "Too many codes sent. Please wait a few minutes, then send a new one.",
  verify_send_failed: "We couldn’t send the code. Try sending a new one.",
};

// The code step's subhead. The backend sets `code_sent` only when a code went out on this
// redirect; without it, the copy follows why: a send that failed or a code that expired leaves
// nothing to enter, so it asks for a new one, while a wrong code or a rate-limited resend
// leaves the code already sent live.
function verifySubhead(codeSent: string | undefined, error: string | undefined): string {
  if (codeSent === "1") return "We sent a code to the address you signed up with. Enter it to finish.";
  if (error === "verify_send_failed" || error === "verify_code_expired") {
    return "Send a new code to the address you signed up with, then enter it here.";
  }
  return "Enter the code we sent to the address you signed up with.";
}

// The factors completable by typing a code in this server-rendered flow (a passkey
// needs a browser ceremony, so it isn't offered here — passkey users sign in at the hub).
const CODE_METHOD_LABELS: Record<string, string> = {
  totp: "Authenticator app",
  sms: "Text message",
  recovery: "Recovery code",
};

function codeMethods(mfa: string | undefined): string[] {
  // A Set keeps the first-seen order and drops repeats: `mfa=totp,totp` is one radio, not two
  // sharing a React key.
  return [
    ...new Set(
      (mfa ?? "")
        .split(",")
        .map((m) => m.trim())
        // Own keys only: `in` would also pass `__proto__`, `constructor` and the rest of
        // Object.prototype, which a crafted `?mfa=` could name.
        .filter((m) => Object.hasOwn(CODE_METHOD_LABELS, m)),
    ),
  ];
}

/** The card for a sign-in link that reached the page without a `login_challenge`. */
export function MissingChallengeCard(): ReactElement {
  return (
    <div className="auth-card">
      <h1 className="auth-card__heading">Sign in</h1>
      <p className="auth-card__subhead">
        This sign-in link is missing or has expired. Start again from the app you
        were signing in to.
      </p>
    </div>
  );
}

/**
 * Login page for the Ory Hydra authorization-server flow — the ONLY user-facing
 * artifact of that flow, served by the frontend (the backend renders nothing).
 *
 * Flow: Hydra redirects an anonymous browser to the backend's GET /auth/oidc/login,
 * which resolves the challenge against Hydra's private admin API and 302s here with
 * a `login_challenge`. This native form POSTs the credentials straight back to the
 * backend's POST /auth/oidc/login — a top-level navigation (no CORS, no client JS) —
 * which verifies them against the request's realm (platform `auth.users` or a
 * per-ecosystem `customer.*`) and tells Hydra to proceed. When the account has a
 * second factor, the backend 303s back here with `mfa`/`mfa_token` and this page
 * renders the OTP step (which POSTs to /auth/oidc/login/mfa). On a bad attempt the
 * backend 303s back here with `?error=…`. The `login_challenge` is Hydra's own
 * anti-CSRF token; the backend rejects any POST that lacks it.
 *
 * CUSTOMER REALM (client-auth): before rendering, this page asks the backend's GET
 * /auth/oidc/login/context which realm this challenge's client belongs to. A hub-realm
 * answer (or a failed/unreachable context call) renders exactly the plain form above.
 * A customer-realm answer additionally may offer social providers — each a link
 * straight to the backend's /oauth/signin/start, never client JS — and, when the
 * ecosystem's sign-up policy allows it, a "Create account" link into `?mode=signup`:
 * a second, still-native form that POSTs to the backend's POST /auth/oidc/signup. A
 * customer-realm answer with `loginEnabled: false` (e.g. a suspended ecosystem) skips
 * both forms entirely and shows the `login_disabled` copy up front instead — there is
 * no point rendering a form the backend will only refuse.
 *
 * SIGN-UP EMAIL CODE (phase 5): while the ecosystem's `customer_email_verification` switch is
 * on, a new password account must prove its address before sign-in completes. The backend 303s
 * back here with `verify=1`, a signed `verify_token` and `code_sent` when the code went out;
 * this page renders a code form that POSTs to /auth/oidc/signup/verify, and a resend form that
 * POSTs to /auth/oidc/signup/verify/send. Neither carries the address: the token names it.
 */
export async function HostedLogin({
  backendUrl,
  params,
  context,
}: {
  /** The backend the forms post to and the context is read from. */
  backendUrl: string;
  params: HostedLoginParams;
  /** Omitted: the component fetches it itself, after the MFA and code steps, as today. */
  context?: HostedLoginContext | null;
}): Promise<ReactElement> {
  // The backend names it `mfa_token` (loginPage.ts `loginUiUrl`), the same as the form field;
  // likewise `verify_token`.
  const {
    login_challenge: challenge,
    error,
    mfa,
    mfa_token: mfaToken,
    mode,
    verify,
    verify_token: verifyToken,
    code_sent: codeSent,
  } = params;

  if (!challenge) {
    // Reached without a challenge: the flow was entered out of band (Hydra always
    // supplies one). Nothing to sign into, so don't render a form that can't submit.
    return <MissingChallengeCard />;
  }

  // Own keys only: a bare index would hand `?error=__proto__` Object.prototype (React then
  // throws rendering it) and `?error=constructor` a function (an empty alert).
  const errorMessage = error
    ? ((Object.hasOwn(ERROR_MESSAGES, error) ? ERROR_MESSAGES[error] : undefined) ??
      "Sign in failed. Please try again.")
    : null;

  // Second-factor step: the backend challenged this account and bounced back with a
  // pending token + the available methods.
  if (mfaToken) {
    const methods = codeMethods(mfa);
    return (
      <div className="auth-card">
        <h1 className="auth-card__heading">Two-factor authentication</h1>
        <p className="auth-card__subhead">Confirm it’s you with your second factor.</p>

        {errorMessage && (
          <div className="auth-card__error" role="alert">
            {errorMessage}
          </div>
        )}

        {methods.length === 0 ? (
          <p className="auth-card__mfa-hint">
            Your account uses a passkey. Sign in at{" "}
            <a href="https://agenticdeveloperhub.com/login">agenticdeveloperhub.com</a> to
            continue.
          </p>
        ) : (
          <form
            method="post"
            action={`${backendUrl}/auth/oidc/login/mfa`}
            className="auth-card__form"
          >
            <input type="hidden" name="login_challenge" value={challenge} />
            <input type="hidden" name="mfa_token" value={mfaToken} />

            {methods.length > 1 && (
              <fieldset className="auth-card__field">
                <legend className="auth-card__label">Verify with</legend>
                {methods.map((m, i) => (
                  <label key={m} className="auth-card__mfa-radio">
                    <input type="radio" name="method" value={m} defaultChecked={i === 0} />
                    {CODE_METHOD_LABELS[m]}
                  </label>
                ))}
              </fieldset>
            )}
            {methods.length === 1 && (
              <input type="hidden" name="method" value={methods[0]} />
            )}

            <div className="auth-card__field">
              <label htmlFor="code" className="auth-card__label">
                Verification code
              </label>
              <input
                id="code"
                name="code"
                type="text"
                inputMode="numeric"
                autoComplete="one-time-code"
                required
                className="auth-card__input"
              />
            </div>
            <button type="submit" className="auth-card__submit">
              Verify
            </button>
          </form>
        )}

        {methods.includes("sms") && (
          <form
            method="post"
            action={`${backendUrl}/auth/oidc/login/mfa/send`}
            className="auth-card__mfa-resend"
          >
            <input type="hidden" name="login_challenge" value={challenge} />
            <input type="hidden" name="mfa_token" value={mfaToken} />
            <button type="submit" className="auth-card__mfa-link">
              Resend SMS code
            </button>
          </form>
        )}
      </div>
    );
  }

  // Sign-up email code step: the new account must prove its address before sign-in completes.
  if (verify === "1" && verifyToken) {
    return (
      <div className="auth-card">
        <h1 className="auth-card__heading">Check your email</h1>
        <p className="auth-card__subhead">
          {verifySubhead(codeSent, error)}
        </p>

        {errorMessage && (
          <div className="auth-card__error" role="alert">
            {errorMessage}
          </div>
        )}

        <form
          method="post"
          action={`${backendUrl}/auth/oidc/signup/verify`}
          className="auth-card__form"
        >
          <input type="hidden" name="login_challenge" value={challenge} />
          <input type="hidden" name="verify_token" value={verifyToken} />
          <div className="auth-card__field">
            <label htmlFor="verify-code" className="auth-card__label">
              Code
            </label>
            <input
              id="verify-code"
              name="code"
              type="text"
              inputMode="numeric"
              autoComplete="one-time-code"
              required
              className="auth-card__input"
            />
          </div>
          <button type="submit" className="auth-card__submit">
            Verify
          </button>
        </form>

        <form
          method="post"
          action={`${backendUrl}/auth/oidc/signup/verify/send`}
          className="auth-card__mfa-resend"
        >
          <input type="hidden" name="login_challenge" value={challenge} />
          <input type="hidden" name="verify_token" value={verifyToken} />
          <button type="submit" className="auth-card__mfa-link">
            Send a new code
          </button>
        </form>
      </div>
    );
  }

  // A convenience call, never load-bearing: null (network error, non-2xx, or an
  // unreachable backend) falls back to the plain, realm-agnostic form below — exactly
  // today's hub-realm rendering.
  // A caller that already read the context (the product site) passes it; the hub passes none.
  context = context === undefined ? await fetchHostedLoginContext(backendUrl, challenge) : context;
  // Narrowed once so the fields below don't each re-litigate `context`'s nullability.
  const customer = context?.realm === "customer" ? context : null;
  const clientSlug = customer?.clientSlug ?? null;
  const clientName = customer?.clientName ?? null;
  const providers = clientSlug ? (customer?.providers ?? []) : [];
  // With email + password off the realm signs in only through its providers: no password
  // form, and no sign-up form either, since that form creates a password account.
  const passwordEnabled = customer?.passwordEnabled ?? true;
  // Invite-only still shows the link — the backend enforces the invite when the form
  // is submitted; only a fully closed ecosystem hides it.
  const canSignup = customer !== null && customer.signupMode !== "closed" && passwordEnabled;

  // A customer realm can resolve the challenge while sign-in is disabled entirely
  // (e.g. a suspended ecosystem) — rendering the ordinary form would only earn a
  // refusal on submit, so show the existing "sign-in disabled" copy up front instead.
  if (customer && (!customer.loginEnabled || (!passwordEnabled && providers.length === 0))) {
    return (
      <div className="auth-card">
        <h1 className="auth-card__heading">
          {clientName ? `Sign in to ${clientName}` : "Sign in"}
        </h1>
        <div className="auth-card__error" role="alert">
          {customer.loginEnabled ? ERROR_MESSAGES.password_disabled : ERROR_MESSAGES.login_disabled}
        </div>
      </div>
    );
  }

  const wantsSignup = canSignup && mode === "signup";

  // "Sign in instead" (email_taken) and the signup form's own "Sign in" link both
  // return to this same page's plain sign-in view, carrying the same challenge.
  const signInHref = `?login_challenge=${encodeURIComponent(challenge)}`;
  const signupHref = `?login_challenge=${encodeURIComponent(challenge)}&mode=signup`;

  const errorBanner = errorMessage && (
    <div className="auth-card__error" role="alert">
      {errorMessage}
      {error === "email_taken" && (
        <>
          {" "}
          <a href={signInHref} className="auth-card__signup-link">
            Sign in instead
          </a>
        </>
      )}
    </div>
  );

  if (wantsSignup) {
    return (
      <div className="auth-card">
        <h1 className="auth-card__heading">
          {clientName ? `Create your ${clientName} account` : "Create account"}
        </h1>
        <p className="auth-card__subhead">Create an account to continue</p>

        <form
          method="post"
          action={`${backendUrl}/auth/oidc/signup`}
          className="auth-card__form"
        >
          {errorBanner}
          <input type="hidden" name="login_challenge" value={challenge} />
          <div className="auth-card__field">
            <label htmlFor="name" className="auth-card__label">
              Name
            </label>
            <input
              id="name"
              name="name"
              type="text"
              autoComplete="name"
              className="auth-card__input"
            />
          </div>
          <div className="auth-card__field">
            <label htmlFor="email" className="auth-card__label">
              Email
            </label>
            <input
              id="email"
              name="email"
              type="email"
              autoComplete="email"
              required
              className="auth-card__input"
            />
          </div>
          <div className="auth-card__field">
            <label htmlFor="password" className="auth-card__label">
              Password
            </label>
            <input
              id="password"
              name="password"
              type="password"
              autoComplete="new-password"
              required
              className="auth-card__input"
            />
          </div>
          <button type="submit" className="auth-card__submit">
            Create account
          </button>
        </form>

        <p className="auth-card__signup">
          Already have an account?{" "}
          <a href={signInHref} className="auth-card__signup-link">
            Sign in
          </a>
        </p>
      </div>
    );
  }

  return (
    <div className="auth-card">
      <h1 className="auth-card__heading">
        {clientName ? `Sign in to ${clientName}` : "Sign in"}
      </h1>
      <p className="auth-card__subhead">Continue to your account</p>

      {/* `clientSlug &&` narrows it to `string` for the href below — providers is only
          ever non-empty when clientSlug is non-null (see its derivation above), so this
          also documents that invariant at the one place it's relied on. */}
      {clientSlug && providers.length > 0 && (
        <>
          <div className="auth-card__providers">
            {providers.map((p) => (
              <a
                key={p.slug}
                href={`${backendUrl}/oauth/signin/start?clientId=${encodeURIComponent(clientSlug)}&providerId=${encodeURIComponent(p.slug)}&login_challenge=${encodeURIComponent(challenge)}`}
                className="auth-card__provider-btn"
              >
                Continue with {p.name}
              </a>
            ))}
          </div>

          {passwordEnabled && (
            <div className="auth-card__divider">
              <span className="auth-card__divider-line" />
              <span className="auth-card__divider-text">or</span>
              <span className="auth-card__divider-line" />
            </div>
          )}
        </>
      )}

      {!passwordEnabled && errorBanner}
      {passwordEnabled && (
      <form
        method="post"
        action={`${backendUrl}/auth/oidc/login`}
        className="auth-card__form"
      >
        {errorBanner}
        <input type="hidden" name="login_challenge" value={challenge} />
        <div className="auth-card__field">
          <label htmlFor="identifier" className="auth-card__label">
            Email or username
          </label>
          <input
            id="identifier"
            name="identifier"
            type="text"
            autoComplete="username"
            required
            className="auth-card__input"
          />
        </div>
        <div className="auth-card__field">
          <label htmlFor="password" className="auth-card__label">
            Password
          </label>
          <input
            id="password"
            name="password"
            type="password"
            autoComplete="current-password"
            required
            className="auth-card__input"
          />
        </div>
        <button type="submit" className="auth-card__submit">
          Sign in
        </button>
      </form>
      )}

      {canSignup && (
        <p className="auth-card__signup">
          Don’t have an account?{" "}
          <a href={signupHref} className="auth-card__signup-link">
            Create account
          </a>
        </p>
      )}
    </div>
  );
}
