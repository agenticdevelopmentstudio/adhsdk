import { describe, expect, it, beforeEach, afterEach, vi } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useAllImagesLoaded } from '../hooks/useAllImagesLoaded'
import type { ContentItem } from '../types'

/* A controllable stand-in for the global Image: the hook assigns onload/onerror
 * and src, and the test decides when each image settles. */
class FakeImage {
  static instances: FakeImage[] = []
  onload: (() => void) | null = null
  onerror: (() => void) | null = null
  src = ''
  constructor() {
    FakeImage.instances.push(this)
  }
}

describe('useAllImagesLoaded', () => {
  const RealImage = globalThis.Image

  beforeEach(() => {
    FakeImage.instances = []
    globalThis.Image = FakeImage as unknown as typeof Image
  })

  afterEach(() => {
    globalThis.Image = RealImage
  })

  it('chat-coordinator-hooks-071 returns true immediately for an empty content set', () => {
    const { result } = renderHook(() => useAllImagesLoaded([]))
    expect(result.current).toBe(true)
    expect(FakeImage.instances).toHaveLength(0)
    const { result: undef } = renderHook(() => useAllImagesLoaded(undefined))
    expect(undef.current).toBe(true)
  })

  it('chat-coordinator-hooks-072 waits for every image, counting a load error as settled', () => {
    const content: ContentItem[] = [
      { type: 'image', src: 'a.png' },
      { type: 'image', src: 'b.png' },
    ]
    const { result } = renderHook(() => useAllImagesLoaded(content))
    expect(FakeImage.instances.map((i) => i.src)).toEqual(['a.png', 'b.png'])
    expect(result.current).toBe(false)

    act(() => FakeImage.instances[0].onload!())
    expect(result.current).toBe(false)

    act(() => FakeImage.instances[1].onerror!())
    expect(result.current).toBe(true)
  })
})
