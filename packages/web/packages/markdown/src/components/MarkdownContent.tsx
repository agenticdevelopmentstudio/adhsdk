// NO "use client" — this is a React Server Component. It runs the SAME pipeline as
// {@link MarkdownRenderer} but on the server (at build / request time), so the rendered HTML is in
// the SSR payload: crawlable, and no client "Rendering…" flash. Use this in server components and
// prerendered routes (the docs sites). Reach for the client MarkdownRenderer only when the content
// is chosen at runtime on the client with no server round-trip.

import { processMarkdown } from '../lib/process-markdown'
import { proseClassName, type ProseMeasure } from '../lib/prose-class'

export interface MarkdownContentProps {
  /** Raw markdown string (frontmatter, if any, is stripped). */
  content: string
  /** Extra class(es) appended to the always-present `adh-mv-prose`. */
  className?: string
  /** How wide the prose runs: a ~72ch reading column (default) or the container's width. */
  measure?: ProseMeasure
}

/**
 * Server-render markdown to sanitised, shiki-highlighted HTML. Same output shape and CSS
 * (`adh-mv-prose`) as {@link MarkdownRenderer}, so a document renders identically whichever path
 * a host uses. Async (RSC): `await`s the shared unified pipeline; the shiki highlighter + frozen
 * processor are module-cached, so repeated calls in one process reuse them.
 */
export async function MarkdownContent({ content, className, measure = 'reading' }: MarkdownContentProps) {
  const { html } = await processMarkdown(content)
  return (
    <div
      className={proseClassName({ measure, className })}
      // `html` is ALWAYS rehype-sanitize output (processMarkdown's final step) — XSS-safe sink (c6).
      dangerouslySetInnerHTML={{ __html: html }}
    />
  )
}
