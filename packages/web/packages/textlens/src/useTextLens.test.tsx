import { act, createElement, useRef, type ReactElement } from 'react'
import { createRoot, type Root } from 'react-dom/client'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const start = vi.fn()
const destroy = vi.fn()
vi.mock('./lens.js', () => ({
  createLens: vi.fn(() => ({ start, stop: vi.fn(), destroy })),
}))

import { useTextLens, type UseTextLensOptions } from './useTextLens.js'

;(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true

function Harness(props: { options: UseTextLensOptions }): ReactElement {
  const ref = useRef<HTMLDivElement>(null)
  useTextLens(ref, props.options)
  return createElement('div', { ref }, createElement('span', { className: 'tag' }, 'abc'))
}

let host: HTMLElement
let root: Root
let mounted: boolean

beforeEach(() => {
  vi.useFakeTimers()
  start.mockClear()
  destroy.mockClear()
  host = document.createElement('div')
  document.body.appendChild(host)
  root = createRoot(host)
  mounted = true
})

afterEach(() => {
  if (mounted) act(() => root.unmount())
  host.remove()
  vi.useRealTimers()
})

function render(options: UseTextLensOptions): void {
  act(() => root.render(createElement(Harness, { options })))
}

describe('useTextLens', () => {
  it('text-lens-025: defers only the first sweep by startDelay, then resweeps immediately', () => {
    render({ selector: '.tag', startDelay: 500 })
    expect(start).not.toHaveBeenCalled()
    act(() => {
      vi.advanceTimersByTime(499)
    })
    expect(start).not.toHaveBeenCalled()
    act(() => {
      vi.advanceTimersByTime(1)
    })
    expect(start).toHaveBeenCalledTimes(1)

    render({ selector: '.tag', startDelay: 500, enabled: false })
    expect(destroy).toHaveBeenCalledTimes(1)

    render({ selector: '.tag', startDelay: 500, enabled: true })
    act(() => {
      vi.advanceTimersByTime(0)
    })
    expect(start).toHaveBeenCalledTimes(2)
  })

  it('text-lens-026: clears the pending timer and destroys the lens on unmount', () => {
    render({ selector: '.tag', startDelay: 500 })
    act(() => {
      vi.advanceTimersByTime(100)
    })
    act(() => root.unmount())
    mounted = false
    act(() => {
      vi.advanceTimersByTime(1000)
    })

    expect(start).not.toHaveBeenCalled()
    expect(destroy).toHaveBeenCalledTimes(1)
  })
})
