'use client'

import { captureAnalyticsEvent, type AnalyticsProps } from '@agenticdevelopertoolkit/analytics'

// Custom analytics capture, paired with the privacy-first PostHog init in
// TelemetryProvider. Everything here is fail-safe: these run on the fetch hot path
// (see fetch-instrumentation), so a telemetry bug must never throw into a caller and
// nothing private (tokens, bodies, ids) may ride along.

/** The explicit allowlist of instrumented event names — one source of truth. */
export const EVENT_HTTP_REQUEST = 'http_request'

/** Property bag for a custom event — scalars only (no nested objects/PII). */
export type EventProps = AnalyticsProps

// Whether posthog.init actually ran (a NEXT_PUBLIC_POSTHOG_KEY was present). Set by
// TelemetryProvider; until then captureEvent only debug-logs. Explicit flag rather
// than poking posthog internals (explicit-over-implicit).
let posthogReady = false

/** Called by TelemetryProvider once PostHog has been initialized. */
export function setPosthogReady(ready: boolean): void {
  posthogReady = ready
}

// Local visibility when PostHog has no key (the local dev suite never sets one): emit
// the same events to the console so a developer can see timings without a deploy.
const debugEnabled =
  process.env.NODE_ENV !== 'production' || process.env.NEXT_PUBLIC_TELEMETRY_DEBUG === '1'

/**
 * Capture a custom analytics event. No-ops (beyond an optional dev console line) unless
 * PostHog initialized. NEVER throws — telemetry must not affect the instrumented path.
 */
export function captureEvent(name: string, props: EventProps): void {
  try {
    if (posthogReady) captureAnalyticsEvent(name, props)
    if (debugEnabled) console.debug('[perf]', name, props)
  } catch {
    /* swallow — a telemetry failure must never break the caller */
  }
}

// The retry marker lives in a posthog-free leaf so the auth client can import it without
// dragging posthog-js in; re-exported here for the barrel + fetch wrapper. Package-path
// specifier, not relative: './retry' is `external` in this package's own tsup.config.ts so
// every entry that reaches the leaf's module-level `retriedInits` WeakSet shares one instance
// instead of each getting its own inlined copy.
export { markRetriedRequest, consumeRetriedFlag } from '@agentic-toolkit/adh/telemetry/retry'
