// WRITTEN by @adh-sdk/site-template's assembler — do not edit.
import type { MetadataRoute } from 'next'
import { frameSitemap } from '@adh-sdk/site-template'
import { config } from '../src/site/config'
import { sitemapRoutes } from '../src/site/sitemap'

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  return frameSitemap(config, await sitemapRoutes())
}
