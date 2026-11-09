// Wire types for the invitations domain — package-local mirrors of the OpenAPI-generated
// response shapes the hub previously imported as `SuccessBody` from `@adh-sdk/adh-api-types`
// (for /v1/invitations/*, /v1/invitation_requests/verify, /v1/auth/registrations). These carry full
// backend-schema fidelity (not just the fields today's call sites touch) so the toolkit
// stays decoupled from the hub's generated types without narrowing what a caller can rely on.

export interface InvitePreviewRow {
  state: "valid" | "expired" | "accepted" | "invalid";
  ecosystemName?: string | null;
  maskedDestination?: string | null;
}

export interface VerifyResultRow {
  ok: boolean;
  ecosystemName: string;
}

export interface AcceptResultRow {
  status: "accepted" | "verification_required";
  ecosystemName?: string;
}

/** The authenticated user record embedded in a fresh register/login result — the SAME
 *  backend customer record GET /auth/me returns, so it re-uses that mirror (one wire
 *  representation; a backend field change is fixed in one place). */
import type { MeRow } from "../personas/wire";

export type UserRow = MeRow;

/** The 201 response from POST /auth/register — token + refreshToken + user, plus the
 *  invite-registration-specific verification/conflict flags. */
export interface RegisterWithInviteResultRow {
  /** JWT access token (Bearer credential) */
  token: string;
  /** Opaque refresh token (rotated on use) */
  refreshToken: string;
  user: UserRow;
  emailVerificationRequired: boolean;
  emailInUse?: boolean;
}

/* ── /v1 wire shapes (snake_case); invitations.ts maps them onto the camelCase rows above ── */

export interface InvitePreviewWire {
  state: InvitePreviewRow["state"];
  ecosystem_name?: string | null;
  masked_destination?: string | null;
}

export interface VerifyResultWire {
  ok: boolean;
  ecosystem_name: string;
}

export interface AcceptResultWire {
  status: AcceptResultRow["status"];
  ecosystem_name?: string;
}

/** `POST /v1/auth/registrations` 201 body. */
export interface RegisterWithInviteResultWire {
  token: string;
  refresh_token: string;
  user: {
    id: string;
    email: string;
    name: string;
    avatar_url: string;
    slug: string | null;
    public_profile_enabled: boolean;
    capabilities: string[];
  };
  email_verification_required: boolean;
  email_in_use?: boolean;
}
