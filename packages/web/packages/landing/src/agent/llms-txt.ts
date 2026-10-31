/**
 * `/llms.txt`: a site's short Markdown index for language models, in the shape llmstxt.org
 * proposes — an H1 with the site's name, a blockquote summary, then H2 sections of links.
 *
 * The fields are the site's own: its name and description, the page list its sitemap already
 * keeps, and the sections of its landing page. Nothing here is written for the file alone, so
 * it cannot drift from what the site says everywhere else.
 */

export interface LlmsLink {
  title: string
  url: string
  /** What the link holds, after a colon, when the title alone does not say. */
  note?: string
}

export interface LlmsSection {
  heading: string
  links: LlmsLink[]
}

export interface LlmsTxt {
  name: string
  summary: string
  sections: LlmsSection[]
}

/** The file's text. A section with no links is left out. */
export function llmsTxt(doc: LlmsTxt): string {
  const out = [`# ${doc.name}`, `> ${doc.summary.replace(/\s*\n\s*/g, ' ')}`]
  for (const section of doc.sections) {
    if (section.links.length === 0) continue
    const links = section.links.map((l) => `- [${l.title}](${l.url})${l.note === undefined ? '' : `: ${l.note}`}`)
    out.push(`## ${section.heading}\n\n${links.join('\n')}`)
  }
  return `${out.join('\n\n')}\n`
}

/** A sitemap path's link title, from its last segment: `/` is "Home", `/introduction/overview`
 *  is "Overview". The sitemap lists paths, not names, and this is the name the path gives. */
export function pathTitle(path: string): string {
  const last = path.split('/').filter((s) => s !== '').pop()
  if (last === undefined) return 'Home'
  const words = decodeURIComponent(last).replace(/[-_]+/g, ' ')
  return words.charAt(0).toUpperCase() + words.slice(1)
}

/** The landing page's sections as links to their anchors on `/`, labelled as the page's own
 *  index labels them. A section the site renders itself (`slot`) is still a section of the
 *  page, so it is listed too. */
export function landingSectionLinks(data: object, origin: string): LlmsLink[] {
  const sections = ((data as { sections?: { id: string; eyebrow: string }[] }).sections ?? [])
  const base = origin.replace(/\/+$/, '')
  return sections.map((s) => ({ title: s.eyebrow, url: `${base}/#${s.id}` }))
}

/** A landing-led site's whole `/llms.txt`: its name and description, a Pages section — `/`
 *  (noting its Markdown at `/index.md`) and then `paths`, the rest of its sitemap — and the
 *  sections of `/`. The one shape every site in the family writes, whichever frame it uses. */
export function landingLlmsTxt(
  site: { name: string; url: string; description: string },
  paths: readonly string[],
  landing: object,
): string {
  const base = site.url.replace(/\/+$/, '')
  return llmsTxt({
    name: site.name,
    summary: site.description,
    sections: [
      {
        heading: 'Pages',
        links: [
          { title: 'Home', url: `${base}/`, note: `${base}/index.md as Markdown` },
          ...paths.filter((path) => path !== '/').map((path) => ({ title: pathTitle(path), url: `${base}${path}` })),
        ],
      },
      { heading: 'Home page sections', links: landingSectionLinks(landing, base) },
    ],
  })
}
