// @vitest-environment node
// Conformance tests for the theme manifest. Runs in a node environment so the import itself
// proves the module touches no document (theme-manifest-010).
import { describe, expect, expectTypeOf, it } from 'vitest'
import * as manifestModule from '../manifest'
import { themes, themeIds, type ThemeEntry, type ThemeKey } from '../manifest'
import { buildScopedCss } from '../ThemeStyle'

// The Registered themes table of the recipe, in its order.
const REGISTERED: ThemeKey[] = [
  'adh',
  'adh-comic',
  'adh-courier',
  'adh-dev-preview',
  'adh-fira',
  'adh-iosevka',
  'adh-jetbrains',
  'adh-manrope',
  'agenticdevelopmentstudioweb',
  'charcoal',
  'dev-team',
  'fishlamp',
  'green-matrix',
  'green-matrix-glass',
  'mikefullerton',
  'myprojects',
  'myprojectsoverview',
  'old-school-terminal',
  'professional',
  'techy',
  'terminal',
  'terminal-split',
  'whimsical',
  'gruvbox',
  'nord',
  'rose-pine',
  'signal',
  'solarized',
  'catppuccin',
  'cobalt2',
  'dracula',
  'github',
  'monokai',
  'one-dark',
  'synthwave84',
  'tokyo-night',
  'vesper',
  'crt-monitor',
  'handheld-communicator',
]

describe('theme manifest', () => {
  it('theme-manifest-001 lists every registered theme once', () => {
    expect(themeIds.length).toBe(REGISTERED.length)
    expect(new Set(themeIds).size).toBe(themeIds.length)
    expect([...themeIds].sort()).toEqual([...REGISTERED].sort())
    expect(Object.keys(themes).sort()).toEqual([...REGISTERED].sort())
  })

  it('theme-manifest-002 includes the rescued themes in themeIds', () => {
    expect(themeIds).toContain('crt-monitor')
    expect(themeIds).toContain('handheld-communicator')
  })

  it('theme-manifest-003 resolves the rescued themes with non-empty css', () => {
    for (const id of ['crt-monitor', 'handheld-communicator'] as const) {
      const entry = themes[id]
      expect(entry).toBeDefined()
      expect(entry.id).toBe(id)
      expect(typeof entry.css).toBe('string')
      expect(entry.css.length).toBeGreaterThan(0)
    }
  })

  it('theme-manifest-004 gives buildScopedCss an entry for every key', () => {
    for (const key of themeIds) {
      const entry = themes[key]
      expect(entry).toBeDefined()
      expect(typeof buildScopedCss(entry.css, '.host')).toBe('string')
    }
  })

  it('theme-manifest-005 spells the non-ASCII labels as given', () => {
    expect(themes['rose-pine'].label).toBe('Rosé Pine')
    expect(themes.synthwave84.label).toBe("Synthwave '84")
    expect(themes['adh-comic'].label).toBe('ADH · Comic')
  })

  it('theme-manifest-006 keeps declaration order at the ends', () => {
    expect(themeIds[0]).toBe('adh')
    expect(themeIds[7]).toBe('adh-manrope')
    expect(themeIds.at(-1)).toBe('handheld-communicator')
  })

  it('theme-manifest-007 yields undefined for an unknown key', () => {
    const lookup = themes as unknown as Record<string, ThemeEntry | undefined>
    expect(() => lookup['no-such-theme']).not.toThrow()
    expect(lookup['no-such-theme']).toBeUndefined()
  })

  it('theme-manifest-008 labels the glass theme', () => {
    expect(themes['green-matrix-glass'].label).toBe('Green Matrix (Glass)')
  })

  it('theme-manifest-009 orders gruvbox right after whimsical', () => {
    expect(themeIds.indexOf('gruvbox') - themeIds.indexOf('whimsical')).toBe(1)
  })

  it('theme-manifest-010 imports in a node environment and defines its runtime exports', () => {
    expect(typeof document).toBe('undefined')
    expect(manifestModule.themes).toBeDefined()
    expect(manifestModule.themeIds).toBeDefined()
  })

  it('theme-manifest-011 stores every entry under its own id with non-empty css', () => {
    for (const k of themeIds) {
      expect(themes[k].id).toBe(k)
      expect(themes[k].css.length).toBeGreaterThan(0)
    }
  })

  it('theme-manifest-012 types ThemeKey as exactly the registered literals', () => {
    const keys = REGISTERED[0]!
    expectTypeOf(keys).toEqualTypeOf<ThemeKey>()
    expectTypeOf<ThemeKey>().toEqualTypeOf<
      | 'adh'
      | 'adh-comic'
      | 'adh-courier'
      | 'adh-dev-preview'
      | 'adh-fira'
      | 'adh-iosevka'
      | 'adh-jetbrains'
      | 'adh-manrope'
      | 'agenticdevelopmentstudioweb'
      | 'charcoal'
      | 'dev-team'
      | 'fishlamp'
      | 'green-matrix'
      | 'green-matrix-glass'
      | 'mikefullerton'
      | 'myprojects'
      | 'myprojectsoverview'
      | 'old-school-terminal'
      | 'professional'
      | 'techy'
      | 'terminal'
      | 'terminal-split'
      | 'whimsical'
      | 'gruvbox'
      | 'nord'
      | 'rose-pine'
      | 'signal'
      | 'solarized'
      | 'catppuccin'
      | 'cobalt2'
      | 'dracula'
      | 'github'
      | 'monokai'
      | 'one-dark'
      | 'synthwave84'
      | 'tokyo-night'
      | 'vesper'
      | 'crt-monitor'
      | 'handheld-communicator'
    >()
  })

  it('theme-manifest-013 types ThemeEntry with id, label and css', () => {
    expectTypeOf<ThemeEntry>().toEqualTypeOf<{ id: ThemeKey; label: string; css: string }>()
  })

  it('theme-manifest-014 computes themeIds once at load', () => {
    const before = [...themeIds]
    const record = themes as unknown as Record<string, ThemeEntry>
    record['late-theme'] = { id: 'adh', label: 'Late', css: 'x' }
    try {
      expect(themeIds).toEqual(before)
    } finally {
      delete record['late-theme']
    }
  })

  it('theme-manifest-015 exports no default theme, grouping or sort', () => {
    expect(Object.keys(manifestModule).sort()).toEqual(['themeIds', 'themes'])
    expect('default' in manifestModule).toBe(false)
  })
})
