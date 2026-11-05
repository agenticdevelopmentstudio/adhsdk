/**
 * How wide rendered prose runs.
 *
 * - `reading` (the default): a ~72ch column, the comfortable line length for a page you read.
 * - `fill`: as wide as its container. For a tool pane showing a file, where the window is the
 *   reader's chosen width and a narrow column just wastes it.
 */
export type ProseMeasure = 'reading' | 'fill'

export interface ProseClassOptions {
  /** Wrap long lines in code blocks instead of scrolling them sideways. */
  wrap?: boolean
  measure?: ProseMeasure
  /** Extra class(es) appended after the package's own. */
  className?: string
}

/**
 * The class list every prose surface (`MarkdownRenderer`, `MarkdownContent`, `JsonRenderer`)
 * puts on its root, so the modifiers mean the same thing wherever a document is rendered.
 */
export function proseClassName({ wrap = false, measure = 'reading', className }: ProseClassOptions = {}): string {
  const classes = ['adh-mv-prose']
  if (wrap) classes.push('adh-mv-prose--wrap')
  if (measure === 'fill') classes.push('adh-mv-prose--fill')
  if (className) classes.push(className)
  return classes.join(' ')
}
