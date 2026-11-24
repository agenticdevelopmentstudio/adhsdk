// Conformance tests for cookbook/themes/appearance-store that need a real React renderer:
// AS-019 (hook identity) and AS-011 (set merges, caches and re-renders). This file never resets
// modules, so the store and the renderer share one React. AS-019 runs first, before anything has
// read the store, so the cache is what the first read loads.
import { act, cleanup, renderHook } from '@testing-library/react'
import { afterEach, describe, expect, it } from 'vitest'

import { APPEARANCE_DEFAULTS, APPEARANCE_STORAGE_KEY } from '../appearance'
import { adoptAppearance, useAppearancePreferences } from '../appearance-store'

afterEach(() => {
  cleanup()
})

describe('useAppearancePreferences', () => {
  it('AS-019: the hook loads the cache on first read and keeps { prefs, set } stable between commits', () => {
    window.localStorage.setItem(APPEARANCE_STORAGE_KEY, '{"colorMode":"dark"}')

    const { result, rerender } = renderHook(() => useAppearancePreferences())
    const first = result.current
    expect(first.prefs.colorMode).toBe('dark')

    rerender()
    expect(result.current).toBe(first)
    expect(result.current.prefs).toBe(first.prefs)
    expect(result.current.set).toBe(first.set)
  })

  it('AS-011: set merges the patch, caches it and re-renders once', () => {
    act(() => adoptAppearance({ ...APPEARANCE_DEFAULTS }))
    let renders = 0
    const { result } = renderHook(() => {
      renders += 1
      return useAppearancePreferences()
    })
    const rendersBefore = renders

    act(() => result.current.set({ contrast: 'high' }))

    expect(result.current.prefs).toEqual({ ...APPEARANCE_DEFAULTS, contrast: 'high' })
    expect(window.localStorage.getItem(APPEARANCE_STORAGE_KEY)).toBe(
      JSON.stringify({ ...APPEARANCE_DEFAULTS, contrast: 'high' }),
    )
    expect(renders - rendersBefore).toBe(1)
  })
})
