// The pure half of client auth editing, which the ecosystem's Settings pane and an application's
// client auth section share. It covers the draft shapes, what counts as a change, what a save
// sends, what a platform allows, how a provider switch maps onto `allowedProviders`, and how the
// login allow-list is cleaned and bounded.

import type {
  ApplicationPlatform,
  AuthProviderChoice,
  ClientAuthPolicy,
  LoginRegistration,
  LoginRegistrationInput,
} from "@adh-sdk/data/ecosystem-config";

/** The editable half of a login registration. The client id is the server's and is not edited. */
export type RegistrationDraft = LoginRegistrationInput;

/** A registration as its editor starts it: no rows yet, which the editor draws as "add one". */
export function registrationToDraft(r: LoginRegistration | null): RegistrationDraft | null {
  return r ? { allowedReturnOrigins: r.allowedReturnOrigins, redirectUris: r.redirectUris } : null;
}

/** A NEW registration's draft: one blank row to type into. A native app has no return origins,
 *  so its row is a redirect URI. */
export function blankRegistration(platform?: ApplicationPlatform): RegistrationDraft {
  return platform === "native"
    ? { allowedReturnOrigins: [], redirectUris: [""] }
    : { allowedReturnOrigins: [""], redirectUris: [] };
}

/** Plain `http:` is allowed only on these hosts (RFC 8252 §7.3), as the backend has it. */
const LOOPBACK_HOSTS = new Set(["localhost", "127.0.0.1", "[::1]"]);
/** The backend's bounds and custom-scheme rules (auth/hydra/signinAppClient.ts,
 *  auth/clientRegistration.ts), mirrored so Save is refused before the round trip. */
const MAX_REDIRECT_URIS = 20;
const MAX_RETURN_ORIGINS = 20;
const FORBIDDEN_CUSTOM_SCHEMES = new Set([
  "http",
  "https",
  "javascript",
  "data",
  "file",
  "vbscript",
  "blob",
  "about",
  "ws",
  "wss",
  "ftp",
]);
const CUSTOM_SCHEME_RE = /^[a-z][a-z0-9+.-]*$/;
// eslint-disable-next-line no-control-regex -- matching control chars is the point
const WHITESPACE_OR_CONTROL_RE = /[\s\x00-\x1f\x7f]/;

/**
 * Canonicalize a return origin to `new URL(o).origin`: the host lowercased, the default port
 * dropped, and no path. That is what the backend stores, and the backend is authoritative for
 * the canonical form. Sending the shape the server persists prevents an "origin saved but sign-in
 * 400s" mismatch. Input that cannot be parsed falls back to the trimmed text, and
 * {@link registrationError} refuses it before a save ever reaches here.
 */
export function canonicalizeReturnOrigin(raw: string): string {
  const trimmed = raw.trim();
  try {
    return new URL(trimmed).origin;
  } catch {
    return trimmed;
  }
}

/** What a save sends. Blank rows are dropped, because the backend rejects an empty string as
 *  "not a URL", and origins are canonicalized. */
export function cleanRegistration(d: RegistrationDraft): LoginRegistrationInput {
  return {
    allowedReturnOrigins: d.allowedReturnOrigins
      .map((o) => o.trim())
      .filter(Boolean)
      .map(canonicalizeReturnOrigin),
    redirectUris: d.redirectUris.map((u) => u.trim()).filter(Boolean),
  };
}

/**
 * Why the registration cannot be saved as it stands, or null when it can. `platform` is the
 * application's (absent for the ecosystem's own registration, which takes any redirect the
 * backend does). The backend is authoritative; this only says it sooner.
 */
export function registrationError(
  d: RegistrationDraft | null,
  platform?: ApplicationPlatform,
): string | null {
  if (!d) return null;
  const origins = d.allowedReturnOrigins.map((x) => x.trim()).filter(Boolean);
  if (platform === "native" && origins.length > 0) return "A native application has no return origins.";
  if (origins.length > MAX_RETURN_ORIGINS) return `At most ${MAX_RETURN_ORIGINS} return origins.`;
  for (const o of origins) {
    let url: URL;
    try {
      url = new URL(o);
    } catch {
      return `Return origin "${o}" is not a valid URL.`;
    }
    if (url.protocol !== "http:" && url.protocol !== "https:")
      return `Return origin "${o}" must be http(s).`;
    if (url.username || url.password) return `Return origin "${o}" must not include credentials.`;
    if (url.pathname !== "/" || url.search || url.hash)
      return `Return origin "${o}" must be just a scheme + host (no path).`;
  }
  const redirects = d.redirectUris.map((x) => x.trim()).filter(Boolean);
  if (redirects.length > MAX_REDIRECT_URIS) return `At most ${MAX_REDIRECT_URIS} redirect URIs.`;
  for (const u of redirects) {
    if (WHITESPACE_OR_CONTROL_RE.test(u)) return `Redirect URI "${u}" must not contain spaces.`;
    let url: URL;
    try {
      url = new URL(u);
    } catch {
      return `Redirect URI "${u}" is not a valid URI.`;
    }
    if (url.username || url.password) return `Redirect URI "${u}" must not include credentials.`;
    if (url.hash || u.includes("#")) return `Redirect URI "${u}" must not include a fragment (#).`;
    if (url.protocol === "https:") continue;
    if (url.protocol === "http:") {
      if (!LOOPBACK_HOSTS.has(url.hostname))
        return `Redirect URI "${u}" may use http only on localhost.`;
      continue;
    }
    if (platform === "web")
      return `Redirect URI "${u}" must be https, or http on localhost, for a web application.`;
    const scheme = url.protocol.slice(0, -1);
    if (!CUSTOM_SCHEME_RE.test(scheme) || FORBIDDEN_CUSTOM_SCHEMES.has(scheme))
      return `Redirect URI "${u}" uses a scheme that is not allowed.`;
    if (u.length <= url.protocol.length) return `Redirect URI "${u}" needs a path after the scheme.`;
  }
  return null;
}

/** Two registrations are the same when they would SAVE the same, so a blank row added and left
 *  empty is not an edit. */
export function sameRegistration(a: RegistrationDraft | null, b: RegistrationDraft | null): boolean {
  if (a === null || b === null) return a === b;
  return JSON.stringify(cleanRegistration(a)) === JSON.stringify(cleanRegistration(b));
}

/** Policy equality. `allowedProviders` is compared as a set, because order means nothing. */
export function samePolicy(a: ClientAuthPolicy | null, b: ClientAuthPolicy | null): boolean {
  if (a === null || b === null) return a === b;
  return (
    a.signupMode === b.signupMode &&
    a.loginEnabled === b.loginEnabled &&
    a.passwordEnabled === b.passwordEnabled &&
    sameProviders(a.allowedProviders, b.allowedProviders) &&
    sameEmailList(a.loginAllowedEmails, b.loginAllowedEmails)
  );
}

/** The backend's bounds on the login allow-list (routes/ecosystemAuthSettings.ts), mirrored so
 *  Save is refused before the round trip. */
export const MAX_LOGIN_ALLOWED_EMAILS = 500;
const MAX_EMAIL_LENGTH = 254;
/** The allow-list's email grammar: exactly one `@`, a non-empty local part with no whitespace and
 *  no quote, and a domain of at least two non-empty dot-separated labels. The backend's zod check
 *  is authoritative; this only refuses sooner what it would refuse. */
const EMAIL_SHAPE = /^[^\s@"]+@[^\s@.]+(?:\.[^\s@.]+)+$/;

/**
 * The login allow-list as a save sends it: each email trimmed and lowercased, blank rows dropped,
 * duplicates dropped with the first kept — the form the backend stores. `null` (every customer)
 * stays `null`, and an empty list stays `[]`, which means nobody — the editor's switch, not the
 * row count, decides between the two.
 */
export function cleanEmailList(emails: string[] | null): string[] | null {
  if (emails === null) return null;
  return [...new Set(emails.map((e) => e.trim().toLowerCase()).filter(Boolean))];
}

/** Two allow-lists are the same when they would SAVE the same, compared as sets. */
function sameEmailList(a: string[] | null, b: string[] | null): boolean {
  const ca = cleanEmailList(a);
  const cb = cleanEmailList(b);
  if (ca === null || cb === null) return ca === cb;
  return ca.length === cb.length && ca.every((e) => cb.includes(e));
}

/**
 * Whether a save sent the login allow-list and the saved policy came back without it. A
 * backend that predates the list drops the unknown field and answers 200. Re-seeding from that
 * answer would turn the switch back off, while every customer can still sign in. An absent
 * field reads as `null` (everyone), so sending `null` to such a backend is not a drop.
 */
export function allowListDropped(
  sent: Partial<ClientAuthPolicy>,
  saved: Partial<ClientAuthPolicy>,
): boolean {
  if (!("loginAllowedEmails" in sent)) return false;
  return !sameEmailList(sent.loginAllowedEmails ?? null, saved.loginAllowedEmails ?? null);
}

/** The error a save shows when the backend dropped the allow-list. */
export const ALLOW_LIST_NOT_SAVED =
  "The sign-in list was not saved, so everyone can still sign in. This backend does not support the list yet.";

/** Why the policy cannot be saved as it stands, or null when it can. The backend is
 *  authoritative; this only says it sooner. */
export function policyError(policy: ClientAuthPolicy | null): string | null {
  const emails = cleanEmailList(policy?.loginAllowedEmails ?? null);
  if (emails === null) return null;
  if (emails.length > MAX_LOGIN_ALLOWED_EMAILS)
    return `At most ${MAX_LOGIN_ALLOWED_EMAILS} people can be listed.`;
  const bad = emails.find((e) => e.length > MAX_EMAIL_LENGTH || !EMAIL_SHAPE.test(e));
  if (bad) return `"${bad}" is not an email address.`;
  return null;
}

function sameProviders(a: string[] | null, b: string[] | null): boolean {
  if (a === null || b === null) return a === b;
  return a.length === b.length && a.every((slug) => b.includes(slug));
}

/** Whether a provider is on under a policy. `null` means every provider is on. */
export function providerOn(policy: ClientAuthPolicy, slug: string): boolean {
  return policy.allowedProviders === null || policy.allowedProviders.includes(slug);
}

/**
 * Turn one provider on or off, and return the new `allowedProviders`. Every provider on is `null`
 * (every configured provider, including ones the platform adds later), never the full list
 * spelled out. The last provider cannot be turned off, because the backend reads `[]` as "all"
 * too. The switch for it is disabled, and this refuses it as well.
 */
export function toggleProvider(
  policy: ClientAuthPolicy,
  providers: readonly AuthProviderChoice[],
  slug: string,
  on: boolean,
): string[] | null {
  const current = providers.map((p) => p.slug).filter((s) => providerOn(policy, s));
  const next = on ? [...new Set([...current, slug])] : current.filter((s) => s !== slug);
  if (next.length === 0) return policy.allowedProviders;
  return providers.every((p) => next.includes(p.slug)) ? null : next;
}

/** The fields of a policy that differ from `base`, for a partial PUT. */
export function policyPatch(
  draft: ClientAuthPolicy,
  base: ClientAuthPolicy,
): Partial<ClientAuthPolicy> | undefined {
  const patch: Partial<ClientAuthPolicy> = {};
  if (draft.signupMode !== base.signupMode) patch.signupMode = draft.signupMode;
  if (draft.loginEnabled !== base.loginEnabled) patch.loginEnabled = draft.loginEnabled;
  if (draft.passwordEnabled !== base.passwordEnabled) patch.passwordEnabled = draft.passwordEnabled;
  if (!sameProviders(draft.allowedProviders, base.allowedProviders))
    patch.allowedProviders = draft.allowedProviders;
  if (!sameEmailList(draft.loginAllowedEmails, base.loginAllowedEmails))
    patch.loginAllowedEmails = cleanEmailList(draft.loginAllowedEmails);
  return Object.keys(patch).length > 0 ? patch : undefined;
}
