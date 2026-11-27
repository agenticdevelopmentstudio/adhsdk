// Directive-free on purpose: the second-factor vocabulary is shared by the client MFA step
// (ui/MfaStep.tsx) and the server-rendered hosted login page (@adh-sdk/hosted-login), which
// imports it through the `./mfa-labels` subpath. `mfa.ts` is 'use client', so it can't live
// there; the type import below is erased at build time and pulls in no client code.
import type { MfaCodeMethod, MfaMethod } from './mfa'

export type { MfaCodeMethod, MfaMethod }

/** The user-facing name of each second-factor method. */
export const MFA_METHOD_LABELS: Readonly<Record<MfaMethod, string>> = {
  totp: 'Authenticator app',
  sms: 'Text message',
  webauthn: 'Passkey or security key',
  recovery: 'Recovery code',
}

/** Whether `m` is a factor completed by typing a code (not a passkey ceremony). Takes any
 *  string, so a method read off a query string can be checked as well as a typed one. */
export function isCodeMethod(m: string): m is MfaCodeMethod {
  return m === 'sms' || m === 'totp' || m === 'recovery'
}
