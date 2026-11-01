import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it } from 'vitest'
import { JsonLd, landingLlmsTxt, landingMarkdown, landingSectionLinks, llmsTxt, pathTitle, withWebSite } from '../index'
import type { LandingBlock } from '../index'

// One block of every kind, keyed by kind: a kind added to LandingBlock without an entry here
// is a type error, so a block the Markdown cannot render cannot be added silently.
const EVERY_BLOCK: Record<LandingBlock['kind'], object> = {
  Lede: { kind: 'Lede', children: { $inline: ['See ', { t: 'link', href: '/details', c: ['the details'] }, '.'] } },
  Trust: { kind: 'Trust', items: ['One', { $inline: [{ t: 'b', c: ['Two'] }] }] },
  Cards: { kind: 'Cards', items: [{ kicker: '01', title: 'A card', body: ['Its body.'] }] },
  Points: { kind: 'Points', entries: [{ term: 'Term', detail: 'Detail.' }, { detail: 'Bare.' }], ordered: true },
  Code: { kind: 'Code', text: 'npm i x' },
  Shot: { kind: 'Shot', title: 'The board', caption: 'What it shows.' },
  Table: { kind: 'Table', caption: 'Plans', columns: ['Plan', 'Price'], rows: [['Free', '$0']] },
  StatusPill: { kind: 'StatusPill', children: 'In beta' },
  Rule: { kind: 'Rule', steps: [{ term: 'When', detail: 'a session starts' }] },
  Stats: { kind: 'Stats', entries: [{ term: 'Fast', detail: 'very' }] },
  Versus: { kind: 'Versus', them: { title: 'Them', points: ['Slow'] }, us: { title: 'Us', lede: 'Quick.' } },
  Chips: { kind: 'Chips', entries: [{ label: 'Claude' }] },
  Checklist: { kind: 'Checklist', groups: [{ heading: 'More', items: [{ text: 'Export' }, { text: 'Sync', soon: true }] }] },
  Faq: { kind: 'Faq', entries: [{ question: 'Is it free?', answer: ['Yes.'] }] },
  Closer: { kind: 'Closer', title: 'Try it', body: ['Now.'] },
  Cta: { kind: 'Cta', buttons: [{ href: '/signup', label: 'Sign up' }] },
  Roadmap: { kind: 'Roadmap', eyebrow: 'Next', children: [{ kind: 'Lede', children: 'Later.' }] },
}

const DATA = {
  $generated: 'GENERATED — do not edit.',
  hero: { headline: { $inline: ['Agentic ', { t: 'b', c: ['Hub'] }] }, tagline: 'Plain words.', blocks: [] },
  sections: [
    { id: 'all', eyebrow: 'Everything', title: 'Every block', blocks: Object.values(EVERY_BLOCK) },
    { id: 'band', eyebrow: 'Rendered by the site', slot: true, blocks: [] },
  ],
}

describe('landingMarkdown', () => {
  const md = landingMarkdown(DATA, { origin: 'https://x.example/' })

  it('opens with the hero, as the page does', () => {
    expect(md.startsWith('# Agentic **Hub**\n\nPlain words.\n\n## Everything\n\n**Every block**')).toBe(true)
  })

  it('renders every block kind', () => {
    for (const line of [
      'See [the details](https://x.example/details).',
      '- One\n- **Two**',
      '### 01: A card\n\nIts body.',
      '1. **Term:** Detail.\n2. Bare.',
      '```\nnpm i x\n```',
      '*The board:* What it shows.',
      '**Plans**\n\n| Plan | Price |\n| --- | --- |\n| Free | $0 |',
      'In beta',
      '1. **When:** a session starts',
      '- **Fast:** very',
      '### Them\n\n- Slow\n\n### Us\n\nQuick.',
      '- Claude',
      '### More\n\n- Export\n- Sync (soon)',
      '### Is it free?\n\nYes.',
      '### Try it\n\nNow.',
      '- [Sign up](https://x.example/signup)',
      '### Next\n\nLater.',
    ]) {
      expect(md).toContain(line)
    }
  })

  it('leaves out a section the site renders itself, which has no words in the data', () => {
    expect(md).not.toContain('Rendered by the site')
  })

  it('writes a slot section from the Markdown the site hands it', () => {
    const filled = landingMarkdown(DATA, { slots: { band: '### A product\n\nWhat it does.\n' } })
    expect(filled).toContain('## Rendered by the site\n\n### A product\n\nWhat it does.\n')
  })

  it('writes the site\'s Markdown in place of a section\'s blocks', () => {
    const md = landingMarkdown(DATA, { slots: { all: 'Its own words.' } })
    expect(md).toContain('## Everything\n\n**Every block**\n\nIts own words.\n')
    expect(md).not.toContain('Its body.')
  })

  it('refuses slot Markdown for a section that does not exist', () => {
    expect(() => landingMarkdown(DATA, { slots: { nope: 'x' } })).toThrow(/"nope"/)
  })

  it('leaves links alone without an origin', () => {
    expect(landingMarkdown(DATA)).toContain('[the details](/details)')
  })

  it('refuses a block kind it has no rendering for', () => {
    const bad = { hero: { headline: 'x', tagline: '', blocks: [{ kind: 'Mystery' }] }, sections: [] }
    expect(() => landingMarkdown(bad)).toThrow(/Mystery/)
  })
})

describe('llmsTxt', () => {
  it('writes the llmstxt.org shape and skips an empty section', () => {
    const text = llmsTxt({
      name: 'Site',
      summary: 'What it is,\n  in one line.',
      sections: [
        { heading: 'Pages', links: [{ title: 'Home', url: 'https://x.example/', note: 'the landing page' }] },
        { heading: 'Empty', links: [] },
      ],
    })
    expect(text).toBe('# Site\n\n> What it is, in one line.\n\n## Pages\n\n- [Home](https://x.example/): the landing page\n')
  })

  it('names a path by its last segment', () => {
    expect(pathTitle('/')).toBe('Home')
    expect(pathTitle('/introduction/overview')).toBe('Overview')
    expect(pathTitle('/code-reviews')).toBe('Code reviews')
  })

  it('writes a landing site’s index: `/` and its Markdown, its other paths, its sections', () => {
    const site = { name: 'Site', url: 'https://x.example/', description: 'What it is.' }
    expect(landingLlmsTxt(site, ['/', '/pricing'], DATA)).toBe(
      [
        '# Site',
        '> What it is.',
        '## Pages\n\n- [Home](https://x.example/): https://x.example/index.md as Markdown\n- [Pricing](https://x.example/pricing)',
        '## Home page sections\n\n- [Everything](https://x.example/#all)\n- [Rendered by the site](https://x.example/#band)',
      ].join('\n\n') + '\n',
    )
  })

  it('links each landing section to its anchor', () => {
    expect(landingSectionLinks(DATA, 'https://x.example/')).toEqual([
      { title: 'Everything', url: 'https://x.example/#all' },
      { title: 'Rendered by the site', url: 'https://x.example/#band' },
    ])
  })
})

describe('structured data', () => {
  const site = { name: 'Site', url: 'https://x.example', description: 'What it is.' }

  it('adds a WebSite ahead of the site’s own entities', () => {
    const doc = withWebSite(site, { '@context': 'https://schema.org', '@graph': [{ '@type': 'Organization', name: 'O' }] })
    expect(doc).toEqual({
      '@context': 'https://schema.org',
      '@graph': [
        { '@type': 'WebSite', '@id': 'https://x.example/#website', ...site },
        { '@type': 'Organization', name: 'O' },
      ],
    })
  })

  it('keeps a WebSite the site already declares', () => {
    const own = { '@type': 'WebSite', name: 'Mine' }
    expect(withWebSite(site, { '@context': 'https://schema.org', ...own })['@graph']).toEqual([own])
  })

  it('escapes `<` so the data cannot close its script', () => {
    const html = renderToStaticMarkup(<JsonLd data={{ name: '</script><b>' }} />)
    expect(html).toBe('<script type="application/ld+json">{"name":"\\u003c/script>\\u003cb>"}</script>')
  })
})
