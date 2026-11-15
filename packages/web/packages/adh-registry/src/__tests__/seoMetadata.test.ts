import { afterEach, describe, expect, it, vi } from 'vitest'
import type { SiteId } from '../sites/registry'

// `NOINDEX_BUILD` is read once at module load, so each vector loads a fresh copy of the
// module under its own NEXT_PUBLIC_DEPLOYMENT_ENV.
async function load() {
  vi.resetModules()
  return import('../seo/metadata')
}

afterEach(() => {
  vi.unstubAllEnvs()
})

const hubSeo = { title: 'T', description: 'D' }
const NOPE = 'nope' as unknown as SiteId
const PROD_ROBOTS = {
  rules: [{ userAgent: '*', allow: '/' }],
  sitemap: 'https://agenticdeveloperhub.com/sitemap.xml',
  host: 'https://agenticdeveloperhub.com',
}
const BLOCK_ALL = { rules: [{ userAgent: '*', disallow: '/' }] }

describe('seo/metadata conformance vectors', () => {
  it('site-registry-seo-001: title, description, brand and origin come from the call and the registry', async () => {
    const { siteMetadata } = await load()
    const md = siteMetadata('hub', hubSeo)
    expect(md.title).toBe('T')
    expect(md.description).toBe('D')
    expect(md.openGraph).toBeTruthy()
    expect(md.applicationName).toBe('Agentic Developer Hub')
    expect((md.metadataBase as URL).origin).toBe('https://agenticdeveloperhub.com')
  })

  it('site-registry-seo-002: canonicalOnly returns exactly the canonical alternate', async () => {
    const { canonicalOnly } = await load()
    expect(canonicalOnly('/')).toEqual({ alternates: { canonical: '/' } })
  })

  it('site-registry-seo-003: ogImageSize is 1200 by 630', async () => {
    const { ogImageSize } = await load()
    expect(ogImageSize).toEqual({ width: 1200, height: 630 })
  })

  it('site-registry-seo-004: a path becomes the canonical and og:url, against the site origin', async () => {
    const { siteMetadata } = await load()
    const md = siteMetadata('cookbook', { ...hubSeo, path: '/pricing' })
    expect(md.alternates?.canonical).toBe('/pricing')
    expect((md.openGraph as { url?: string }).url).toBe('/pricing')
    expect((md.metadataBase as URL).origin).toBe('https://agenticdevelopercookbook.com')
  })

  it('site-registry-seo-005: an empty path omits alternates and og:url', async () => {
    const { siteMetadata } = await load()
    const md = siteMetadata('hub', { ...hubSeo, path: '' })
    expect('alternates' in md).toBe(false)
    expect('url' in (md.openGraph as object)).toBe(false)
  })

  it('site-registry-seo-006: an empty keywords array is kept, not omitted', async () => {
    const { siteMetadata } = await load()
    const md = siteMetadata('hub', { ...hubSeo, keywords: [] })
    expect(md.keywords).toEqual([])
  })

  it('site-registry-seo-007: with no card the default image is used in Open Graph and Twitter', async () => {
    const { siteMetadata } = await load()
    const md = siteMetadata('hub', hubSeo)
    expect((md.openGraph as { images: unknown[] }).images[0]).toEqual({
      url: '/opengraph-image.png',
      width: 1200,
      height: 630,
    })
    expect((md.twitter as { images: unknown[] }).images[0]).toBe('/opengraph-image.png')
  })

  it('site-registry-seo-008: a given card replaces the default image in both blocks', async () => {
    const { siteMetadata } = await load()
    const md = siteMetadata('devteam', { ...hubSeo, card: '/devteam/og.png' })
    expect((md.openGraph as { images: { url: string }[] }).images[0]!.url).toBe('/devteam/og.png')
    expect((md.twitter as { images: unknown[] }).images[0]).toBe('/devteam/og.png')
  })

  it('site-registry-seo-009: an unresolvable site falls back to the hub brand and origin', async () => {
    const { siteMetadata } = await load()
    const md = siteMetadata(NOPE, hubSeo)
    expect(md.applicationName).toBe('Agentic Developer Hub')
    expect((md.metadataBase as URL).origin).toBe('https://agenticdeveloperhub.com')
  })

  it('site-registry-seo-010: a testing build says noindex and nofollow', async () => {
    vi.stubEnv('NEXT_PUBLIC_DEPLOYMENT_ENV', 'testing')
    const { siteMetadata } = await load()
    const robots = siteMetadata('hub', hubSeo).robots as Record<string, any>
    expect(robots.index).toBe(false)
    expect(robots.follow).toBe(false)
    expect(robots.googleBot.index).toBe(false)
    expect(robots.googleBot.follow).toBe(false)
    expect(robots.googleBot['max-image-preview']).toBe('large')
  })

  it('site-registry-seo-011: a build with no tier variable says index and follow', async () => {
    vi.stubEnv('NEXT_PUBLIC_DEPLOYMENT_ENV', '')
    const { siteMetadata } = await load()
    const robots = siteMetadata('hub', hubSeo).robots as Record<string, any>
    expect(robots.index).toBe(true)
    expect(robots.follow).toBe(true)
    expect(robots.googleBot.index).toBe(true)
    expect(robots.googleBot.follow).toBe(true)
    expect(robots.googleBot['max-image-preview']).toBe('large')
  })

  it('site-registry-seo-012: the production host gets allow, sitemap and host', async () => {
    const { siteRobots } = await load()
    expect(siteRobots('hub', 'agenticdeveloperhub.com')).toEqual(PROD_ROBOTS)
  })

  it('site-registry-seo-013: the www form and a port suffix both count as production', async () => {
    const { siteRobots } = await load()
    expect(siteRobots('hub', 'www.agenticdeveloperhub.com')).toEqual(PROD_ROBOTS)
    expect(siteRobots('hub', 'agenticdeveloperhub.com:3000')).toEqual(PROD_ROBOTS)
  })

  it('site-registry-seo-014: a staging host is blocked entirely', async () => {
    const { siteRobots } = await load()
    expect(siteRobots('hub', 'staging.agenticdeveloperhub.com')).toEqual(BLOCK_ALL)
  })

  it('site-registry-seo-015: an unresolvable site is blocked whatever the host', async () => {
    const { siteRobots } = await load()
    expect(siteRobots(NOPE, 'agenticdeveloperhub.com')).toEqual(BLOCK_ALL)
  })

  it('site-registry-seo-016: a non-empty disallow list is added verbatim, an empty one is omitted', async () => {
    const { siteRobots } = await load()
    const withList = siteRobots('hub', 'agenticdeveloperhub.com', { disallow: ['/admin'] })
    expect(withList.rules).toEqual([{ userAgent: '*', allow: '/', disallow: ['/admin'] }])
    const empty = siteRobots('hub', 'agenticdeveloperhub.com', { disallow: [] })
    expect('disallow' in (empty.rules as object[])[0]!).toBe(false)
  })

  it('site-registry-seo-017: sitemap entries map routes with defaults and one shared lastModified', async () => {
    const { siteSitemap } = await load()
    const [a, b] = siteSitemap('cookbook', [
      { path: '/' },
      { path: '/pricing', priority: 0.9, changeFrequency: 'weekly' },
    ])
    expect(a).toMatchObject({
      url: 'https://agenticdevelopercookbook.com/',
      changeFrequency: 'monthly',
      priority: 1,
    })
    expect(a!.lastModified).toBeInstanceOf(Date)
    expect(b).toMatchObject({
      url: 'https://agenticdevelopercookbook.com/pricing',
      changeFrequency: 'weekly',
      priority: 0.9,
    })
    expect(b!.lastModified).toBe(a!.lastModified)
  })

  it('site-registry-seo-018: an empty route list gives an empty sitemap', async () => {
    const { siteSitemap } = await load()
    expect(siteSitemap('hub', [])).toEqual([])
  })

  it('site-registry-seo-019: a priority of zero is kept, not replaced by the default', async () => {
    const { siteSitemap } = await load()
    expect(siteSitemap('hub', [{ path: '/x', priority: 0 }])[0]!.priority).toBe(0)
  })
})
