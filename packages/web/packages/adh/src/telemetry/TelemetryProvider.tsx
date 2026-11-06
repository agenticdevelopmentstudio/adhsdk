'use client'

import { useEffect, type ReactNode } from 'react'
import * as Sentry from '@sentry/react'
import { scrubUrl, startPostHog } from '@adh-sdk/analytics'
import { setPosthogReady, captureEvent } from './analytics'
import { instrumentFetch } from './fetch-instrumentation'
import { errorNoiseReason, noiseReason, type NoiseEnvironment } from './noise-filter'
// Package-path specifier, not relative: this leaf is `external` in this package's own
// tsup.config.ts (module-level `reporter` state must stay a single instance across every
// entry that reaches it — see the comment beside '@adh-sdk/adh/telemetry/report-error'
// in that file). A relative './report-error' would get inlined and silently duplicated instead.
import { setErrorReporter } from '@adh-sdk/adh/telemetry/report-error'

// Telemetry, wired ONCE here so every site that renders the shared chrome gets it
// from a single place (the way the header/footer already work). Two engines, both
// privacy-first by construction:
//   • Errors    → Sentry SDK pointed at self-hosted GlitchTip (errors only).
//   • Analytics → PostHog, anonymous + cookieless + allowlist-only, configured in
//     @adh-sdk/analytics.
//
// Privacy principle: default-deny / fail-toward-privacy. A mistake must EXCLUDE
// data, never accidentally include something private — so autocapture and session
// replay are OFF, persistence is in-memory (no cross-session id, no consent
// banner), users are never identified, and URLs are stripped of query/hash.
//
// Both engines no-op when their NEXT_PUBLIC_* key is absent, so this is safe to
// ship before the GlitchTip / PostHog projects exist.

let started = false

function noiseEnvironment(): NoiseEnvironment {
  return { userAgent: navigator.userAgent, webdriver: navigator.webdriver }
}

function startTelemetry(resolveEnvironment: (hostname: string) => string): void {
  if (started || typeof window === 'undefined') return
  started = true

  // Ask the host to classify the hostname UNCONDITIONALLY — before the DSN check —
  // so the seam is exercised on every mount regardless of whether GlitchTip is
  // configured, not just when there happens to be a DSN. Cheap, synchronous, and
  // means a caller can always trust `resolveEnvironment` ran once telemetry starts.
  const environment = resolveEnvironment(window.location.hostname)

  // ── Errors → GlitchTip (Sentry-compatible) ───────────────────────────────
  const dsn = process.env.NEXT_PUBLIC_GLITCHTIP_DSN
  if (dsn) {
    Sentry.init({
      dsn,
      // Tag every event with the env the HOST resolved above from the hostname
      // (testing./staging./else prod; *.local → local, or whatever scheme the host uses) —
      // the toolkit has no site registry of its own, so this is injected. Without it Sentry
      // defaults `environment` to "production", so a testing/staging error was mislabeled
      // production and impossible to triage by env. Set once at init — the real host is
      // authoritative (the dev env override is a display-only concern).
      environment,
      // The deploy's commit SHA (next-config-base inlines VERCEL_GIT_COMMIT_SHA as
      // NEXT_PUBLIC_ADH_RELEASE), so every error is attributable to a deploy — as the backend
      // already tags its own. Omitted when blank (local dev / no Vercel SHA). This is also the
      // key future source-map artifacts upload against.
      ...(process.env.NEXT_PUBLIC_ADH_RELEASE ? { release: process.env.NEXT_PUBLIC_ADH_RELEASE } : {}),
      tracesSampleRate: 0, // errors only — no performance tracing (GlitchTip is errors-only)
      sendDefaultPii: false, // never infer the user's IP or attach PII
      beforeSend(event) {
        // Drop what nobody can act on (bots, third-party scripts, stale chunks, the
        // visitor's own network) — see noise-filter.ts for each rule and its evidence.
        if (noiseReason(event, noiseEnvironment())) return null
        // Belt-and-suspenders scrub: drop user + cookies, strip URL queries.
        delete event.user
        if (event.request) {
          delete event.request.cookies
          event.request.url = scrubUrl(event.request.url)
        }
        return event
      },
    })
  }

  // ── Analytics → PostHog (anonymous, cookieless, allowlist-only) ───────────
  // The config is @adh-sdk/analytics', shared with every site outside the
  // family; it no-ops without NEXT_PUBLIC_POSTHOG_KEY. Gate captureEvent on it: custom
  // events only reach PostHog once init has actually run.
  if (startPostHog()) setPosthogReady(true)

  // Route HANDLED errors (captureException across the platform) to BOTH pipelines,
  // registered regardless of which backend is configured: GlitchTip gets the error
  // itself (no-op if Sentry isn't init), and PostHog gets an `error_reported` metric
  // event for error-rate dashboards (no-op until PostHog is ready). The raw message
  // is NOT sent to PostHog (it goes only to GlitchTip) — PostHog gets the low-PII
  // shape (feature/step + error name) so a message can't leak into analytics.
  setErrorReporter((error, context) => {
    Sentry.withScope((scope) => {
      if (context) scope.setExtras(context)
      Sentry.captureException(error)
    })
    // Noise beforeSend drops (bots, stale chunks, the visitor's network) is not
    // counted here either, so the dashboard's per-site error figure matches GlitchTip.
    if (errorNoiseReason(error, noiseEnvironment())) return
    captureEvent('error_reported', {
      // `error_name` (not `name`) so a caller-supplied `name` in context can't be
      // silently clobbered by the spread.
      error_name: error instanceof Error ? error.name : typeof error,
      ...context,
    })
  })

  // Time every fetch (authenticated + unauthenticated). Runs even without a PostHog key
  // so the local dev suite still surfaces timings on the console; emission is a no-op
  // toward PostHog until setPosthogReady(true) above.
  instrumentFetch()
}

export type TelemetryProviderProps = {
  children: ReactNode
  /** Classifies the current hostname into a deployment environment, used to tag every
   *  error report. Injected by the host: the toolkit has no site registry, and without
   *  this Sentry defaults `environment` to "production", making testing/staging errors
   *  impossible to triage by env. */
  resolveEnvironment: (hostname: string) => string
}

/**
 * Initializes error + analytics capture for the site. Drop-in: wrap a site's
 * providers tree with it once. Renders children unchanged.
 */
export function TelemetryProvider({ children, resolveEnvironment }: TelemetryProviderProps): ReactNode {
  useEffect(() => {
    startTelemetry(resolveEnvironment)
  }, [resolveEnvironment])
  return children
}
