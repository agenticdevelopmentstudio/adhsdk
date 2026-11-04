// @vitest-environment node
import { readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { describe, expect, it } from 'vitest'
import { themes, themeIds } from '../manifest'

const LIGHT = 'html:root[data-color-mode]:not(.dark)'
const LIGHT_SHEET = readFileSync(
  fileURLToPath(new URL('../styles/color-mode-light.css', import.meta.url)),
  'utf8',
)

function withoutComments(css: string): string {
  return css.replace(/\/\*[\s\S]*?\*\//g, '')
}

function propsOf(body: string): string[] {
  return Array.from(body.matchAll(/(--[a-z0-9-]+)\s*:/g), (m) => m[1]!)
}

/** Every custom property the light sheet's base rule sets: what a device in light mode gets. */
function lightModeProps(): string[] {
  const match = /:root\[data-color-mode\]:not\(\.dark\)\s*\{([^}]*)\}/.exec(withoutComments(LIGHT_SHEET))
  if (!match) throw new Error('color-mode-light.css has no base rule: the sheet changed shape')
  return propsOf(match[1]!)
}

/** Every custom property a theme sets in a rule that lists `LIGHT` beside the bare dark anchor. */
function darkPinnedProps(css: string): string[] | null {
  const pinned = Array.from(withoutComments(css).matchAll(/([^{}]+)\{([^{}]*)\}/g)).filter(([, selector]) => {
    const list = selector!.split(',').map((s) => s.trim())
    return list.includes('html:root') && list.includes(LIGHT)
  })
  return pinned.length ? pinned.flatMap(([, , body]) => propsOf(body!)) : null
}

const DARK_ALWAYS = themeIds.filter((id) => darkPinnedProps(themes[id].css) !== null)

describe('dark-always themes', () => {
  it('finds the themes it is meant to check', () => {
    expect(DARK_ALWAYS).toContain('fishlamp')
    expect(DARK_ALWAYS).toContain('charcoal')
    expect(lightModeProps()).toContain('--color-apt-cat-blue')
  })

  // A token this list misses is the one thing that flips on a light-mode device, on a surface that
  // stayed dark: the theme looks right in any screenshot taken on a dark-mode machine.
  it.each(DARK_ALWAYS)('%s pins every token the light sheet sets', (id) => {
    const pinned = new Set(darkPinnedProps(themes[id].css))
    expect(lightModeProps().filter((p) => !pinned.has(p))).toEqual([])
  })
})
