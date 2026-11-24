import { authedJson, extractErrorMessage } from "../http";
import type {
  AcceptResultRow,
  AcceptResultWire,
  InvitePreviewRow,
  InvitePreviewWire,
  RegisterWithInviteResultRow,
  RegisterWithInviteResultWire,
  VerifyResultRow,
  VerifyResultWire,
} from "./wire";

// Response shapes mirror the generated OpenAPI types (see ./wire) so a backend
// contract change breaks the type-check here rather than at runtime.
export type InvitePreview = InvitePreviewRow;
export type AcceptResult = AcceptResultRow;
export type VerifyResult = VerifyResultRow;
export type RegisterWithInviteResult = RegisterWithInviteResultRow;

/** Invite-aware self-registration payload (the base register body + the invite token). */
export interface RegisterWithInviteInput {
  email: string;
  password: string;
  name: string;
  invite: string;
}

/**
 * Client for the public `/join` acceptance flow. Preview + verify are anonymous
 * (`fetch` to the public /v1 routes); accept is authed (`authedJson`); register is the
 * existing signup POST with the invite token attached. The hub rewrites `/api/*`
 * onto the backend (stripping the `/api` prefix).
 */
export const invitationsApi = {
  /** Read an invitation's public state by its raw token. Never throws: a non-2xx
   *  (or a missing/expired token) resolves to the `invalid` state so the page can
   *  render a single "this link doesn't work" pane. */
  async preview(token: string): Promise<InvitePreview> {
    const res = await fetch(
      `/api/v1/invitations/preview?token=${encodeURIComponent(token)}`,
      { cache: "no-store" },
    );
    if (!res.ok) return { state: "invalid", ecosystemName: null, maskedDestination: null };
    const w = (await res.json()) as InvitePreviewWire;
    return {
      state: w.state,
      ecosystemName: w.ecosystem_name ?? null,
      maskedDestination: w.masked_destination ?? null,
    };
  },

  /** Complete an invite-backed account by verifying its emailed code. Throws on a
   *  non-2xx (expired 410 / invalid 400) so the verify page can show its error state. */
  async verify(code: string): Promise<VerifyResult> {
    const res = await fetch("/api/v1/invitation_requests/verify", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ code }),
    });
    if (!res.ok) throw new Error(String(res.status));
    const w = (await res.json()) as VerifyResultWire;
    return { ok: w.ok, ecosystemName: w.ecosystem_name };
  },

  /** A logged-in user accepts an invitation by token — either joins immediately or
   *  is told to verify their email first. */
  async accept(token: string): Promise<AcceptResult> {
    const w = await authedJson<AcceptResultWire>("/api/v1/invitations/accept", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ token }),
    });
    return { status: w.status, ...(w.ecosystem_name !== undefined ? { ecosystemName: w.ecosystem_name } : {}) };
  },

  /** Register a brand-new account against an invitation (the invite token gates the
   *  otherwise-closed signup and binds the new account to the pending invite). On a
   *  non-2xx the backend's message is surfaced (e.g. a 403 when the entered email
   *  doesn't match the address the invitation was sent to). */
  async registerWithInvite(input: RegisterWithInviteInput): Promise<RegisterWithInviteResult> {
    const res = await fetch("/api/v1/auth/registrations", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(input),
    });
    if (!res.ok) {
      const body = await res.json().catch(() => null);
      throw new Error(extractErrorMessage(body, `Registration failed (${res.status})`));
    }
    const w = (await res.json()) as RegisterWithInviteResultWire;
    return {
      token: w.token,
      refreshToken: w.refresh_token,
      user: {
        id: w.user.id,
        email: w.user.email,
        name: w.user.name,
        avatarUrl: w.user.avatar_url,
        slug: w.user.slug ?? null,
        publicProfileEnabled: w.user.public_profile_enabled,
        capabilities: w.user.capabilities,
      },
      emailVerificationRequired: w.email_verification_required,
      ...(w.email_in_use !== undefined ? { emailInUse: w.email_in_use } : {}),
    };
  },
};
