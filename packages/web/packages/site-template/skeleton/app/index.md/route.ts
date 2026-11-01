// WRITTEN by @agenticdevelopertoolkit/site-template's assembler — do not edit. Change the
// skeleton in the toolkit and re-assemble.
import { frameLandingMarkdown } from '@agenticdevelopertoolkit/site-template'
import landing from '../../src/landing.json'
import { config } from '../../src/site/config'
import { slotMarkdown } from '../../src/site/markdown'

// Written once, at build time, from the same data `/` renders.
export const dynamic = 'force-static'

/** `/index.md`: `/`'s words as Markdown, for agents that would rather read text. */
export function GET(): Response {
  return new Response(frameLandingMarkdown(config, landing, slotMarkdown), {
    headers: { 'Content-Type': 'text/markdown; charset=utf-8' },
  })
}
