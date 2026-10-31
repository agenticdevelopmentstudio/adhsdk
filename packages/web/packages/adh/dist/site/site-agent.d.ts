import { type SiteConfig } from './SiteConfig';
/** `/llms.txt`: the registry's name for the site, its `seo.description`, `/` and its Markdown,
 *  the sitemap's other routes, and the sections of `/`. */
export declare function siteLlmsTxt(site: SiteConfig, landing: object): Promise<string>;
/** `/index.md`: `/`'s words as Markdown, its links resolved against the production origin. */
export declare function siteLandingMarkdown(site: SiteConfig, landing: object): string;
//# sourceMappingURL=site-agent.d.ts.map