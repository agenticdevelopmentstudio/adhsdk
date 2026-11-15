// @vitest-environment node
// Conformance tests for the theme-data recipe: the generator scripts (theme-data.mjs,
// inline-imports.mjs, build-theme-data.mjs) run on temporary styles directories, plus the
// shipped src/styles and the generated src/theme-data.ts.
import { execFileSync } from 'node:child_process'
import { mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { afterEach, describe, expect, it } from 'vitest'
import { themes as manifestThemes } from '../manifest'
// @ts-expect-error -- plain .mjs build helper, no type declarations
import { renderThemeData } from '../../scripts/theme-data.mjs'

const themes: Record<string, { id: string; css: string } | undefined> = manifestThemes
const render = renderThemeData as (dir: string) => Promise<{ text: string; count: number }>

const SCRIPT = fileURLToPath(new URL('../../scripts/build-theme-data.mjs', import.meta.url))
const SHIPPED_STYLES = fileURLToPath(new URL('../styles', import.meta.url))
const GENERATED = fileURLToPath(new URL('../theme-data.ts', import.meta.url))
const MANIFEST = fileURLToPath(new URL('../manifest.ts', import.meta.url))

const roots: string[] = []

/** A package-root-shaped temp dir with `src/styles` holding the given files. */
function makePackage(files: Record<string, string>): { root: string; styles: string; out: string } {
  const root = mkdtempSync(join(tmpdir(), 'theme-data-'))
  roots.push(root)
  const styles = join(root, 'src', 'styles')
  mkdirSync(styles, { recursive: true })
  for (const [name, css] of Object.entries(files)) writeFileSync(join(styles, name), css, 'utf8')
  return { root, styles, out: join(root, 'src', 'theme-data.ts') }
}

function runScript(root: string): string {
  return execFileSync('node', [SCRIPT], { cwd: root, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] })
}

function exportNames(text: string): string[] {
  return [...text.matchAll(/^export const (\w+) = /gm)].map((m) => m[1]!)
}

afterEach(() => {
  while (roots.length) rmSync(roots.pop()!, { recursive: true, force: true })
})

describe('theme-data conformance', () => {
  it('theme-data-001 manifest entries carry non-empty css and an id equal to the key', () => {
    for (const key of ['crt-monitor', 'handheld-communicator']) {
      const entry = themes[key]!
      expect(typeof entry.css).toBe('string')
      expect(entry.css.length).toBeGreaterThan(0)
      expect(entry.id).toBe(key)
    }
  })

  it('theme-data-002 export strings are stylesheet text with the light and color-mode selectors', () => {
    for (const key of ['fishlamp', 'charcoal']) {
      const css = themes[key]!.css
      expect(typeof css).toBe('string')
      expect(css).toContain('html:root')
      expect(css).toContain('html:root[data-color-mode]:not(.dark)')
    }
  })

  it('theme-data-003 exports are named from the file names and ordered by sorted file name', async () => {
    const { styles } = makePackage({
      'terminal-split.css': 'a{}',
      'dev-team.css': 'b{}',
      'adh.css': 'c{}',
      'adh-comic.css': 'd{}',
    })
    const { text } = await render(styles)
    expect(exportNames(text)).toEqual(['adhComicCss', 'adhCss', 'devTeamCss', 'terminalSplitCss'])
  })

  it('theme-data-004 a relative @import is inlined and the shared palette is also exported', async () => {
    const palette = ':root { --accent: #123456; }\n'
    const { styles } = makePackage({
      'fishlamp-palette.css': palette,
      'fishlamp.css': "/* head */\n@import './fishlamp-palette.css';\n.x { color: red; }\n",
    })
    const { text } = await render(styles)
    const fishlamp = JSON.parse(text.match(/^export const fishlampCss = (.*)$/m)![1]!) as string
    expect(fishlamp).toContain(palette)
    expect(fishlamp).not.toContain("@import './")
    expect(fishlamp).toBe(`/* head */\n${palette}\n.x { color: red; }\n`)
    expect(exportNames(text)).toContain('fishlampPaletteCss')
  })

  it('theme-data-005 a remote @import url(...) is kept unchanged', async () => {
    const css = "@import url('https://fonts.googleapis.com/css2?family=Sora&display=swap');\n:root{}\n"
    const { styles } = makePackage({ 'dracula.css': css })
    const { text } = await render(styles)
    const value = JSON.parse(text.match(/^export const draculaCss = (.*)$/m)![1]!) as string
    expect(value).toContain("@import url('https://fonts.googleapis.com/css2?family=Sora&display=swap');")
    expect(value).toBe(css)
  })

  it('theme-data-006 a self-import throws and no output is written', () => {
    const { root, out } = makePackage({ 'self.css': "@import './self.css';\n" })
    let message = ''
    try {
      runScript(root)
    } catch (e) {
      message = String((e as { stderr?: unknown }).stderr)
    }
    expect(message).toContain('inline-imports:')
    expect(message).toContain('self.css imports itself')
    expect(() => readFileSync(out, 'utf8')).toThrow()
  })

  it('theme-data-007 a missing import target fails with a file-not-found error and leaves the older output untouched', () => {
    const { root, out } = makePackage({ 'a.css': "@import './gone.css';\n" })
    writeFileSync(out, 'OLDER FILE\n', 'utf8')
    let message = ''
    try {
      runScript(root)
    } catch (e) {
      message = String((e as { stderr?: unknown }).stderr)
    }
    expect(message).toContain('ENOENT')
    expect(readFileSync(out, 'utf8')).toBe('OLDER FILE\n')
  })

  it('theme-data-008 prints the completion message with singular and plural theme', () => {
    const one = makePackage({ 'a.css': 'a{}' })
    expect(runScript(one.root)).toBe('build-theme-data: 1 theme → src/theme-data.ts\n')
    const two = makePackage({ 'a.css': 'a{}', 'b.css': 'b{}' })
    expect(runScript(two.root)).toBe('build-theme-data: 2 themes → src/theme-data.ts\n')
  })

  it('theme-data-009 two runs with no CSS change produce byte-identical output', () => {
    const { root, out } = makePackage({ 'a.css': 'a{}', 'b-c.css': 'b{}' })
    runScript(root)
    const first = readFileSync(out)
    runScript(root)
    const second = readFileSync(out)
    expect(second.equals(first)).toBe(true)
  })

  it('theme-data-010 the export is one JSON string with escapes and the em dash unescaped', async () => {
    const css = '/* say "hi"\n  — done */\n'
    const { styles } = makePackage({ 'q.css': css })
    const { text } = await render(styles)
    const line = text.split('\n').find((l) => l.startsWith('export const qCss = '))!
    expect(line).toContain('\\"hi\\"')
    expect(line).toContain('\\n')
    expect(line).toContain('—')
    expect(line).not.toContain('\\u')
    expect(JSON.parse(line.slice('export const qCss = '.length))).toBe(css)
  })

  it('theme-data-011 line 1 is the generated comment, line 2 is empty and the file ends with one newline', async () => {
    const { styles } = makePackage({ 'a.css': 'a{}', 'b.css': 'b{}' })
    const { text } = await render(styles)
    const lines = text.split('\n')
    expect(lines[0]).toBe('// AUTO-GENERATED by scripts/build-theme-data.mjs — do not edit.')
    expect(lines[1]).toBe('')
    expect(text.endsWith('\n')).toBe(true)
    expect(text.endsWith('\n\n')).toBe(false)
  })

  it('theme-data-012 non-theme sheets are exported and not imported by the manifest', async () => {
    const { text } = await render(SHIPPED_STYLES)
    const names = exportNames(text)
    const nonTheme = ['accessibilityCss', 'colorModeLightCss', 'fishlampPaletteCss', 'mikefullertonLandingCss']
    const manifestSource = readFileSync(MANIFEST, 'utf8')
    for (const name of nonTheme) {
      expect(names).toContain(name)
      expect(manifestSource).not.toMatch(new RegExp(`\\b${name}\\b`))
    }
  })

  it('theme-data-013 the shipped adh.css keeps its @font-face declarations in adhCss', async () => {
    const { text } = await render(SHIPPED_STYLES)
    const adh = JSON.parse(text.match(/^export const adhCss = (.*)$/m)![1]!) as string
    expect(adh).toContain('@font-face')
    expect(readdirSync(SHIPPED_STYLES)).toContain('adh.css')
  })

  it('theme-data-014 the generated file equals what the generator renders from the stylesheets now', async () => {
    const { text } = await render(SHIPPED_STYLES)
    expect(readFileSync(GENERATED, 'utf8')).toBe(text)
  })

  it('theme-data-015 a sheet with no relative @import is exported byte for byte', async () => {
    const css = '/* x */\r\n:root { --a: "b\\c"; }\n\ttab\n'
    const { styles } = makePackage({ 'plain.css': css })
    const { text } = await render(styles)
    const value = JSON.parse(text.match(/^export const plainCss = (.*)$/m)![1]!) as string
    expect(value).toBe(css)
  })
})
