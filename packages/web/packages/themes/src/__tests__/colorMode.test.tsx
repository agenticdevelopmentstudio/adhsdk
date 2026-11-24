/// <reference types="@testing-library/jest-dom/vitest" />
import { act, cleanup, render, renderHook } from '@testing-library/react'
import type { ReactNode } from 'react'
import { renderToString } from 'react-dom/server'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { ColorModeProvider, useColorMode } from '../colorMode'

const KEY = 'adh-sdk:color-mode'
const LEGACY = 'agentic-toolkit:color-mode'

interface FakeMql {
  matches: boolean
  addEventListener: ReturnType<typeof vi.fn>
  removeEventListener: ReturnType<typeof vi.fn>
}

let systemDark = false
let mql: FakeMql
let changeListeners: Array<(e: { matches: boolean }) => void>

function installMatchMedia() {
  changeListeners = []
  mql = {
    get matches() {
      return systemDark
    },
    addEventListener: vi.fn((_type: string, fn: (e: { matches: boolean }) => void) => {
      changeListeners.push(fn)
    }),
    removeEventListener: vi.fn((_type: string, fn: (e: { matches: boolean }) => void) => {
      changeListeners = changeListeners.filter((l) => l !== fn)
    }),
  } as unknown as FakeMql
  vi.stubGlobal('matchMedia', () => mql)
  window.matchMedia = (() => mql) as unknown as typeof window.matchMedia
}

function wrapper(props: { storageKey?: string; defaultMode?: 'auto' | 'light' | 'dark' } = {}) {
  return ({ children }: { children: ReactNode }) => <ColorModeProvider {...props}>{children}</ColorModeProvider>
}

beforeEach(() => {
  window.localStorage.clear()
  document.documentElement.classList.remove('dark')
  delete document.documentElement.dataset.appearanceMode
  systemDark = false
  installMatchMedia()
})

afterEach(() => {
  cleanup()
  vi.restoreAllMocks()
  vi.unstubAllGlobals()
})

describe('ColorModeProvider', () => {
  it('color-mode-001: cycle() moves auto to dark and the consumer sees the change', () => {
    const { result } = renderHook(() => useColorMode(), { wrapper: wrapper() })
    const before = `${result.current.mode}/${result.current.resolved}`
    expect(result.current.mode).toBe('auto')
    act(() => result.current.cycle())
    expect(result.current.mode).toBe('dark')
    expect(`${result.current.mode}/${result.current.resolved}`).not.toBe(before)
  })

  it('color-mode-002: useColorMode returns the context value inside a provider and throws outside', () => {
    const { result } = renderHook(() => useColorMode(), { wrapper: wrapper() })
    expect(Object.keys(result.current).sort()).toEqual(['cycle', 'mode', 'resolved', 'setMode'])
    vi.spyOn(console, 'error').mockImplementation(() => {})
    expect(() => renderHook(() => useColorMode())).toThrow(
      'useColorMode must be used within a <ColorModeProvider>',
    )
  })

  it('color-mode-003: reads a stored mode and ignores an invalid one', () => {
    window.localStorage.setItem(KEY, 'dark')
    const first = renderHook(() => useColorMode(), { wrapper: wrapper() })
    expect(first.result.current.mode).toBe('dark')
    first.unmount()
    window.localStorage.setItem(KEY, 'purple')
    const second = renderHook(() => useColorMode(), { wrapper: wrapper() })
    expect(second.result.current.mode).toBe('auto')
  })

  it('color-mode-004: the legacy key is read only for the default storage key and is not cleaned', () => {
    window.localStorage.setItem(LEGACY, 'light')
    const first = renderHook(() => useColorMode(), { wrapper: wrapper() })
    expect(first.result.current.mode).toBe('light')
    expect(window.localStorage.getItem(KEY)).toBe('light')
    expect(window.localStorage.getItem(LEGACY)).toBe('light')
    first.unmount()
    const custom = renderHook(() => useColorMode(), { wrapper: wrapper({ storageKey: 'x' }) })
    expect(custom.result.current.mode).toBe('auto')
  })

  it('color-mode-005: auto resolves from a dark system and marks the document', () => {
    systemDark = true
    const { result } = renderHook(() => useColorMode(), { wrapper: wrapper() })
    expect(result.current.resolved).toBe('dark')
    expect(document.documentElement).toHaveClass('dark')
    expect(document.documentElement.dataset.appearanceMode).toBe('auto')
  })

  it('color-mode-006: a system change event re-resolves auto', () => {
    systemDark = true
    const { result } = renderHook(() => useColorMode(), { wrapper: wrapper() })
    expect(result.current.resolved).toBe('dark')
    act(() => changeListeners.forEach((l) => l({ matches: false })))
    expect(result.current.resolved).toBe('light')
    expect(document.documentElement).not.toHaveClass('dark')
  })

  it('color-mode-007: an explicit default mode overrides a dark system', () => {
    systemDark = true
    const { result } = renderHook(() => useColorMode(), { wrapper: wrapper({ defaultMode: 'light' }) })
    expect(result.current.resolved).toBe('light')
    expect(document.documentElement).not.toHaveClass('dark')
    expect(document.documentElement.dataset.appearanceMode).toBe('light')
  })

  it('color-mode-008: an explicit mode is persisted and auto removes the key', () => {
    const { result } = renderHook(() => useColorMode(), { wrapper: wrapper() })
    act(() => result.current.setMode('dark'))
    expect(window.localStorage.getItem(KEY)).toBe('dark')
    act(() => result.current.setMode('auto'))
    expect(window.localStorage.getItem(KEY)).toBeNull()
  })

  it('color-mode-009: cycle() walks auto, dark, light, auto, dark', () => {
    const { result } = renderHook(() => useColorMode(), { wrapper: wrapper() })
    const seen: string[] = []
    for (let i = 0; i < 4; i++) {
      act(() => result.current.cycle())
      seen.push(result.current.mode)
    }
    expect(seen).toEqual(['dark', 'light', 'auto', 'dark'])
  })

  it('color-mode-010: the awt:appearance-cycle window event cycles the mode', () => {
    const { result } = renderHook(() => useColorMode(), { wrapper: wrapper() })
    act(() => {
      window.dispatchEvent(new CustomEvent('awt:appearance-cycle'))
    })
    expect(result.current.mode).toBe('dark')
  })

  it('color-mode-011: awt:appearance-changed fires on mount and after a mode change', () => {
    const handler = vi.fn()
    window.addEventListener('awt:appearance-changed', handler)
    try {
      const { result } = renderHook(() => useColorMode(), { wrapper: wrapper() })
      expect(handler).toHaveBeenCalledTimes(1)
      act(() => result.current.setMode('light'))
      expect(handler).toHaveBeenCalledTimes(2)
    } finally {
      window.removeEventListener('awt:appearance-changed', handler)
    }
  })

  it('color-mode-012: storage failures are swallowed', () => {
    vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
      throw new Error('denied')
    })
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new Error('denied')
    })
    // The vitest setup installs an own-property shim on window.localStorage, so stub that too.
    vi.spyOn(window.localStorage, 'getItem').mockImplementation(() => {
      throw new Error('denied')
    })
    vi.spyOn(window.localStorage, 'setItem').mockImplementation(() => {
      throw new Error('denied')
    })
    const { result } = renderHook(() => useColorMode(), { wrapper: wrapper({ defaultMode: 'light' }) })
    expect(result.current.mode).toBe('light')
    expect(() => act(() => result.current.setMode('dark'))).not.toThrow()
    expect(result.current.mode).toBe('dark')
    expect(document.documentElement).toHaveClass('dark')
    expect(document.documentElement.dataset.appearanceMode).toBe('dark')
  })

  it('color-mode-013: server render uses the default mode, a light system and touches no document', () => {
    function Probe() {
      const { mode, resolved } = useColorMode()
      return <span>{`${mode}/${resolved}`}</span>
    }
    const realWindow = globalThis.window
    vi.stubGlobal('window', undefined)
    let html: string
    try {
      html = renderToString(
        <ColorModeProvider defaultMode="dark">
          <Probe />
        </ColorModeProvider>,
      )
    } finally {
      vi.stubGlobal('window', realWindow)
    }
    expect(html).toContain('dark/dark')
    // systemDark is false on the server: auto resolves to light.
    vi.stubGlobal('window', undefined)
    try {
      html = renderToString(
        <ColorModeProvider>
          <Probe />
        </ColorModeProvider>,
      )
    } finally {
      vi.stubGlobal('window', realWindow)
    }
    expect(html).toContain('auto/light')
    expect(document.documentElement).not.toHaveClass('dark')
    expect(document.documentElement.dataset.appearanceMode).toBeUndefined()
  })

  it('color-mode-014: a legacy value is written to the new key on first render', () => {
    window.localStorage.setItem(LEGACY, 'light')
    render(
      <ColorModeProvider>
        <span />
      </ColorModeProvider>,
    )
    expect(window.localStorage.getItem(KEY)).toBe('light')
  })

  it('color-mode-015: unmounting removes the system change listener', () => {
    const { unmount } = renderHook(() => useColorMode(), { wrapper: wrapper() })
    expect(mql.addEventListener).toHaveBeenCalledTimes(1)
    const [type, fn] = mql.addEventListener.mock.calls[0] as [string, unknown]
    expect(type).toBe('change')
    unmount()
    expect(mql.removeEventListener).toHaveBeenCalledWith('change', fn)
  })

  it('color-mode-016: unmounting removes the cycle event listener', () => {
    const add = vi.spyOn(window, 'addEventListener')
    const remove = vi.spyOn(window, 'removeEventListener')
    const { unmount } = renderHook(() => useColorMode(), { wrapper: wrapper() })
    const cycleAdds = add.mock.calls.filter(([t]) => t === 'awt:appearance-cycle')
    expect(cycleAdds).toHaveLength(1)
    unmount()
    expect(remove.mock.calls.filter(([t, fn]) => t === 'awt:appearance-cycle' && fn === cycleAdds[0]?.[1])).toHaveLength(1)
    window.localStorage.clear()
    act(() => {
      window.dispatchEvent(new CustomEvent('awt:appearance-cycle'))
    })
    // A live listener would have cycled auto to dark and persisted it; the key stays absent.
    expect(window.localStorage.getItem(KEY)).toBeNull()
  })

  it('color-mode-017: cycle and the context value keep their identity across a parent re-render', () => {
    const seen: Array<ReturnType<typeof useColorMode>> = []
    function Probe() {
      seen.push(useColorMode())
      return null
    }
    function Parent({ tick }: { tick: number }) {
      return (
        <ColorModeProvider>
          <Probe key="p" />
          <span>{tick}</span>
        </ColorModeProvider>
      )
    }
    const { rerender } = render(<Parent tick={1} />)
    rerender(<Parent tick={2} />)
    const first = seen[0]
    const last = seen[seen.length - 1]
    expect(first).toBeDefined()
    expect(last).toBeDefined()
    expect(last?.cycle).toBe(first?.cycle)
    expect(Object.is(last, first)).toBe(true)
  })

  it('color-mode-018: unmounting leaves the dark class and appearance attribute on the document', () => {
    const { result, unmount } = renderHook(() => useColorMode(), { wrapper: wrapper({ defaultMode: 'dark' }) })
    expect(result.current.mode).toBe('dark')
    unmount()
    expect(document.documentElement).toHaveClass('dark')
    expect(document.documentElement.dataset.appearanceMode).toBe('dark')
  })

  it('color-mode-019: setMode changes mode and resolved together', () => {
    const { result } = renderHook(() => useColorMode(), { wrapper: wrapper({ defaultMode: 'dark' }) })
    act(() => result.current.setMode('light'))
    expect(result.current.mode).toBe('light')
    expect(result.current.resolved).toBe('light')
  })
})
