import { themes, type ThemeKey } from './manifest'

const GLOBAL_ID = 'adh-sdk-theme'
const SCOPED_ID = 'adh-sdk-theme-scoped'

/** One id per scope, not one id for all scoped blocks. A page can carry several
 *  scoped themes at once (a chat theming itself, plus a host app theming the
 *  wrapper it sits in), and a shared id makes those duplicates — invalid HTML, and
 *  `getElementById` silently resolves to whichever happens to come first. */
export const scopedId = (scope: string): string => {
  const slug = scope.replace(/[^a-zA-Z0-9_-]+/g, '-').replace(/(^-+|-+$)/g, '').toLowerCase()
  // The slug drops punctuation and case, so `.host-a`, `#host-a` and `.Host-A` would
  // collide. A scope that is not already its own slug gets a hash of the raw selector,
  // which keeps every distinct scope on a distinct id.
  return slug === scope ? `${SCOPED_ID}-${slug}` : `${SCOPED_ID}-${slug}-${fnv1a(scope)}`
}

/** 32-bit FNV-1a of a string, base 36: short, stable, dependency-free. */
const fnv1a = (text: string): string => {
  let hash = 0x811c9dc5
  for (let i = 0; i < text.length; i++) {
    hash ^= text.charCodeAt(i)
    hash = Math.imul(hash, 0x01000193)
  }
  return (hash >>> 0).toString(36)
}

const IMPORT_RE = /^@import\s+url\([^)]+\);\s*$/gm
// Full-palette themes — every theme with a complete M3 role layer — anchor their token
// blocks at `html:root` (dark, the default) and `html:root[data-color-mode]:not(.dark)`
// (light). The `:root` patterns below cannot see either: their `:root` is preceded by
// `html`, not by a line start or a comma. Without these two the whole palette of every
// full-palette theme is dropped in scoped mode and the scope silently keeps the host page's
// colours — the failure looks like "the theme did nothing", with no error anywhere.
//
// QUALIFIED before bare: an anchor may carry any run of document-state qualifiers —
// `[data-color-mode]:not(.dark)`, `[data-contrast='high']`, or both at once (a dark-always
// theme like fishlamp names every combination it has to out-specify). Those qualifiers
// describe the DOCUMENT, not the scoped element, so they move onto an `html` ancestor and
// the scope descends from it. Matching only the one light form left every other shape
// unrewritten — and rewrote `html:root[data-color-mode]:not(.dark)[data-contrast='high']`
// to `… :scope[data-contrast='high']`, hanging a document attribute on the scoped element,
// where it matches nothing. Both failures are silent; buildScopedCss.test.ts's last case
// asserts against the real stylesheets so a new anchor shape fails there instead.
//
// The anchor may also be INDENTED — a rule nested in an `@media (prefers-contrast: more)`
// block is the case that exists — so each pattern opens at a line start plus any leading
// horizontal whitespace, not at the line start alone. `[ \t]*` and not `\s*`: the latter
// eats newlines, which would let one match swallow a preceding blank line.
const ANCHOR = String.raw`(^[ \t]*|,\s*)`

// The paired light block for a full-palette theme (27 of the 41 shipped stylesheets,
// measured against src/styles: dracula.css is typical — a 91-declaration `html:root`
// dark block followed by an 85-declaration `html:root[data-color-mode]:not(.dark)`
// light block). Its qualifier is EXACTLY the color-mode discriminator, `[data-color-
// mode]:not(.dark)`, and — the part that matters here — it is the ENTIRE selector of
// its OWN rule (immediately followed by `{`). That second condition is what colorMode
// used to ignore: this pattern is textually indistinguishable from one comma-list item
// among several UNLESS the lookahead for `{` (not `,`) is checked too, and two shipped
// themes (charcoal.css, fishlamp.css — "dark-always", no light palette) share exactly
// this discriminator as one item in a combined `html:root, html:root[data-color-mode]
// :not(.dark), …[data-contrast=…] { }` list. Matching the discriminator alone would
// rewrite THAT occurrence as well and hand those themes a light variant they don't
// have — the regression this anchor is scoped, by construction, to avoid.
const HTML_ROOT_LIGHT_ANCHOR_RE = new RegExp(
  ANCHOR + String.raw`html:root\[data-color-mode\]:not\(\.dark\)(?=\s*\{)`,
  'gm',
)
const HTML_ROOT_QUALIFIED_RE = new RegExp(
  ANCHOR + String.raw`html:root((?:\[[^\]]*\]|:not\([^()]*\))+)`,
  'gm',
)
const HTML_ROOT_RE = new RegExp(ANCHOR + String.raw`html:root(?=[\s,{])`, 'gm')
const ROOT_DARK_RE = new RegExp(ANCHOR + String.raw`:root\.dark\b`, 'gm')
const ROOT_NOT_DARK_RE = new RegExp(ANCHOR + String.raw`:root:not\(\.dark\)`, 'gm')
const ROOT_RE = new RegExp(ANCHOR + String.raw`:root(?=[\s,{:])`, 'gm')
const BODY_RE = new RegExp(ANCHOR + String.raw`body(?=[\s,{:.])`, 'gm')

/** A scoped selector that never matches — used to drop the unwanted variant. */
const NEVER = ':scope.pc-colormode-off'

export type ThemeColorMode = 'system' | 'light' | 'dark'

export function buildScopedCss(
  css: string,
  scope: string,
  colorMode: ThemeColorMode = 'system',
): string {
  const imports = (css.match(IMPORT_RE) || []).join('\n')
  // `system` (default) follows the document's `html.dark` class. When forced,
  // resolve the chosen variant's `:root` selectors to `:scope` (always apply)
  // and the other variant's to a never-matching selector (drop it), so the
  // theme renders in that mode regardless of `html.dark`.
  const darkSel =
    colorMode === 'dark' ? ':scope'
      : colorMode === 'light' ? NEVER
        : 'html.dark :scope'
  const lightSel =
    colorMode === 'light' ? ':scope'
      : colorMode === 'dark' ? NEVER
        : 'html:not(.dark) :scope'
  // Same three-way shape as lightSel above, for the html:root-anchored light block:
  // system leaves it exactly as HTML_ROOT_QUALIFIED_RE would have produced anyway (no
  // regression for the 27 themes already relying on that path); light drops the now-
  // redundant discriminator and collapses to `:scope`, so it wins over the dark block's
  // own unconditional `:scope` by source order (the dark block, from HTML_ROOT_RE, is
  // never removed — see that regex's own comment); dark sends it to NEVER so it can't
  // fire regardless of the document's real data-color-mode.
  const lightAnchorSel =
    colorMode === 'light' ? ':scope'
      : colorMode === 'dark' ? NEVER
        : 'html[data-color-mode]:not(.dark) :scope'
  const body = css
    .replace(IMPORT_RE, '')
    .replace(HTML_ROOT_LIGHT_ANCHOR_RE, `$1${lightAnchorSel}`)
    .replace(HTML_ROOT_QUALIFIED_RE, '$1html$2 :scope')
    .replace(HTML_ROOT_RE, '$1:scope')
    .replace(ROOT_DARK_RE, `$1${darkSel}`)
    .replace(ROOT_NOT_DARK_RE, `$1${lightSel}`)
    .replace(ROOT_RE, '$1:scope')
    .replace(BODY_RE, '$1:scope')
  return `${imports}\n@scope (${scope}) {\n${body}\n}`
}

export interface ThemeStyleProps {
  theme: ThemeKey
  scope?: string
  /**
   * Force the theme's color variant regardless of the document's `html.dark`
   * class. `system` (default) follows `html.dark` — the prior behavior. Only
   * affects scoped usage (when `scope` is set).
   */
  colorMode?: ThemeColorMode
}

export function ThemeStyle({ theme, scope, colorMode = 'system' }: ThemeStyleProps) {
  const entry = themes[theme]
  // An unknown theme key (a stale persisted choice, a typo in a consumer's own theme
  // list) must render nothing, not throw — throwing here takes down the whole page a
  // <style> tag was never worth taking down.
  if (!entry) return null
  const css = scope ? buildScopedCss(entry.css, scope, colorMode) : entry.css
  const id = scope ? scopedId(scope) : GLOBAL_ID
  // Render the <style> inline (so it's in the SSR HTML and applied on the very
  // first paint — no flash of default-sized, unstyled chat before a client
  // effect runs). The content is the resolved theme CSS, so re-rendering on a
  // theme/CSS change (incl. HMR) swaps it live. dangerouslySetInnerHTML is the
  // standard way to emit a <style> body without React escaping CSS punctuation
  // (e.g. `>`); the source is our own static theme manifest, not user input.
  return <style id={id} dangerouslySetInnerHTML={{ __html: css }} />
}
