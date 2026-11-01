import type { ReactElement } from 'react'
import type { CopyText } from './types'

/**
 * One `CopyText`, rendered: a string as text, an `{ html }` value as the markup content-buildr
 * rendered from the site's markdown. That markup is the site's own, written by its author and
 * generated at build time, so it is trusted the way the rest of the site's source is.
 */
export function Words({ text }: { text: CopyText }): ReactElement {
  return typeof text === 'string' ? <>{text}</> : <span dangerouslySetInnerHTML={{ __html: text.html }} />
}

const ENTITIES: Record<string, string> = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'", '#39': "'", '#x27': "'", nbsp: '\u00a0' }

/**
 * The same `CopyText` as Markdown, for `/index.md`: links, bold, emphasis and code — the inline
 * markup content-buildr writes — and its entities decoded. Any other tag or entity is refused
 * rather than dropped, so markup the site starts writing fails the build instead of vanishing
 * from the text.
 */
export function wordsMarkdown(text: CopyText): string {
  if (typeof text === 'string') return text
  const markdown = text.html
    .replace(/<a\s+href="([^"]*)"[^>]*>([\s\S]*?)<\/a>/g, (_, href: string, inner: string) => `[${inner}](${href})`)
    .replace(/<\/?(b|strong)>/g, '**')
    .replace(/<\/?em>/g, '*')
    .replace(/<\/?code>/g, '`')
  const tag = /<\/?[a-z][^>]*>/i.exec(markdown)
  if (tag !== null) throw new Error(`wordsMarkdown: no Markdown for ${tag[0]} in ${JSON.stringify(text.html)}`)
  return markdown.replace(/&([a-z]+|#39|#x27);/g, (entity, name: string) => {
    const value = ENTITIES[name]
    if (value === undefined) throw new Error(`wordsMarkdown: no Markdown for ${entity} in ${JSON.stringify(text.html)}`)
    return value
  })
}
