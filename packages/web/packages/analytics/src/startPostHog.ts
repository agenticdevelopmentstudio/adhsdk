import posthog, { type PostHog } from 'posthog-js'
import { scrubPath, scrubUrl } from './scrub'

// PostHog, configured ONCE here so every site — the adh family through its
// TelemetryProvider, and any other site through PostHogAnalytics — sends the same
// anonymous, cookieless, allowlist-only events.
//
// Privacy principle: default-deny / fail-toward-privacy. A mistake must EXCLUDE data,
// never accidentally include something private — so autocapture and session replay are
// OFF, persistence is in-memory (no cross-session id, no consent banner), users are never
// identified, and URLs are stripped of query/hash and id-shaped segments.
//
// No-ops when NEXT_PUBLIC_POSTHOG_KEY is absent, so a site can ship this before its
// project has a key, and a local build sends nothing.

// The started instance lives on `window`, not in module state: a deploy that bundles this
// package twice (a site's own copy beside the one adh's dist reaches) must still start
// PostHog once and send every event through that one instance, or each copy counts its own
// pageviews.
const RUNNING = '__adhsdkPostHog'
type Host = Window & { [RUNNING]?: PostHog }

function running(): PostHog | undefined {
  return typeof window === 'undefined' ? undefined : (window as Host)[RUNNING]
}

/**
 * Start PostHog for this page. Idempotent: the first call initializes it and every later
 * call returns the same answer without touching it again, so a site that mounts it twice
 * (a shared shell and its own layout) still starts it once.
 *
 * @returns whether PostHog is running — false without a key, or on the server.
 */
export function startPostHog(): boolean {
  if (running()) return true
  if (typeof window === 'undefined') return false
  // Read inline, not through a helper: Next inlines `process.env.NEXT_PUBLIC_*` only where
  // the expression is written out in full.
  const key = process.env.NEXT_PUBLIC_POSTHOG_KEY
  if (!key) return false
  posthog.init(key, {
    api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST ?? 'https://us.i.posthog.com',
    autocapture: false, // the heart of "default to less": no automatic click/input capture
    disable_session_recording: true, // no screen replay, ever
    capture_pageview: 'history_change', // traffic only — pageviews on SPA route change
    // Real-user Core Web Vitals (LCP/INP/CLS/FCP) as `$web_vitals` events. Distinct
    // from autocapture (which stays off) and numeric-only, so it carries no PII.
    capture_performance: { web_vitals: true },
    persistence: 'memory', // cookieless: no cross-session id ⇒ no consent banner
    person_profiles: 'identified_only', // never create a profile for an anonymous visitor
    mask_all_text: true, // belt-and-suspenders if any capture path ever runs
    mask_all_element_attributes: true,
    disable_surveys: true,
    before_send: (event) => {
      // Scrub the URL/path properties PostHog attaches to every event (pageviews AND
      // $web_vitals): origin + redacted path, no query/hash. $pathname is redacted too
      // so an id-bearing route can't ride along unscrubbed.
      if (event?.properties) {
        event.properties.$current_url = scrubUrl(event.properties.$current_url)
        event.properties.$referrer = scrubUrl(event.properties.$referrer)
        if (typeof event.properties.$pathname === 'string') {
          event.properties.$pathname = scrubPath(event.properties.$pathname)
        }
      }
      return event
    },
  })
  ;(window as Host)[RUNNING] = posthog
  return true
}

/** Property bag for a custom event — scalars only (no nested objects/PII). */
export type AnalyticsProps = Record<string, string | number | boolean | null | undefined>

/**
 * Send a custom event through the PostHog that `startPostHog` started. A no-op until it has,
 * so a host never has to ask first. Going through here rather than importing posthog-js
 * directly is what keeps a host's events on the ONE initialized instance: a second copy of
 * posthog-js in a bundle would accept `capture` calls and send nothing.
 */
export function captureAnalyticsEvent(name: string, props: AnalyticsProps): void {
  running()?.capture(name, props)
}
