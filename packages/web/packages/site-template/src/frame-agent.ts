import { landingLlmsTxt, landingMarkdown, withWebSite } from '@agenticdevelopertoolkit/landing'
import type { JsonLdValue } from '@agenticdevelopertoolkit/landing'
import type { FrameConfig, FrameCopy, FrameSitemapRoute } from './types'

// What a content site tells agents and answer engines, written once from the same copy, config
// and landing data its pages are rendered from: its structured data, its `/llms.txt`, and `/`
// as Markdown at `/index.md`. The landing kit does the writing; this only says which of the
// site's words go where.

function origin(config: FrameConfig): string {
  return config.siteUrl.replace(/\/+$/, '')
}

/** The root layout's structured data: a `WebSite` from the site's name, origin and description,
 *  ahead of whatever `site.json`'s `jsonLd` declares. A site that already declares a `WebSite`
 *  keeps its own. */
export function frameJsonLd(copy: FrameCopy, config: FrameConfig): JsonLdValue {
  return withWebSite({ name: copy.name, url: origin(config), description: copy.description }, config.jsonLd)
}

/** `/llms.txt`: the site's name and description, its pages — `/` and its Markdown, the
 *  sitemap's listed paths, then the routes it computes — and the sections of `/`. */
export function frameLlmsTxt(
  copy: FrameCopy,
  config: FrameConfig,
  landing: object,
  computed: readonly FrameSitemapRoute[] = [],
): string {
  return landingLlmsTxt(
    { name: copy.name, url: origin(config), description: copy.description },
    [...config.sitemap, ...computed.map((route) => route.path)],
    landing,
  )
}

/** `/index.md`: `/`'s words as Markdown, with its links made absolute, and the words of the
 *  bands the site renders itself from `slots` (site.json's `slotMarkdown`). */
export function frameLandingMarkdown(
  config: FrameConfig,
  landing: object,
  slots: Readonly<Record<string, string>> = {},
): string {
  return landingMarkdown(landing, { origin: origin(config), slots })
}
