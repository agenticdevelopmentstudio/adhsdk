// Conformance tests for cookbook/themes/appearance: normalization, the storage cache, the DOM
// mapping and the pre-paint script. appearance-016 and appearance-017 live in
// clearAppearance.test.ts.
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import {
  APPEARANCE_DEFAULTS,
  APPEARANCE_PREPAINT_SCRIPT,
  APPEARANCE_STORAGE_KEY,
  applyAppearance,
  clearStoredAppearance,
  normalizeAppearance,
  readStoredAppearance,
  writeStoredAppearance,
  type AppearancePrefs,
} from '../appearance'
import { BOOL_PREFS, ENUM_PREF_DEFAULTS, appearancePrepaint } from '../appearance-prepaint.mjs'

function stubMatchMedia(matches: boolean): void {
  vi.stubGlobal('matchMedia', () => ({ matches }))
}

function dataAttributes(el: Element): string[] {
  return el.getAttributeNames().filter((name) => name.startsWith('data-'))
}

function runPrepaint(): void {
  new Function(APPEARANCE_PREPAINT_SCRIPT)()
}

function resetRoot(): void {
  const html = document.documentElement
  html.classList.remove('dark')
  for (const name of dataAttributes(html)) html.removeAttribute(name)
}

beforeEach(() => {
  window.localStorage.clear()
  resetRoot()
})

afterEach(() => {
  vi.restoreAllMocks()
  vi.unstubAllGlobals()
  window.localStorage.clear()
  resetRoot()
})

describe('normalizeAppearance', () => {
  it('appearance-001: returns a fresh copy of the defaults for null', () => {
    const result = normalizeAppearance(null)
    expect(result).toEqual(APPEARANCE_DEFAULTS)
    expect(result).not.toBe(APPEARANCE_DEFAULTS)
  })

  it('appearance-002: accepts valid fields and keeps defaults for invalid ones', () => {
    const result = normalizeAppearance({
      colorMode: 'dark',
      contrast: 'high',
      textSize: 'huge',
      focusOutlines: true,
    })
    expect(result).toEqual({
      ...APPEARANCE_DEFAULTS,
      colorMode: 'dark',
      contrast: 'high',
      focusOutlines: true,
    })
    expect(result.textSize).toBe('default')
  })

  it('appearance-003: ignores non-boolean values for boolean fields', () => {
    const result = normalizeAppearance({ focusOutlines: 'true', underlineLinks: 1 })
    expect(result.focusOutlines).toBe(false)
    expect(result.underlineLinks).toBe(false)
  })

  it('appearance-004: returns defaults for non-object input without throwing', () => {
    expect(normalizeAppearance('dark')).toEqual(APPEARANCE_DEFAULTS)
    expect(normalizeAppearance(0)).toEqual(APPEARANCE_DEFAULTS)
  })

  it('appearance-005: drops unknown keys and keeps exactly the seven preference keys', () => {
    const result = normalizeAppearance({ theme: 'x', spacing: 'spacious' })
    expect(result.spacing).toBe('spacious')
    expect(Object.keys(result).sort()).toEqual(
      [
        'colorMode',
        'contrast',
        'focusOutlines',
        'reduceMotion',
        'spacing',
        'textSize',
        'underlineLinks',
      ].sort(),
    )
  })

  it('appearance-030: returns a copy, leaving APPEARANCE_DEFAULTS unmutated', () => {
    const a = normalizeAppearance({ colorMode: 'dark' })
    a.spacing = 'spacious'
    expect(APPEARANCE_DEFAULTS.spacing).toBe('compact')
    expect(normalizeAppearance(null).spacing).toBe('compact')
  })
})

describe('storage cache', () => {
  it('appearance-006: reads the defaults from empty storage', () => {
    expect(readStoredAppearance()).toEqual(APPEARANCE_DEFAULTS)
  })

  it('appearance-007: normalizes what it reads', () => {
    window.localStorage.setItem(
      APPEARANCE_STORAGE_KEY,
      '{"colorMode":"light","spacing":"nope"}',
    )
    const result = readStoredAppearance()
    expect(result.colorMode).toBe('light')
    expect(result.spacing).toBe('compact')
  })

  it('appearance-008: returns the defaults for unparseable JSON without throwing', () => {
    window.localStorage.setItem(APPEARANCE_STORAGE_KEY, '{not json')
    expect(readStoredAppearance()).toEqual(APPEARANCE_DEFAULTS)
  })

  it('appearance-009: swallows a storage write failure', () => {
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new DOMException('quota', 'QuotaExceededError')
    })
    expect(() => writeStoredAppearance({ ...APPEARANCE_DEFAULTS })).not.toThrow()
  })

  it('appearance-010: writes the serialized prefs and clears the key', () => {
    const prefs: AppearancePrefs = { ...APPEARANCE_DEFAULTS, colorMode: 'dark', spacing: 'spacious' }
    writeStoredAppearance(prefs)
    expect(window.localStorage.getItem(APPEARANCE_STORAGE_KEY)).toBe(JSON.stringify(prefs))
    clearStoredAppearance()
    expect(window.localStorage.getItem(APPEARANCE_STORAGE_KEY)).toBeNull()
  })

  it('appearance-025: the three functions are safe with no window', () => {
    vi.stubGlobal('window', undefined)
    let read: AppearancePrefs | undefined
    expect(() => {
      read = readStoredAppearance()
      writeStoredAppearance({ ...APPEARANCE_DEFAULTS })
      clearStoredAppearance()
    }).not.toThrow()
    expect(read).toEqual(APPEARANCE_DEFAULTS)
    expect(read).not.toBe(APPEARANCE_DEFAULTS)
  })

  it('appearance-029: writes without normalizing; normalization happens on read', () => {
    writeStoredAppearance({ ...APPEARANCE_DEFAULTS, colorMode: 'bogus' as never })
    expect(window.localStorage.getItem(APPEARANCE_STORAGE_KEY)).toContain('"colorMode":"bogus"')
    expect(readStoredAppearance().colorMode).toBe('auto')
  })
})

describe('applyAppearance', () => {
  it('appearance-011: resolves auto to dark from the system preference', () => {
    const el = document.createElement('html')
    applyAppearance(el, { ...APPEARANCE_DEFAULTS, colorMode: 'auto' }, true)
    expect(el.classList.contains('dark')).toBe(true)
    expect(el.dataset.colorMode).toBe('auto')
  })

  it('appearance-012: light mode wins over a dark system preference', () => {
    const el = document.createElement('html')
    applyAppearance(el, { ...APPEARANCE_DEFAULTS, colorMode: 'light' }, true)
    expect(el.classList.contains('dark')).toBe(false)
    expect(el.dataset.colorMode).toBe('light')
  })

  it('appearance-013: the defaults leave only data-color-mode', () => {
    const el = document.createElement('html')
    applyAppearance(el, { ...APPEARANCE_DEFAULTS }, false)
    expect(dataAttributes(el)).toEqual(['data-color-mode'])
    expect(el.dataset.colorMode).toBe('auto')
  })

  it('appearance-014: non-default values set their attributes', () => {
    const el = document.createElement('html')
    applyAppearance(
      el,
      {
        ...APPEARANCE_DEFAULTS,
        reduceMotion: 'on',
        contrast: 'extra-high',
        spacing: 'spacious',
        underlineLinks: true,
      },
      false,
    )
    expect(el.getAttribute('data-reduce-motion')).toBe('on')
    expect(el.getAttribute('data-contrast')).toBe('extra-high')
    expect(el.getAttribute('data-spacing')).toBe('spacious')
    expect(el.getAttribute('data-underline-links')).toBe('always')
    expect(el.hasAttribute('data-focus-outlines')).toBe(false)
  })

  it('appearance-015: returning to the default removes the attribute', () => {
    const el = document.createElement('html')
    applyAppearance(el, { ...APPEARANCE_DEFAULTS, contrast: 'high' }, false)
    expect(el.hasAttribute('data-contrast')).toBe(true)
    applyAppearance(el, { ...APPEARANCE_DEFAULTS, contrast: 'default' }, false)
    expect(el.hasAttribute('data-contrast')).toBe(false)
  })

  it('appearance-026: is idempotent for the same arguments', () => {
    const el = document.createElement('html')
    const prefs: AppearancePrefs = { ...APPEARANCE_DEFAULTS, colorMode: 'dark', contrast: 'high' }
    applyAppearance(el, prefs, true)
    const first = el.outerHTML
    applyAppearance(el, prefs, true)
    expect(el.outerHTML).toBe(first)
  })

  it('appearance-027: never reads matchMedia itself', () => {
    vi.stubGlobal('matchMedia', () => {
      throw new Error('matchMedia must not be read')
    })
    const el = document.createElement('html')
    expect(() =>
      applyAppearance(el, { ...APPEARANCE_DEFAULTS, colorMode: 'auto' }, true),
    ).not.toThrow()
    expect(el.classList.contains('dark')).toBe(true)
  })
})

describe('pre-paint script', () => {
  it('appearance-018: stored dark sets the class and the attribute', () => {
    stubMatchMedia(false)
    window.localStorage.setItem(APPEARANCE_STORAGE_KEY, '{"colorMode":"dark"}')
    runPrepaint()
    expect(document.documentElement.classList.contains('dark')).toBe(true)
    expect(document.documentElement.dataset.colorMode).toBe('dark')
  })

  it('appearance-019: nothing stored follows the system preference', () => {
    stubMatchMedia(true)
    runPrepaint()
    expect(document.documentElement.classList.contains('dark')).toBe(true)
    expect(document.documentElement.dataset.colorMode).toBe('auto')
  })

  it('appearance-020: default values leave no attribute, non-defaults set one', () => {
    stubMatchMedia(false)
    window.localStorage.setItem(
      APPEARANCE_STORAGE_KEY,
      '{"contrast":"default","textSize":"large","focusOutlines":false}',
    )
    runPrepaint()
    const html = document.documentElement
    expect(html.dataset.textSize).toBe('large')
    expect(html.hasAttribute('data-contrast')).toBe(false)
    expect(html.hasAttribute('data-focus-outlines')).toBe(false)
    expect(dataAttributes(html).sort()).toEqual(['data-color-mode', 'data-text-size'])
  })

  it('appearance-021: swallows the error for a stored null', () => {
    stubMatchMedia(true)
    window.localStorage.setItem(APPEARANCE_STORAGE_KEY, 'null')
    expect(() => runPrepaint()).not.toThrow()
    expect(document.documentElement.classList.contains('dark')).toBe(false)
    expect(document.documentElement.hasAttribute('data-color-mode')).toBe(false)
  })

  it('appearance-022: writes a bogus stored value without validating it', () => {
    stubMatchMedia(false)
    window.localStorage.setItem(APPEARANCE_STORAGE_KEY, '{"contrast":"bogus"}')
    runPrepaint()
    expect(document.documentElement.getAttribute('data-contrast')).toBe('bogus')
  })

  it('appearance-023: the Vite plugin injects the script at the end of head', () => {
    const plugin = appearancePrepaint()
    expect(plugin.name).toBe('adh-appearance-prepaint')
    const tags = plugin.transformIndexHtml()
    expect(tags).toHaveLength(1)
    expect(tags[0]).toEqual({
      tag: 'script',
      children: APPEARANCE_PREPAINT_SCRIPT,
      injectTo: 'head',
    })
  })
})

describe('shared preference lists', () => {
  it('appearance-024: both exports are frozen', () => {
    expect(Object.isFrozen(ENUM_PREF_DEFAULTS)).toBe(true)
    expect(Object.isFrozen(BOOL_PREFS)).toBe(true)
  })

  it('appearance-028: colorMode is not in the enum list', () => {
    expect(Object.keys(ENUM_PREF_DEFAULTS)).toEqual(['reduceMotion', 'contrast', 'textSize', 'spacing'])
  })
})
