/**
 * A landing page as Markdown, for the agents and answer engines that would rather read text
 * than a deck of screens.
 *
 * It reads the page's DATA — the `landing.json` content-buildr writes, before
 * `landingFromData` turns it into ReactNodes — so the Markdown and the rendered page come from
 * the same words and cannot say different things. Every block kind `LandingBlock` names has a
 * rendering here; a kind this file does not know is refused rather than dropped, so a block
 * added to the kit without a rendering here fails a test instead of vanishing from the text.
 *
 * A section whose body the SITE renders (`slot`) has no words in the data, and is left out
 * rather than printed as a heading with nothing under it.
 */

type Rich = unknown

interface InlineElement {
  t: 'b' | 'em' | 'code' | 'a' | 'link'
  href?: string
  c: Rich[]
}

export interface LandingMarkdownOptions {
  /** The site's origin, which a root-relative link (`/details`) is resolved against so the
   *  Markdown still points somewhere when it is read away from the site. */
  origin?: string
}

/** The page's `landing.json`, as one Markdown document: the hero, then each section. */
export function landingMarkdown(data: object, options: LandingMarkdownOptions = {}): string {
  const page = data as { hero?: Record<string, unknown>; sections?: Record<string, unknown>[] }
  const out: string[] = []
  const hero = page.hero ?? {}
  const headline = text(hero.headline, options)
  if (headline !== '') out.push(`# ${headline}`)
  const tagline = text(hero.tagline, options)
  if (tagline !== '') out.push(tagline)
  out.push(...blocks(hero.blocks, 2, options))
  for (const section of page.sections ?? []) {
    const body = blocks(section.blocks, 3, options)
    const title = text(section.title, options)
    if (body.length === 0 && title === '') continue
    out.push(`## ${text(section.eyebrow, options)}`)
    if (title !== '') out.push(`**${title}**`)
    out.push(...body)
  }
  return `${out.join('\n\n')}\n`
}

/** A rich value — a string, or content-buildr's `{ "$inline": [nodes] }` — as Markdown text. */
function text(value: Rich, options: LandingMarkdownOptions): string {
  if (value === undefined || value === null) return ''
  if (typeof value === 'string') return value
  if (Array.isArray(value)) return value.map((v) => text(v, options)).join('')
  if (typeof value === 'object' && '$inline' in value) {
    return text((value as { $inline: Rich[] }).$inline, options)
  }
  const node = value as InlineElement
  const inner = text(node.c, options)
  switch (node.t) {
    case 'b':
      return `**${inner}**`
    case 'em':
      return `*${inner}*`
    case 'code':
      return `\`${inner}\``
    case 'a':
    case 'link':
      return `[${inner}](${href(node.href ?? '', options)})`
    default:
      throw new Error(`landingMarkdown: unknown inline node ${JSON.stringify(value)}`)
  }
}

function href(target: string, options: LandingMarkdownOptions): string {
  if (options.origin === undefined || !target.startsWith('/') || target.startsWith('//')) return target
  return `${options.origin.replace(/\/+$/, '')}${target}`
}

function list(items: string[], ordered = false): string {
  return items.map((item, i) => `${ordered ? `${i + 1}.` : '-'} ${item}`).join('\n')
}

/** Each block as one or more Markdown paragraphs; `depth` is the heading level a block's own
 *  titles take, one below the section that holds it. */
function blocks(value: unknown, depth: number, options: LandingMarkdownOptions): string[] {
  const hashes = '#'.repeat(Math.min(depth, 6))
  const t = (v: Rich): string => text(v, options)
  const paragraphs = (v: unknown): string[] => ((v ?? []) as Rich[]).map(t)
  const term = (entry: { term?: Rich; detail: Rich }): string => {
    const name = t(entry.term)
    return name === '' ? t(entry.detail) : `**${name}:** ${t(entry.detail)}`
  }
  const out: string[] = []
  for (const block of (value ?? []) as Record<string, unknown>[]) {
    switch (block.kind) {
      case 'Lede':
      case 'StatusPill':
        out.push(t(block.children))
        break
      case 'Trust':
        out.push(list(paragraphs(block.items)))
        break
      case 'Cards':
        for (const card of block.items as Record<string, unknown>[]) {
          const kicker = t(card.kicker)
          out.push(`${hashes} ${kicker === '' ? '' : `${kicker}: `}${t(card.title)}`, ...paragraphs(card.body))
        }
        break
      case 'Points':
        out.push(list((block.entries as { term?: Rich; detail: Rich }[]).map(term), block.ordered === true))
        break
      case 'Rule':
        out.push(list((block.steps as { term: Rich; detail: Rich }[]).map(term), true))
        break
      case 'Stats':
        out.push(list((block.entries as { term: Rich; detail: Rich }[]).map(term)))
        break
      case 'Code':
        out.push(`\`\`\`\n${block.text as string}\n\`\`\``)
        break
      case 'Shot':
        out.push(`*${t(block.title)}:* ${t(block.caption)}`)
        break
      case 'Table': {
        const columns = paragraphs(block.columns)
        const caption = t(block.caption)
        out.push(
          [
            ...(caption === '' ? [] : [`**${caption}**`, '']),
            `| ${columns.join(' | ')} |`,
            `| ${columns.map(() => '---').join(' | ')} |`,
            ...(block.rows as Rich[][]).map((row) => `| ${row.map(t).join(' | ')} |`),
          ].join('\n'),
        )
        break
      }
      case 'Versus':
        for (const side of [block.them, block.us] as Record<string, unknown>[]) {
          out.push(`${hashes} ${t(side.title)}`, t(side.lede))
          const points = paragraphs(side.points)
          if (points.length > 0) out.push(list(points))
        }
        break
      case 'Chips':
        out.push(list((block.entries as { label: Rich }[]).map((e) => t(e.label))))
        break
      case 'Checklist':
        for (const group of block.groups as { heading: Rich; items: { text: Rich; soon?: boolean }[] }[]) {
          out.push(
            `${hashes} ${t(group.heading)}`,
            list(group.items.map((item) => `${t(item.text)}${item.soon === true ? ' (soon)' : ''}`)),
          )
        }
        break
      case 'Faq':
        for (const entry of block.entries as { question: Rich; answer: Rich[] }[]) {
          out.push(`${hashes} ${t(entry.question)}`, ...paragraphs(entry.answer))
        }
        break
      case 'Closer':
        out.push(`${hashes} ${t(block.title)}`, ...paragraphs(block.body))
        break
      case 'Cta':
        out.push(list((block.buttons as { href: string; label: Rich }[]).map((b) => `[${t(b.label)}](${href(b.href, options)})`)))
        break
      case 'Roadmap': {
        const eyebrow = t(block.eyebrow)
        if (eyebrow !== '') out.push(`${hashes} ${eyebrow}`)
        out.push(...blocks(block.children, depth + 1, options))
        break
      }
      default:
        throw new Error(`landingMarkdown: no Markdown for block kind ${JSON.stringify(block.kind)}`)
    }
  }
  return out.filter((p) => p !== '')
}
