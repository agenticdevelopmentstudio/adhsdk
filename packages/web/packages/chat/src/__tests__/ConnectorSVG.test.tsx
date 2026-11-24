import { useEffect, type RefObject } from 'react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { act, cleanup, render } from '@testing-library/react'
import { ConnectorSVG, type ConnectorPair } from '../modes/three-pane/ConnectorSVG'
import {
  ConnectorRegistryProvider,
  useConnectorRegistry,
} from '../modes/three-pane/connectors/ConnectorRegistry'

// ---- ResizeObserver / requestAnimationFrame stubs ----
class FakeRO {
  static instances: FakeRO[] = []
  observed: Element[] = []
  disconnected = false
  constructor(public cb: () => void) {
    FakeRO.instances.push(this)
  }
  observe(el: Element) {
    this.observed.push(el)
  }
  disconnect() {
    this.disconnected = true
  }
  unobserve() {}
}

let rafQueue: Map<number, FrameRequestCallback>
let nextRaf: number
let rafSpy: ReturnType<typeof vi.fn>
let cafSpy: ReturnType<typeof vi.fn>

beforeEach(() => {
  FakeRO.instances = []
  rafQueue = new Map()
  nextRaf = 1
  rafSpy = vi.fn((cb: FrameRequestCallback) => {
    const id = nextRaf++
    rafQueue.set(id, cb)
    return id
  })
  cafSpy = vi.fn((id: number) => {
    rafQueue.delete(id)
  })
  vi.stubGlobal('ResizeObserver', FakeRO)
  vi.stubGlobal('requestAnimationFrame', rafSpy)
  vi.stubGlobal('cancelAnimationFrame', cafSpy)
})

afterEach(() => {
  cleanup()
  vi.unstubAllGlobals()
  vi.restoreAllMocks()
})

function flushRaf() {
  const cbs = Array.from(rafQueue.values())
  rafQueue.clear()
  act(() => cbs.forEach((cb) => cb(0)))
}

type Box = { left: number; top: number; width: number; height: number }

function mkEl(box: Box) {
  const el = document.createElement('div')
  el.getBoundingClientRect = () =>
    ({
      left: box.left,
      top: box.top,
      width: box.width,
      height: box.height,
      right: box.left + box.width,
      bottom: box.top + box.height,
      x: box.left,
      y: box.top,
      toJSON() {},
    }) as DOMRect
  return el
}

function mkFrame(box: Box): RefObject<HTMLDivElement | null> {
  return { current: mkEl(box) as HTMLDivElement }
}

function Registrar({ els }: { els: Record<string, HTMLElement> }) {
  const reg = useConnectorRegistry()
  useEffect(() => {
    const offs = Object.entries(els).map(([id, el]) => reg.register(id, el))
    return () => offs.forEach((off) => off())
  }, [reg, els])
  return null
}

function ui(
  frameRef: RefObject<HTMLDivElement | null>,
  pairs: ConnectorPair[],
  els: Record<string, HTMLElement>,
) {
  return (
    <ConnectorRegistryProvider>
      <Registrar els={els} />
      <ConnectorSVG frameRef={frameRef} pairs={pairs} />
    </ConnectorRegistryProvider>
  )
}

const BOX = { left: 0, top: 0, width: 10, height: 10 }
const PAIR: ConnectorPair[] = [{ from: 'el1', to: 'el2' }]
const lines = (c: HTMLElement) => Array.from(c.querySelectorAll('line'))
const circles = (c: HTMLElement) => Array.from(c.querySelectorAll('circle'))
const lastRO = () => FakeRO.instances[FakeRO.instances.length - 1]

describe('ConnectorSVG conformance vectors', () => {
  it('connector-001 svg root has class pc-connector-svg, aria-hidden true, one connector', () => {
    const els = { el1: mkEl(BOX), el2: mkEl(BOX) }
    const { container } = render(ui(mkFrame(BOX), PAIR, els))
    const svg = container.querySelector('svg')!
    expect(svg.getAttribute('class')).toBe('pc-connector-svg')
    expect(svg.getAttribute('aria-hidden')).toBe('true')
    expect(svg.querySelectorAll('g').length).toBe(1)
    expect(lines(container).length).toBe(1)
  })

  it('connector-002 the line runs from the center of el1 to the center of el2', () => {
    const els = {
      el1: mkEl({ left: 0, top: 0, width: 20, height: 10 }),
      el2: mkEl({ left: 100, top: 50, width: 40, height: 20 }),
    }
    const { container } = render(ui(mkFrame(BOX), PAIR, els))
    const l = lines(container)[0]
    expect([
      l.getAttribute('x1'),
      l.getAttribute('y1'),
      l.getAttribute('x2'),
      l.getAttribute('y2'),
    ]).toEqual(['10', '5', '120', '60'])
  })

  it('connector-003 a pair with an unregistered endpoint renders nothing', () => {
    const els = { el1: mkEl(BOX) }
    const { container } = render(ui(mkFrame(BOX), [{ from: 'el1', to: 'missing' }], els))
    expect(lines(container).length).toBe(0)
    expect(circles(container).length).toBe(0)
  })

  it('connector-004 two circles of r=3 sit at the line endpoints', () => {
    const els = {
      el1: mkEl({ left: 0, top: 0, width: 20, height: 10 }),
      el2: mkEl({ left: 100, top: 50, width: 40, height: 20 }),
    }
    const { container } = render(ui(mkFrame(BOX), PAIR, els))
    const cs = circles(container)
    expect(cs.length).toBe(2)
    expect(cs.map((c) => c.getAttribute('r'))).toEqual(['3', '3'])
    expect([cs[0].getAttribute('cx'), cs[0].getAttribute('cy')]).toEqual(['10', '5'])
    expect([cs[1].getAttribute('cx'), cs[1].getAttribute('cy')]).toEqual(['120', '60'])
  })

  it('connector-005 stroke and circle fill use the source element computed color', () => {
    const els = { el1: mkEl(BOX), el2: mkEl(BOX) }
    const real = window.getComputedStyle.bind(window)
    vi.spyOn(window, 'getComputedStyle').mockImplementation(
      (el: Element, pseudo?: string | null) => {
        if (el === els.el1) return { color: '#ff0000' } as CSSStyleDeclaration
        return real(el, pseudo)
      },
    )
    const { container } = render(ui(mkFrame(BOX), PAIR, els))
    expect(lines(container)[0].getAttribute('stroke')).toBe('#ff0000')
    for (const c of circles(container)) expect(c.getAttribute('fill')).toBe('#ff0000')
  })

  it('connector-006 endpoints are computed relative to the container reference origin', () => {
    const els = {
      el1: mkEl({ left: 150, top: 250, width: 100, height: 50 }),
      el2: mkEl({ left: 150, top: 250, width: 100, height: 50 }),
    }
    const frame = mkFrame({ left: 100, top: 200, width: 500, height: 500 })
    const { container } = render(ui(frame, PAIR, els))
    const l = lines(container)[0]
    expect(l.getAttribute('x1')).toBe('100')
    expect(l.getAttribute('y1')).toBe('75')
  })

  it('connector-007 a ResizeObserver callback redraws endpoints at the new centers', () => {
    const box = { left: 0, top: 0, width: 100, height: 50 }
    const els = { el1: mkEl(box), el2: mkEl({ left: 200, top: 0, width: 20, height: 20 }) }
    const { container } = render(ui(mkFrame(BOX), PAIR, els))
    expect(lines(container)[0].getAttribute('x1')).toBe('50')
    box.width = 200
    box.height = 100
    act(() => lastRO().cb())
    flushRaf()
    expect(lines(container)[0].getAttribute('x1')).toBe('100')
    expect(lines(container)[0].getAttribute('y1')).toBe('50')
  })

  it('connector-008 rapid resize events schedule a single requestAnimationFrame', () => {
    const els = { el1: mkEl(BOX), el2: mkEl(BOX) }
    render(ui(mkFrame(BOX), PAIR, els))
    rafSpy.mockClear()
    const ro = lastRO()
    act(() => {
      ro.cb()
      ro.cb()
      ro.cb()
    })
    expect(rafSpy).toHaveBeenCalledTimes(1)
  })

  it('connector-009 unmounting with a pending frame cancels it', () => {
    const els = { el1: mkEl(BOX), el2: mkEl(BOX) }
    const { unmount } = render(ui(mkFrame(BOX), PAIR, els))
    act(() => lastRO().cb())
    const handle = rafSpy.mock.results[rafSpy.mock.results.length - 1].value
    unmount()
    expect(cafSpy).toHaveBeenCalledWith(handle)
  })

  it('connector-010 a window resize event recomputes positions', () => {
    const box = { left: 0, top: 0, width: 20, height: 10 }
    const els = { el1: mkEl(box), el2: mkEl(BOX) }
    const { container } = render(ui(mkFrame(BOX), PAIR, els))
    expect(lines(container)[0].getAttribute('x1')).toBe('10')
    box.width = 60
    act(() => {
      window.dispatchEvent(new Event('resize'))
    })
    flushRaf()
    expect(lines(container)[0].getAttribute('x1')).toBe('30')
  })

  it('connector-011 a scroll event on any element recomputes via the capture-phase window listener', () => {
    const box = { left: 0, top: 0, width: 20, height: 10 }
    const els = { el1: mkEl(box), el2: mkEl(BOX) }
    const { container } = render(ui(mkFrame(BOX), PAIR, els))
    box.width = 60
    const other = document.createElement('div')
    document.body.appendChild(other)
    act(() => {
      other.dispatchEvent(new Event('scroll'))
    })
    flushRaf()
    expect(lines(container)[0].getAttribute('x1')).toBe('30')
    other.remove()
  })

  it('connector-012 unmount disconnects the observer and removes resize and scroll listeners', () => {
    const add = vi.spyOn(window, 'addEventListener')
    const remove = vi.spyOn(window, 'removeEventListener')
    const els = { el1: mkEl(BOX), el2: mkEl(BOX) }
    const { unmount } = render(ui(mkFrame(BOX), PAIR, els))
    const ro = lastRO()
    const resizeFn = add.mock.calls.filter((c) => c[0] === 'resize').pop()![1]
    const scrollFn = add.mock.calls.filter((c) => c[0] === 'scroll').pop()![1]
    unmount()
    expect(ro.disconnected).toBe(true)
    expect(remove).toHaveBeenCalledWith('resize', resizeFn)
    expect(remove).toHaveBeenCalledWith('scroll', scrollFn, true)
  })

  it('connector-013 a null container reference renders an empty svg and does no computation', () => {
    const els = { el1: mkEl(BOX), el2: mkEl(BOX) }
    const { container } = render(ui({ current: null }, PAIR, els))
    expect(container.querySelector('svg')).not.toBeNull()
    expect(lines(container).length).toBe(0)
    expect(circles(container).length).toBe(0)
    expect(FakeRO.instances.length).toBe(0)
  })

  it('connector-014 empty pairs render an empty svg', () => {
    const els = { el1: mkEl(BOX), el2: mkEl(BOX) }
    const { container } = render(ui(mkFrame(BOX), [], els))
    expect(container.querySelector('svg')).not.toBeNull()
    expect(lines(container).length).toBe(0)
    expect(circles(container).length).toBe(0)
  })

  it('connector-015 changing pairs re-establishes the observer and recomputes', () => {
    const el3 = mkEl({ left: 300, top: 0, width: 20, height: 20 })
    const els = { el1: mkEl({ left: 0, top: 0, width: 20, height: 10 }), el2: mkEl(BOX), el3 }
    const frame = mkFrame(BOX)
    const { container, rerender } = render(ui(frame, PAIR, els))
    const before = FakeRO.instances.length
    const next: ConnectorPair[] = [{ from: 'el1', to: 'el3' }]
    rerender(ui(frame, next, els))
    expect(FakeRO.instances.length).toBeGreaterThan(before)
    const ro = lastRO()
    expect(ro.observed).toContain(frame.current)
    expect(ro.observed).toEqual(expect.arrayContaining([els.el1, els.el2, els.el3]))
    expect(lines(container)[0].getAttribute('x2')).toBe('310')
  })

  it('connector-016 line stroke width and opacity and circle fill opacity are fixed', () => {
    const els = { el1: mkEl(BOX), el2: mkEl(BOX) }
    const { container } = render(ui(mkFrame(BOX), PAIR, els))
    const l = lines(container)[0]
    expect(l.getAttribute('stroke-width')).toBe('1')
    expect(l.getAttribute('stroke-opacity')).toBe('0.4')
    for (const c of circles(container)) expect(c.getAttribute('fill-opacity')).toBe('0.4')
  })

  it('connector-017 a zero-size element still renders using its position as the center', () => {
    const els = { el1: mkEl({ left: 50, top: 50, width: 0, height: 0 }), el2: mkEl(BOX) }
    const frame = mkFrame({ left: 0, top: 0, width: 100, height: 100 })
    const { container } = render(ui(frame, PAIR, els))
    const l = lines(container)[0]
    expect(l.getAttribute('x1')).toBe('50')
    expect(l.getAttribute('y1')).toBe('50')
  })

  it('connector-018 self pairs and duplicate pairs each render their own line', () => {
    const els = {
      el1: mkEl({ left: 0, top: 0, width: 20, height: 10 }),
      el2: mkEl({ left: 100, top: 0, width: 20, height: 10 }),
    }
    const pairs: ConnectorPair[] = [
      { from: 'el1', to: 'el1' },
      { from: 'el1', to: 'el2' },
      { from: 'el1', to: 'el2' },
    ]
    const { container } = render(ui(mkFrame(BOX), pairs, els))
    const ls = lines(container)
    expect(ls.length).toBe(3)
    expect(ls[0].getAttribute('x1')).toBe(ls[0].getAttribute('x2'))
    expect(ls[0].getAttribute('y1')).toBe(ls[0].getAttribute('y2'))
    expect(ls[1].outerHTML).toBe(ls[2].outerHTML)
    expect(circles(container).length).toBe(6)
  })
})
