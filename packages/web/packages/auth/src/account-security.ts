'use client'

// Self-serve account-security API: second-factor management (TOTP, WebAuthn,
// recovery codes) + preferred method, over /v1/account/mfa/*. Backs the Security
// settings workspace. Lives in this package (not @adh-sdk/data)
// because the WebAuthn registration ceremony shares @simplewebauthn/browser
// with the login-time MFA completion in ./mfa.ts — enrollment and challenge
// are two halves of one factor lifecycle.
//
// The response types are authored locally (mirroring the backend's
// /account/mfa OpenAPI schemas) — the hub's generated @adh-sdk/adh-api-types
// is a monorepo coupling this package can't take.
import { startRegistration } from '@simplewebauthn/browser'
import type { PublicKeyCredentialCreationOptionsJSON } from '@simplewebauthn/browser'
import { authedJson, authedRequest } from './client'
import { listAllV1, unixToIso } from './v1'

/** Factor status — maps `GET /v1/account/mfa`. */
export interface MfaStatus {
  sms: boolean
  totp: boolean
  webauthn: boolean
  /** A TOTP enrollment awaits confirmation. */
  totpPending: boolean
  /** Unused recovery codes. */
  recoveryRemaining: number
  preferredMethod: 'sms' | 'totp' | 'webauthn' | null
}

/** One registered credential — maps `GET /v1/account/mfa/passkeys` rows. */
export interface WebauthnCredential {
  id: string
  name: string
  kind: 'passkey' | 'security_key'
  createdAt: string
  lastUsedAt?: string | null
}

export type PreferredMethod = 'sms' | 'totp' | 'webauthn'

interface V1MfaStatus {
  sms: boolean
  totp: boolean
  webauthn: boolean
  totp_pending: boolean
  recovery_remaining: number
  preferred_method: PreferredMethod | null
}

export async function getMfaStatus(): Promise<MfaStatus> {
  const raw = await authedJson<V1MfaStatus>('/api/v1/account/mfa')
  return {
    sms: raw.sms,
    totp: raw.totp,
    webauthn: raw.webauthn,
    totpPending: raw.totp_pending,
    recoveryRemaining: raw.recovery_remaining,
    preferredMethod: raw.preferred_method,
  }
}

// --- TOTP -------------------------------------------------------------------

/** Maps `POST /v1/account/mfa/totp`. */
export interface TotpEnrollment {
  /** Base32 secret (for manual entry). */
  secret: string
  /** otpauth:// URI to render as a QR code. */
  otpauthUri: string
}

export async function enrollTotp(): Promise<TotpEnrollment> {
  const raw = await authedJson<{ secret: string; otpauth_uri: string }>('/api/v1/account/mfa/totp', {
    method: 'POST',
  })
  return { secret: raw.secret, otpauthUri: raw.otpauth_uri }
}
export async function confirmTotp(code: string): Promise<void> {
  await authedJson('/api/v1/account/mfa/totp/confirm', {
    method: 'POST',
    body: JSON.stringify({ code }),
  })
}
export async function removeTotp(): Promise<void> {
  await authedRequest('/api/v1/account/mfa/totp', { method: 'DELETE' })
}

// --- WebAuthn (passkeys / security keys) ------------------------------------

interface V1Passkey {
  id: string
  name: string
  kind: 'passkey' | 'security_key'
  created: number
  last_used_at?: string | null
}

export async function listWebauthn(): Promise<{ items: WebauthnCredential[] }> {
  const rows = await listAllV1<V1Passkey>('/api/v1/account/mfa/passkeys')
  return {
    items: rows.map((r) => ({
      id: r.id,
      name: r.name,
      kind: r.kind,
      createdAt: unixToIso(r.created),
      lastUsedAt: r.last_used_at ?? null,
    })),
  }
}

/** Run the full browser registration ceremony for a passkey or security key. */
export async function registerWebauthn(kind: 'passkey' | 'security_key', name: string): Promise<void> {
  const { options, token } = await authedJson<{
    options: PublicKeyCredentialCreationOptionsJSON
    token: string
  }>('/api/v1/account/mfa/passkeys/registration_options', {
    method: 'POST',
    body: JSON.stringify({ kind }),
  })
  const response = await startRegistration({ optionsJSON: options })
  await authedJson('/api/v1/account/mfa/passkeys', {
    method: 'POST',
    body: JSON.stringify({ token, response, name }),
  })
}
export async function removeWebauthn(id: string): Promise<void> {
  await authedRequest(`/api/v1/account/mfa/passkeys/${encodeURIComponent(id)}`, { method: 'DELETE' })
}

// --- Recovery codes + preference --------------------------------------------

export function regenerateRecoveryCodes(): Promise<{ codes: string[] }> {
  return authedJson<{ codes: string[] }>('/api/v1/account/mfa/recovery_codes/regenerate', { method: 'POST' })
}
export async function setPreferredMethod(method: PreferredMethod): Promise<{ preferredMethod: PreferredMethod }> {
  const raw = await authedJson<{ preferred_method: PreferredMethod }>('/api/v1/account/mfa', {
    method: 'POST',
    body: JSON.stringify({ preference: { method } }),
  })
  return { preferredMethod: raw.preferred_method }
}
