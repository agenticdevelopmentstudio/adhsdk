// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit. Change the
// skeleton in the toolkit and re-assemble.
import { frameLlmsTxt } from '@agenticdevelopertoolkit/site-template'
import type { FrameCopy } from '@agenticdevelopertoolkit/site-template'
import siteCopy from '../../src/content/site/site.json'
import landing from '../../src/landing.json'
import { config } from '../../src/site/config'
import { sitemapRoutes } from '../../src/site/sitemap'

// Written once, at build time, like the sitemap it lists.
export const dynamic = 'force-static'

// Typed for the reason the root layout gives.
const copy: FrameCopy = siteCopy

/** `/llms.txt`: the site's index for language models (llmstxt.org). */
export async function GET(): Promise<Response> {
  return new Response(frameLlmsTxt(copy, config, landing, await sitemapRoutes()), {
    headers: { 'Content-Type': 'text/plain; charset=utf-8' },
  })
}
