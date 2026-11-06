'use client'

/** Structured context attached to a reported error — scalars only (no PII / bodies / ids). */
export type ErrorContext = Record<string, string | number | boolean | null | undefined>

type Reporter = (error: unknown, context?: ErrorContext) => void

// Injected by the host once its error SDK is live; null = console-only (no host
// wired, pre-init, or SSR). Explicit indirection — the same registered-reporter
// pattern @adh-sdk/adh's report-error uses — rather than importing a telemetry
// SDK here, so this package stays a dependency-free leaf.
let reporter: Reporter | null = null

/**
 * Wire the host's error reporter (e.g. Sentry → GlitchTip). The host calls this
 * once at client bootstrap; pass null to unregister. Until a host registers one,
 * {@link reportUnexpectedAuthError} logs to the console only.
 */
export function setAuthErrorReporter(fn: Reporter | null): void {
  reporter = fn
}

// Per-signature throttle for reportUnexpectedAuthError. During an outage the SAME
// failure recurs on every react-query focus/remount refetch (an errored query is
// always stale), each attempt throwing a FRESH Error object — so effects keyed on
// error identity re-report, unbounded, exactly when telemetry volume hurts most.
// One report per (message + context) per window is the signal; the repeats are not.
const REPORT_DEDUPE_WINDOW_MS = 60_000
const lastReportAt = new Map<string, number>()

// The WebAuthn ceremony ended by the user or the browser, not by a bug: the user
// dismissed the passkey sheet or let it time out (`NotAllowedError`), or a newer
// ceremony aborted this one (`AbortError`). @simplewebauthn's WebAuthnError keeps
// the DOMException's name, and a raw DOMException carries it too, so the name is
// the one check that covers both. Passkey cancel is the commonest passkey outcome.
const CEREMONY_CANCELLED = new Set(['NotAllowedError', 'AbortError'])

function isCeremonyCancelled(err: unknown): boolean {
  const name = typeof err === 'object' && err !== null ? (err as { name?: unknown }).name : undefined
  return typeof name === 'string' && CEREMONY_CANCELLED.has(name)
}

/**
 * Report a CAUGHT auth error — but only when it's unexpected. A status-carrying
 * HTTP error (e.g. an {@link import('./client').AuthHttpError} thrown by
 * `authedJson` on a non-ok response) with a 4xx status is an expected user/flow
 * error (wrong password, stale exchange code, email already taken, capability
 * rejection) and is dropped to avoid noise, as is a passkey ceremony the user
 * cancelled or that timed out (`NotAllowedError` / `AbortError`); network errors (no numeric `status`)
 * and 5xx backend failures are reported — deduped to one report per identical
 * (message + context) signature per minute, so an outage under react-query's
 * focus/remount refetches can't flood the reporter. Fail-safe: never throws.
 *
 * Duck-types a numeric `.status` carried by an `Error` (the same shape as the
 * host's `httpStatus` helper) rather than `instanceof` one AuthHttpError class:
 * TWO distinct AuthHttpError classes coexist when a host layers its own auth
 * client atop this package, and both must be recognized. After the gate the
 * error goes to the host-injected reporter (if any) AND the console.
 */
export function reportUnexpectedAuthError(err: unknown, context?: ErrorContext): void {
  const status = err instanceof Error ? (err as { status?: unknown }).status : undefined
  if (typeof status === 'number' && status < 500) return
  if (isCeremonyCancelled(err)) return
  const signature = `${err instanceof Error ? err.message : String(err)}|${JSON.stringify(context ?? null)}`
  const now = Date.now()
  const last = lastReportAt.get(signature)
  if (last !== undefined && now - last < REPORT_DEDUPE_WINDOW_MS) return
  lastReportAt.set(signature, now)
  reportAuthError(err, context)
}

/**
 * Report a CAUGHT auth error UNCONDITIONALLY — for call sites that have already
 * decided the error is worth reporting (a network failure with no HTTP status,
 * a caller-gated 5xx, an unexpected throw from a click handler). Same sink as
 * {@link reportUnexpectedAuthError} without the status gate. Fail-safe: never throws.
 */
export function reportAuthError(err: unknown, context?: ErrorContext): void {
  try {
    reporter?.(err, context)
  } catch {
    /* a telemetry failure must never break the caller */
  }
  console.error(err, context)
}
