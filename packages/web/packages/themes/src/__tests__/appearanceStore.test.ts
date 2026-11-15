// Conformance tests for cookbook/themes/appearance-store, AS-008 to AS-020 (AS-001 to AS-007 live
// in appearanceScope.test.ts, AppearanceScope.test.tsx and clearAppearance.test.ts).
//
// The store keeps module state, so each test loads a fresh copy. `subscribe` and the snapshot
// getters are private; the only way to reach them is the `useSyncExternalStore` call inside
// `useAppearancePreferences`, so the fresh copy is loaded against a React whose
// `useSyncExternalStore` records the three functions it is handed. No renderer is involved, which
// is also why the real-hook vectors (AS-011, AS-019) live in appearanceStoreHook.test.tsx.
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import {
  APPEARANCE_DEFAULTS,
  APPEARANCE_STORAGE_KEY,
  applyAppearance,
  clearAppearance,
  type AppearancePrefs,
} from '../appearance'

type Store = typeof import('../appearance-store')

interface Captured {
  subscribe: (listener: () => void) => () => void
  getSnapshot: () => AppearancePrefs
  getServerSnapshot: () => AppearancePrefs
}

let captured: Captured | undefined

function seam(): Captured {
  if (!captured) throw new Error('the store never called useSyncExternalStore')
  return captured
}

// `capture` calls the hook once so the seam is recorded; that reads the snapshot, so a test about
// a store that has not been read passes `false`.
async function freshStore(capture = true): Promise<Store> {
  vi.resetModules()
  captured = undefined
  vi.doMock('react', async () => {
    const actual = await vi.importActual<typeof import('react')>('react')
    return {
      ...actual,
      useSyncExternalStore: (
        subscribe: Captured['subscribe'],
        getSnapshot: Captured['getSnapshot'],
        getServerSnapshot: Captured['getServerSnapshot'],
      ): AppearancePrefs => {
        captured = { subscribe, getSnapshot, getServerSnapshot }
        return getSnapshot()
      },
      useCallback: <T>(fn: T): T => fn,
      useMemo: <T>(factory: () => T): T => factory(),
    }
  })
  const store = await import('../appearance-store')
  if (capture) store.useAppearancePreferences()
  return store
}

interface FakeSchemeQuery {
  flip: (dark: boolean) => void
}

function installSchemeQuery(dark: boolean): FakeSchemeQuery {
  const listeners = new Set<() => void>()
  const mq = {
    matches: dark,
    media: '(prefers-color-scheme: dark)',
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: (_type: string, l: () => void) => listeners.add(l),
    removeEventListener: (_type: string, l: () => void) => listeners.delete(l),
    dispatchEvent: () => false,
  }
  window.matchMedia = vi.fn(() => mq as unknown as MediaQueryList)
  return {
    flip(next: boolean): void {
      mq.matches = next
      for (const l of listeners) l()
    },
  }
}

function painted(): boolean {
  const el = document.documentElement
  return el.hasAttribute('data-color-mode') || el.classList.contains('dark') || el.hasAttribute('data-contrast')
}

const DARK: AppearancePrefs = { ...APPEARANCE_DEFAULTS, colorMode: 'dark' }

let originalMatchMedia: typeof window.matchMedia

beforeEach(() => {
  originalMatchMedia = window.matchMedia
  for (const a of [...document.documentElement.attributes]) document.documentElement.removeAttribute(a.name)
  window.localStorage.clear()
})

afterEach(() => {
  window.matchMedia = originalMatchMedia
  vi.restoreAllMocks()
  vi.doUnmock('react')
})

describe('appearance store', () => {
  it('AS-008: clearAppearance takes every applied pref and the pre-paint defaults off an element', () => {
    const el = document.createElement('html')
    el.className = 'font-a'
    el.setAttribute('lang', 'en')
    const before = el.outerHTML
    applyAppearance(
      el,
      {
        colorMode: 'dark',
        reduceMotion: 'on',
        contrast: 'high',
        textSize: 'large',
        spacing: 'spacious',
        focusOutlines: true,
        underlineLinks: true,
      },
      true,
    )
    clearAppearance(el)
    expect(el.outerHTML).toBe(before)

    el.dataset.colorMode = 'auto'
    el.classList.add('dark')
    clearAppearance(el)
    expect(el.hasAttribute('data-color-mode')).toBe(false)
    expect(el.classList.contains('dark')).toBe(false)
  })

  it('AS-009: an OS change does not repaint when the colour mode is explicit', async () => {
    const os = installSchemeQuery(false)
    const store = await freshStore()
    store.adoptAppearance({ ...APPEARANCE_DEFAULTS, colorMode: 'light' })

    os.flip(true)

    expect(document.documentElement.classList.contains('dark')).toBe(false)
  })

  it('AS-010: reset clears the cache, restores the defaults and follows the OS', async () => {
    installSchemeQuery(false)
    const store = await freshStore()
    store.adoptAppearance(DARK)
    expect(document.documentElement.classList.contains('dark')).toBe(true)

    store.resetAppearance()

    expect(window.localStorage.getItem(APPEARANCE_STORAGE_KEY)).toBeNull()
    expect(seam().getSnapshot()).toEqual(APPEARANCE_DEFAULTS)
    expect(document.documentElement.classList.contains('dark')).toBe(false)
  })

  it('AS-012: the server snapshot is the defaults and nothing is painted', async () => {
    window.localStorage.setItem(APPEARANCE_STORAGE_KEY, JSON.stringify(DARK))
    const store = await freshStore()

    expect(seam().getServerSnapshot()).toEqual(APPEARANCE_DEFAULTS)
    expect(painted()).toBe(false)
  })

  it('AS-013: loads without matchMedia, and auto then resolves to light', async () => {
    Object.defineProperty(window, 'matchMedia', { value: undefined, configurable: true, writable: true })
    const store = await freshStore()

    store.adoptAppearance({ ...APPEARANCE_DEFAULTS, colorMode: 'auto' })

    expect(document.documentElement.classList.contains('dark')).toBe(false)
    expect(document.documentElement.dataset.colorMode).toBe('auto')
  })

  it('AS-014: loads when the query has no addEventListener', async () => {
    const matchMedia = vi.fn(() => ({ matches: false }) as unknown as MediaQueryList)
    window.matchMedia = matchMedia

    const store = await freshStore()

    expect(matchMedia).toHaveBeenCalledWith('(prefers-color-scheme: dark)')
    expect(() => store.adoptAppearance({ ...APPEARANCE_DEFAULTS, colorMode: 'auto' })).not.toThrow()
    expect(document.documentElement.classList.contains('dark')).toBe(false)
  })

  it('AS-015: a failing localStorage write does not stop the commit', async () => {
    installSchemeQuery(false)
    const store = await freshStore()
    const listener = vi.fn()
    seam().subscribe(listener)
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new DOMException('quota', 'QuotaExceededError')
    })
    const prefs: AppearancePrefs = { ...APPEARANCE_DEFAULTS, colorMode: 'dark', contrast: 'high' }

    expect(() => store.adoptAppearance(prefs)).not.toThrow()

    expect(seam().getSnapshot()).toEqual(prefs)
    expect(document.documentElement.classList.contains('dark')).toBe(true)
    expect(document.documentElement.dataset.contrast).toBe('high')
    expect(listener).toHaveBeenCalledTimes(1)
  })

  it('AS-016: an OS change before anything is read does nothing', async () => {
    const os = installSchemeQuery(false)
    await freshStore(false)

    expect(() => os.flip(true)).not.toThrow()

    expect(painted()).toBe(false)
  })

  it('AS-017: set holds, caches and paints an unvalidated value as given', async () => {
    installSchemeQuery(false)
    const store = await freshStore()

    store.useAppearancePreferences().set({ colorMode: 'bogus' as never })

    expect(seam().getSnapshot().colorMode).toBe('bogus')
    expect(JSON.parse(window.localStorage.getItem(APPEARANCE_STORAGE_KEY) ?? '{}').colorMode).toBe('bogus')
    expect(document.documentElement.dataset.colorMode).toBe('bogus')
  })

  it('AS-018: a listener sees the new snapshot, cache and paint, before the commit returns', async () => {
    installSchemeQuery(false)
    const store = await freshStore()
    let seen: { dark: boolean; cached: string | null; snapshot: AppearancePrefs } | undefined
    seam().subscribe(() => {
      seen = {
        dark: document.documentElement.classList.contains('dark'),
        cached: window.localStorage.getItem(APPEARANCE_STORAGE_KEY),
        snapshot: seam().getSnapshot(),
      }
    })

    store.adoptAppearance(DARK)

    expect(seen).toBeDefined()
    expect(seen!.dark).toBe(true)
    expect(seen!.cached).toBe(JSON.stringify(DARK))
    expect(seen!.snapshot).toEqual(DARK)
  })

  it('AS-019: the first read loads the cache and the snapshot keeps its identity between commits', async () => {
    window.localStorage.setItem(APPEARANCE_STORAGE_KEY, '{"colorMode":"dark"}')
    await freshStore()
    const { getSnapshot } = seam()

    const first = getSnapshot()
    const second = getSnapshot()

    expect(first.colorMode).toBe('dark')
    expect(Object.is(first, second)).toBe(true)
  })

  it('AS-020: unsubscribe removes a listener; a throwing listener stops the ones after it', async () => {
    installSchemeQuery(false)
    const store = await freshStore()
    const a = vi.fn()
    const b = vi.fn()
    const unsubscribeA = seam().subscribe(a)
    const unsubscribeB = seam().subscribe(b)

    unsubscribeA()
    store.adoptAppearance(DARK)
    expect(a).not.toHaveBeenCalled()
    expect(b).toHaveBeenCalledTimes(1)

    unsubscribeB()
    seam().subscribe(() => {
      throw new Error('listener failed')
    })
    seam().subscribe(b)
    expect(() => store.adoptAppearance({ ...DARK, contrast: 'high' })).toThrow('listener failed')
    expect(b).toHaveBeenCalledTimes(1)
    expect(seam().getSnapshot().contrast).toBe('high')
  })
})
