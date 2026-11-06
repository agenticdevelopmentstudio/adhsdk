import { describe, expect, it } from 'vitest'
import { noiseReason, type NoiseCandidate } from '../noise-filter'

// Fixtures are shaped after real GlitchTip events from the Nov 2026 triage.
const CHROME = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36'

function exc(type: string, value: string, ...files: string[]): NoiseCandidate {
  return { exception: { values: [{ type, value, stacktrace: { frames: files.map((filename) => ({ filename })) } }] } }
}

const OUR_BUG = exc('TypeError', "Cannot read properties of undefined (reading 'id')",
  'https://agenticdeveloperhub.com/_next/static/immutable/chunks/42sp027f-umgu.js')

describe('noiseReason', () => {
  it('reports a genuine error from our own bundle on a real browser', () => {
    expect(noiseReason(OUR_BUG, { userAgent: CHROME })).toBeNull()
  })

  it.each([
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/120.0.0.0 Safari/537.36',
    'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0 Safari/537.36 360Spider',
    'Mozilla/5.0 (compatible; crawler)',
  ])('drops events from bot user agent %s', (userAgent) => {
    expect(noiseReason(OUR_BUG, { userAgent })).toBe('bot')
  })

  it('does not mistake a phone brand ending in "bot" for a bot', () => {
    const cubot = 'Mozilla/5.0 (Linux; Android 12; CUBOT X30) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36'
    expect(noiseReason(OUR_BUG, { userAgent: cubot })).toBeNull()
  })

  it('drops events from automated browsers (navigator.webdriver)', () => {
    expect(noiseReason(OUR_BUG, { userAgent: CHROME, webdriver: true })).toBe('automation')
  })

  it.each([
    'https://agenticdevelopercookbook.com/d512ddbf37368eeb/script.js', // Vercel Web Analytics
    '/e1e36be97a8decd2/script.js', // Speed Insights, as GlitchTip shows it
    '<obscura:bootstrap>',
    'chrome-extension://abcdefghijklmnop/content.js',
  ])('drops errors thrown entirely inside foreign code: %s', (file) => {
    expect(noiseReason(exc('SyntaxError', 'Invalid or unexpected token', file), { userAgent: CHROME })).toBe('foreign-code')
  })

  it('keeps an error that passes through foreign code but has our frames too', () => {
    const mixed = exc('TypeError', 'x is null', 'https://agenticdeveloperhub.com/d512ddbf37368eeb/script.js',
      'https://agenticdeveloperhub.com/_next/static/immutable/chunks/app.js')
    expect(noiseReason(mixed, { userAgent: CHROME })).toBeNull()
  })

  it('does not treat a frameless error as foreign', () => {
    expect(noiseReason({ exception: { values: [{ type: 'Error', value: 'boom' }] } }, { userAgent: CHROME })).toBeNull()
  })

  it('drops ChunkLoadError from a tab that outlived its deploy', () => {
    const chunk = exc('ChunkLoadError', 'Failed to load chunk /_next/static/immutable/chunks/1y93nj_hv2pw3.css from module 94713',
      'https://agenticdevelopercodereviews.com/_next/static/immutable/chunks/turbopack-1sw8j8ptr3fae.js')
    expect(noiseReason(chunk, { userAgent: CHROME })).toBe('stale-deploy')
  })

  it.each([
    'Failed to fetch',
    'Load failed',
    'NetworkError when attempting to fetch resource.',
    // as Sentry's fetch instrumentation rewrites them (enhanceFetchErrorMessages: 'always')
    'Failed to fetch (auth.agenticdeveloperhub.com)',
    'Load failed (api.example.com:8443)',
    'NetworkError when attempting to fetch resource. (api.example.com)',
  ])(
    'drops the browser network failure "%s"',
    (value) => {
      expect(noiseReason(exc('TypeError', value, 'https://agenticdeveloperbilling.com/_next/static/x.js'), { userAgent: CHROME }))
        .toBe('network')
    },
  )

  it('keeps a network-shaped message with anything else after it', () => {
    expect(noiseReason(exc('TypeError', 'Failed to fetch (profile is undefined)', 'https://a.com/app.js'), { userAgent: CHROME }))
      .toBeNull()
  })

  it('keeps a TypeError that merely mentions fetching', () => {
    expect(noiseReason(exc('TypeError', 'Failed to fetch user: profile is undefined', 'https://a.com/app.js'), { userAgent: CHROME }))
      .toBeNull()
  })
})
