import { Hono } from 'hono';
import { HTTPException } from 'hono/http-exception';
import { getCookie, setCookie, deleteCookie } from 'hono/cookie';
import { randomBytes } from 'node:crypto';
import type { AuthVars } from '../middleware/auth';
import type { StatusConfig } from '../config/port';
import type { Storage, UserRecord } from '../storage/ports';
import { roleForEmail, isUniqueViolation } from '../storage/ports';
import { setSessionCookie } from './cookie';

const STATE_COOKIE = 'gh_oauth_state';
/** Where the visitor was going when the login gate bounced them (the login
 *  page's `next`), carried across the GitHub round trip beside the state. */
const NEXT_COOKIE = 'gh_oauth_next';
/** Where a GitHub login with no (valid) `next` lands. */
const DEFAULT_DESTINATION = '/home';
/** A throwaway origin `next` is resolved against; only its path part is kept. */
const NEXT_RESOLVE_BASE = 'http://next.invalid';

/**
 * `next` if it is a same-origin, purely relative path, else null. The value ends
 * up in a Location header, so anything that could leave the site is refused:
 * a scheme or host (`https://evil`), a protocol-relative `//evil` and its
 * backslash spelling `/\evil` (browsers treat `\` as `/`), and control chars.
 * It is then resolved the way a browser would (as `@adh-sdk/auth`'s browser-side
 * `safeReturnTo` does) and only the normalized `pathname+search+hash` is returned:
 * dot segments that collapse to `//host` (`/x/..//evil`) are refused, and the
 * result is percent-encoded, so no raw non-ASCII byte reaches the Location header.
 */
export function safeNext(next: string | undefined | null): string | null {
  if (!next || next.length > 2048) return null;
  if (!next.startsWith('/') || next.startsWith('//') || next.startsWith('/\\')) return null;
  if (/[\x00-\x1f\x7f]/.test(next)) return null;
  let url: URL;
  try {
    url = new URL(next, NEXT_RESOLVE_BASE);
  } catch {
    return null;
  }
  if (url.origin !== NEXT_RESOLVE_BASE || url.pathname.startsWith('//')) return null;
  return url.pathname + url.search + url.hash;
}

/** fetch with the GitHub deadline — the only outbound fetches on a PRE-AUTH
 *  request path; un-deadlined, a hung GitHub API held the callback open for as
 *  long as the socket survived. `config.github.fetchTimeoutMs` (test-tunable);
 *  null keeps this default. */
async function ghFetch(url: string, init: RequestInit, config: StatusConfig): Promise<Response> {
  try {
    return await fetch(url, { ...init, signal: AbortSignal.timeout(config.github.fetchTimeoutMs ?? 8_000) });
  } catch {
    throw new HTTPException(502, { message: 'GitHub is unreachable' });
  }
}

interface GithubProfile {
  githubId: string;
  email: string | null;
  displayName: string;
}

function authorizeUrl(state: string, config: StatusConfig): string {
  const params = new URLSearchParams({
    client_id: config.github.clientId,
    redirect_uri: `${config.publicBaseUrl}/api/auth/github/callback`,
    scope: 'read:user user:email',
    state,
    allow_signup: 'true',
  });
  return `https://github.com/login/oauth/authorize?${params.toString()}`;
}

/** Exchange the OAuth `code` for the GitHub identity (server-side; the secret
 *  never touches the browser). Falls back to /user/emails for the primary
 *  verified address when the profile email is private. */
async function exchangeCode(code: string, config: StatusConfig): Promise<GithubProfile> {
  const tokenRes = await ghFetch('https://github.com/login/oauth/access_token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({
      client_id: config.github.clientId,
      client_secret: config.github.clientSecret,
      code,
    }),
  }, config);
  if (!tokenRes.ok) throw new HTTPException(502, { message: 'GitHub token exchange failed' });
  const token = ((await tokenRes.json()) as { access_token?: string }).access_token;
  if (!token) throw new HTTPException(401, { message: 'GitHub authorization failed' });

  const headers = {
    Authorization: `Bearer ${token}`,
    Accept: 'application/vnd.github+json',
    'User-Agent': 'status-backend',
  };
  // Check status BEFORE parsing: a non-200 body (revoked token, 403 rate-limit,
  // outage) is an error object, not a profile — trusting it would yield
  // id=undefined → githubId='undefined' and fuse every failed login into one row.
  const userRes = await ghFetch('https://api.github.com/user', { headers }, config);
  if (!userRes.ok) throw new HTTPException(502, { message: 'Could not read the GitHub profile' });
  const ghUser = (await userRes.json()) as { id?: number; login?: string; name: string | null; email: string | null };
  if (typeof ghUser.id !== 'number' || !Number.isFinite(ghUser.id)) {
    throw new HTTPException(502, { message: 'GitHub profile is missing an id' });
  }

  // Only ever adopt a PRIMARY + VERIFIED address (account-linking keys on email).
  let email = ghUser.email;
  if (!email) {
    const emailsRes = await ghFetch('https://api.github.com/user/emails', { headers }, config);
    if (emailsRes.ok) {
      const emails = (await emailsRes.json()) as { email: string; primary: boolean; verified: boolean }[];
      email = emails.find((e) => e.primary && e.verified)?.email ?? null;
    }
  }

  return {
    githubId: String(ghUser.id),
    email: email ? email.toLowerCase() : null,
    displayName: ghUser.name || ghUser.login || 'GitHub user',
  };
}

export function githubRoutes(storage: Storage, config: StatusConfig): Hono<{ Variables: AuthVars }> {
  const app = new Hono<{ Variables: AuthVars }>();

  app.get('/auth/github/start', (c) => {
    // Both are required: without publicBaseUrl the redirect_uri is relative and
    // GitHub rejects it, so fail fast here rather than bounce the user to a
    // GitHub error page with no recovery.
    if (!config.github.clientId || !config.publicBaseUrl) {
      throw new HTTPException(500, { message: 'GitHub login is not configured' });
    }
    const state = randomBytes(16).toString('hex');
    setCookie(c, STATE_COOKIE, state, { httpOnly: true, secure: config.cookieSecure, sameSite: 'Lax', path: '/', maxAge: 600 });
    // The CLI device flow is why this exists: a signed-out approver opening
    // `/device?code=…` is bounced to /login?next=…, and a GitHub login that
    // dropped `next` landed on /home with the pending request never approved.
    const next = safeNext(c.req.query('next'));
    if (next) {
      setCookie(c, NEXT_COOKIE, next, { httpOnly: true, secure: config.cookieSecure, sameSite: 'Lax', path: '/', maxAge: 600 });
    } else {
      deleteCookie(c, NEXT_COOKIE, { path: '/' });
    }
    return c.redirect(authorizeUrl(state, config));
  });

  app.get('/auth/github/callback', async (c) => {
    const code = c.req.query('code');
    const state = c.req.query('state');
    const expected = getCookie(c, STATE_COOKIE);
    deleteCookie(c, STATE_COOKIE, { path: '/' });
    const next = safeNext(getCookie(c, NEXT_COOKIE)) ?? DEFAULT_DESTINATION;
    deleteCookie(c, NEXT_COOKIE, { path: '/' });
    if (!code || !state || !expected || state !== expected) {
      throw new HTTPException(400, { message: 'Invalid OAuth state' });
    }

    const profile = await exchangeCode(code, config);
    let user: UserRecord | undefined = await storage.auth.findUserByGithubId(profile.githubId);
    if (!user) {
      const existing = profile.email ? await storage.auth.findUserByEmail(profile.email) : undefined;
      try {
        if (existing) {
          user = (await storage.auth.attachGithubId(existing.id, profile.githubId)) ?? existing;
        } else {
          user = await storage.auth.createUser({
            email: profile.email ?? `gh_${profile.githubId}@users.noreply.github.com`,
            displayName: profile.displayName,
            role: profile.email ? roleForEmail(profile.email, config) : 'pending',
            githubId: profile.githubId,
          });
        }
      } catch (err) {
        // Lost the create/attach race with a concurrent first login for the same
        // identity — the winner's row IS the account; log into it instead of
        // throwing the raw unique violation to the generic 500 handler.
        if (!isUniqueViolation(err)) throw err;
        user =
          (await storage.auth.findUserByGithubId(profile.githubId)) ??
          (profile.email ? await storage.auth.findUserByEmail(profile.email) : undefined);
        if (!user) throw err;
      }
    }

    setSessionCookie(c, await storage.auth.createSession(user.id), config);
    return c.redirect(next);
  });

  return app;
}
