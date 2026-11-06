// Pure classifier for error events nobody can act on. TelemetryProvider's `beforeSend`
// drops an event when this says it is noise, so GlitchTip (and the status board, which
// turns red for 24 h on a single unresolved error) only hears about OUR failures.
//
// Every rule below is backed by real GlitchTip traffic (Nov 2026 triage,
// docs/status-site/status-glitchtip-noise-and-scheduler.md in statussite):
//   • bots           — HeadlessChrome / crawlers / scraping browsers run our pages in
//                      broken JS engines and report the breakage as ours.
//   • foreign code   — every frame is someone else's script: Vercel Analytics /
//                      Speed Insights (`/<16 hex>/script.js`), a scraper's injected
//                      bootstrap (`<obscura:…>`), or a browser extension.
//   • stale deploy   — ChunkLoadError: a tab opened before a deploy asks for a chunk the
//                      new deploy no longer serves. The reload fixes it; nothing to fix.
//   • network        — the browser's own "the request never completed" errors (offline,
//                      blocked, navigated away). Server-side failures arrive as HTTP
//                      statuses and are still reported; a dead backend is the status
//                      prober's job, not a visitor's browser's.
//
// Structural types only (no @sentry/* import) so this stays a dependency-free leaf that
// unit-tests without a Sentry runtime. Each rule is one entry: delete it to undo it.

type Frame = { filename?: string; abs_path?: string }
type ExceptionValue = { type?: string; value?: string; stacktrace?: { frames?: Frame[] } }
export type NoiseCandidate = { exception?: { values?: ExceptionValue[] }; message?: string }
export type NoiseEnvironment = { userAgent?: string; webdriver?: boolean }

const BOT_USER_AGENT = /HeadlessChrome|\bbot\b|bot\/|crawler|spider|Lighthouse|PhantomJS|Puppeteer|Playwright|Obscura/i

const FOREIGN_FRAME = [
  /\/[0-9a-f]{16}\/script\.js(?:[?#]|$)/, // Vercel Web Analytics / Speed Insights v2 hashed paths
  /^<obscura:/, // Obscura scraping browser's injected bootstrap
  /^(?:chrome|moz|safari|safari-web)-extension:\/\//, // browser extensions
]

// Sentry's fetch instrumentation (enhanceFetchErrorMessages, default 'always') appends
// the request's host: "Failed to fetch (auth.example.com)". Allow that one suffix.
const NETWORK_FAILURE = /^(?:Failed to fetch|Load failed|NetworkError when attempting to fetch resource\.?)(?: \([^()\s]+\))?$/

function frameSource(frame: Frame): string {
  return frame.abs_path || frame.filename || ''
}

function allFramesForeign(values: ExceptionValue[]): boolean {
  const sources = values.flatMap((v) => v.stacktrace?.frames ?? []).map(frameSource).filter(Boolean)
  return sources.length > 0 && sources.every((s) => FOREIGN_FRAME.some((re) => re.test(s)))
}

/** Why `event` is noise, or null when it should be reported. */
export function noiseReason(event: NoiseCandidate, env: NoiseEnvironment = {}): string | null {
  if (env.webdriver) return 'automation'
  if (env.userAgent && BOT_USER_AGENT.test(env.userAgent)) return 'bot'

  const values = event.exception?.values ?? []
  if (allFramesForeign(values)) return 'foreign-code'
  if (values.some((v) => v.type === 'ChunkLoadError')) return 'stale-deploy'
  if (values.some((v) => v.type === 'TypeError' && NETWORK_FAILURE.test(v.value ?? ''))) return 'network'
  return null
}
