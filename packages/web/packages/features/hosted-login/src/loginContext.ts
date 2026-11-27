/** The customer realm's sign-up policy, as the backend's ecosystem auth settings name it. */
export type HostedLoginSignupMode = "open" | "invite_only" | "closed";

/** One social provider the hosted login page may offer for this sign-in app. */
export interface HostedLoginProvider {
  slug: string;
  name: string;
}

/**
 * What `GET /auth/oidc/login/context` answers — everything the hosted login page
 * (HostedLogin.tsx) needs to draw itself for the challenge's realm.
 * Mirrors the backend's `LoginContext` (src/auth/hydra/provider.ts): hub realm always
 * answers `clientSlug: null` and `providers: []`.
 */
export interface HostedLoginContext {
  realm: "hub" | "customer";
  /** null for the hub; the customer realm's ecosystem id. */
  ecosystemId: string | null;
  clientSlug: string | null;
  clientName: string | null;
  ecosystemName: string | null;
  loginEnabled: boolean;
  /** False when the realm has email + password sign-in switched off: the page offers only
   *  its providers, and neither the password form nor the (password) sign-up form. */
  passwordEnabled: boolean;
  signupMode: HostedLoginSignupMode;
  providers: HostedLoginProvider[];
}

const SIGNUP_MODES: readonly string[] = ["open", "invite_only", "closed"] satisfies HostedLoginSignupMode[];

function isStringOrNull(v: unknown): v is string | null {
  return v === null || typeof v === "string";
}

function isProvider(v: unknown): v is HostedLoginProvider {
  if (typeof v !== "object" || v === null) return false;
  const p = v as Record<string, unknown>;
  return typeof p.slug === "string" && typeof p.name === "string";
}

/**
 * Whether a parsed `login/context` body has the {@link HostedLoginContext} shape. The page
 * trusts every field it reads — `providers.map`, a `loginEnabled` that gates the whole form — so
 * a body that is JSON but not this shape (a proxy's error page, a backend from another version)
 * must count as no context at all, not be cast and read.
 */
export function isHostedLoginContext(v: unknown): v is HostedLoginContext {
  if (typeof v !== "object" || v === null) return false;
  const c = v as Record<string, unknown>;
  return (
    (c.realm === "hub" || c.realm === "customer") &&
    isStringOrNull(c.ecosystemId) &&
    isStringOrNull(c.clientSlug) &&
    isStringOrNull(c.clientName) &&
    isStringOrNull(c.ecosystemName) &&
    typeof c.loginEnabled === "boolean" &&
    typeof c.passwordEnabled === "boolean" &&
    typeof c.signupMode === "string" &&
    SIGNUP_MODES.includes(c.signupMode) &&
    Array.isArray(c.providers) &&
    c.providers.every(isProvider)
  );
}

/** `url` without its trailing slashes, so a base written as `https://api.example.com/` builds
 *  `https://api.example.com/auth/...`, never `//auth/...`. Every backend URL this package builds
 *  goes through it. */
export function trimTrailingSlashes(url: string): string {
  return url.replace(/\/+$/, "");
}

/**
 * Fetch the login context for a Hydra `login_challenge`, server-side (this is a Node
 * fetch from the page's Server Component, not a browser call), from the backend at
 * `backendUrl`.
 *
 * Returns `null` on ANY failure — a network error, a non-2xx, an unparseable body, a body
 * that isn't a {@link HostedLoginContext} (see {@link isHostedLoginContext}), or the 3s
 * timeout below — and NEVER throws. The page's fallback for `null` is today's
 * plain, realm-agnostic form: this context call is a convenience (social buttons, the
 * "Create account" link, the "Sign in to <App>" heading), not something the login
 * page's core function (submitting credentials to the backend with the challenge) can
 * depend on. A hosted login page that goes down because this one extra call failed —
 * or hung — would be a strictly worse outcome than one that just shows fewer buttons.
 * The timeout exists for exactly that "hung" case: without it, a backend that accepts
 * the connection but never answers blocks this Server Component's render indefinitely,
 * taking the whole login page down with it.
 */
export async function fetchHostedLoginContext(
  backendUrl: string,
  challenge: string,
): Promise<HostedLoginContext | null> {
  try {
    const res = await fetch(
      `${trimTrailingSlashes(backendUrl)}/auth/oidc/login/context?login_challenge=${encodeURIComponent(challenge)}`,
      { cache: "no-store", signal: AbortSignal.timeout(3000) },
    );
    if (!res.ok) return null;
    const body: unknown = await res.json();
    return isHostedLoginContext(body) ? body : null;
  } catch {
    // Covers a network error, a timeout abort, and a non-JSON body alike.
    return null;
  }
}
