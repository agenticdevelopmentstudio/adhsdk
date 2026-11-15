// @vitest-environment node
// Conformance tests for the font preload list. The committed manifest backs the integration vectors;
// the unit vectors replace the manifest with a fixture through a module mock.
import { existsSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { afterEach, describe, expect, it, vi } from 'vitest'
import manifest from '../fonts/metrics.json'
import { themes } from '../manifest'
import { THEME_FONT_PRELOADS } from '../fonts'

interface FixtureFace {
  file: string
  preload: boolean
}

const FONT_DIR = fileURLToPath(new URL('../fonts/', import.meta.url))

async function preloadsFor(publicPath: string, faces: FixtureFace[]): Promise<readonly string[]> {
  vi.resetModules()
  vi.doMock('../fonts/metrics.json', () => ({ default: { publicPath, faces } }))
  const mod = await import('../fonts')
  return mod.THEME_FONT_PRELOADS
}

afterEach(() => {
  vi.doUnmock('../fonts/metrics.json')
  vi.resetModules()
})

describe('THEME_FONT_PRELOADS against the committed manifest', () => {
  it('fonts-001 preloads at least the faces that carry a page layout', () => {
    expect(THEME_FONT_PRELOADS.length).toBeGreaterThan(0)
  })

  it('fonts-002 preloads only same-origin woff2 paths', () => {
    for (const href of THEME_FONT_PRELOADS) {
      expect(href).toMatch(/^\/[^/]/)
      expect(href.endsWith('.woff2')).toBe(true)
    }
  })

  it('fonts-003 declares an @font-face for every preloaded face', () => {
    for (const href of THEME_FONT_PRELOADS) {
      expect(themes.adh.css).toContain(`url('${href}')`)
    }
  })

  it('fonts-004 fetches no font from a third-party stylesheet', () => {
    expect(themes.adh.css).not.toMatch(/@import/)
  })

  it('fonts-005 ships the preloaded bytes at the path it preloads', () => {
    for (const href of THEME_FONT_PRELOADS) {
      expect(existsSync(FONT_DIR + href.split('/').pop()!)).toBe(true)
    }
  })

  it('fonts-006 starts every committed entry with the publicPath', () => {
    for (const href of THEME_FONT_PRELOADS) expect(href.startsWith(`${manifest.publicPath}/`)).toBe(true)
  })

  it('fonts-007 preloads no ext cut', () => {
    for (const href of THEME_FONT_PRELOADS) expect(href.endsWith('-ext.woff2')).toBe(false)
  })
})

describe('THEME_FONT_PRELOADS against injected manifests', () => {
  it('fonts-006 keeps only flagged faces, in manifest order', async () => {
    const list = await preloadsFor('/p', [
      { file: 'iosevka-400.woff2', preload: true },
      { file: 'iosevka-400-ext.woff2', preload: false },
      { file: 'iosevka-700.woff2', preload: true },
    ])
    expect(list).toEqual(['/p/iosevka-400.woff2', '/p/iosevka-700.woff2'])
  })

  it('fonts-008 is empty when no face is flagged', async () => {
    expect(await preloadsFor('/p', [{ file: 'a.woff2', preload: false }])).toEqual([])
  })

  it('fonts-009 joins publicPath and file with one slash', async () => {
    expect(await preloadsFor('/x', [{ file: 'a.woff2', preload: true }])).toEqual(['/x/a.woff2'])
  })

  it('fonts-010 lists a preloaded face whose file is absent, without error', async () => {
    const file = 'no-such-face-on-disk.woff2'
    expect(existsSync(FONT_DIR + file)).toBe(false)
    expect(await preloadsFor('/x', [{ file, preload: true }])).toEqual([`/x/${file}`])
  })
})
