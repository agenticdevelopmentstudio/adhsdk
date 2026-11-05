import { siteIdentity } from '@adh-sdk/adh-registry/seo'
import { landingLlmsTxt, landingMarkdown } from '@adh-sdk/landing'
import { siteSitemapRoutes, type SiteConfig } from './SiteConfig'

// What a family site tells agents and answer engines, from the same config and landing data
// its pages are built from. `app/llms.txt/route.ts` and `app/index.md/route.ts` are mounts of
// these, identical on every site like the rest of `app/`.

/** `/llms.txt`: the registry's name for the site, its `seo.description`, `/` and its Markdown,
 *  the sitemap's other routes, and the sections of `/`. */
export async function siteLlmsTxt(site: SiteConfig, landing: object): Promise<string> {
  const routes = await siteSitemapRoutes(site)
  return landingLlmsTxt(
    { ...siteIdentity(site.id), description: site.seo.description },
    routes.map((route) => route.path),
    landing,
  )
}

/** `/index.md`: `/`'s words as Markdown, its links resolved against the production origin. */
export function siteLandingMarkdown(site: SiteConfig, landing: object): string {
  return landingMarkdown(landing, { origin: siteIdentity(site.id).url })
}
