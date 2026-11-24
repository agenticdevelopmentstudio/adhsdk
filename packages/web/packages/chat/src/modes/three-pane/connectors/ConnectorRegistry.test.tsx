import { describe, it, expect, vi } from 'vitest'
import { render, act } from '@testing-library/react'
import { useEffect } from 'react'
import {
  ConnectorRegistryProvider,
  useConnectorRegistry,
  useConnectorRegistryOptional,
  useRegistrySnapshot,
  type RegistryHandle,
  type RegistrySnapshot,
} from './ConnectorRegistry'
import { ConnectorAnchor } from './ConnectorAnchor'

type Snapshot = ReturnType<ReturnType<typeof useConnectorRegistry>['snapshot']>

function Probe({ onReady }: { onReady: (snap: Snapshot) => void }) {
  const reg = useConnectorRegistry()
  useEffect(() => {
    onReady(reg.snapshot())
  }, [reg, onReady])
  return null
}

describe('ConnectorRegistry', () => {
  it('registers and unregisters anchors by id', () => {
    let snap: Snapshot | null = null
    const { unmount } = render(
      <ConnectorRegistryProvider>
        <ConnectorAnchor id="msg-0-out" />
        <ConnectorAnchor id="panel-0-in" />
        <Probe onReady={(s) => (snap = s)} />
      </ConnectorRegistryProvider>,
    )
    expect(snap).toBeTruthy()
    expect(snap!.has('msg-0-out')).toBe(true)
    expect(snap!.has('panel-0-in')).toBe(true)
    unmount()
  })
})

function mount(): RegistryHandle {
  let handle: RegistryHandle | null = null
  function Grab() {
    handle = useConnectorRegistry()
    return null
  }
  render(
    <ConnectorRegistryProvider>
      <Grab />
    </ConnectorRegistryProvider>,
  )
  return handle!
}

const el = () => document.createElement('div')

describe('ConnectorRegistry conformance vectors', () => {
  it('registry-001 register stores the element under its id', () => {
    const reg = mount()
    const a = el()
    reg.register('btn1', a)
    expect(reg.snapshot().get('btn1')).toBe(a)
  })

  it('registry-002 the returned function removes the element', () => {
    const reg = mount()
    const unreg = reg.register('btn1', el())
    unreg()
    expect(reg.snapshot().get('btn1')).toBeUndefined()
    expect(reg.snapshot().has('btn1')).toBe(false)
  })

  it('registry-003 re-registering the same element is a no-op', () => {
    const reg = mount()
    const a = el()
    reg.register('btn1', a)
    const before = reg.snapshot()
    const listener = vi.fn()
    reg.subscribe(listener)
    const second = reg.register('btn1', a)
    second()
    expect(listener).not.toHaveBeenCalled()
    expect(reg.snapshot()).toBe(before)
    expect(reg.snapshot().get('btn1')).toBe(a)
  })

  it('registry-004 a different element replaces and notifies', () => {
    const reg = mount()
    const b = el()
    reg.register('btn1', el())
    const listener = vi.fn()
    reg.subscribe(listener)
    reg.register('btn1', b)
    expect(listener).toHaveBeenCalledTimes(1)
    expect(reg.snapshot().get('btn1')).toBe(b)
  })

  it('registry-005 listener fires once per real change', () => {
    const reg = mount()
    const a = el()
    const listener = vi.fn()
    reg.subscribe(listener)
    const unreg = reg.register('btn1', a)
    expect(listener).toHaveBeenCalledTimes(1)
    unreg()
    expect(listener).toHaveBeenCalledTimes(2)
    const again = reg.register('btn1', a)
    expect(listener).toHaveBeenCalledTimes(3)
    reg.register('btn1', a)
    expect(listener).toHaveBeenCalledTimes(3)
    again()
    expect(listener).toHaveBeenCalledTimes(4)
    again()
    unreg()
    expect(listener).toHaveBeenCalledTimes(4)
  })

  it('registry-006 snapshot reports has and get after register', () => {
    const reg = mount()
    const a = el()
    reg.register('btn1', a)
    const snap = reg.snapshot()
    expect(snap.has('btn1')).toBe(true)
    expect(snap.get('btn1')).toBe(a)
  })

  it('registry-007 snapshot identity is stable between changes', () => {
    const reg = mount()
    reg.register('btn1', el())
    expect(reg.snapshot()).toBe(reg.snapshot())
  })

  it('registry-008 ids lists every registered id', () => {
    const reg = mount()
    reg.register('btn1', el())
    reg.register('btn2', el())
    expect(reg.snapshot().ids()).toEqual(expect.arrayContaining(['btn1', 'btn2']))
    expect(reg.snapshot().ids()).toHaveLength(2)
  })

  it('registry-009 useConnectorRegistry throws without a provider', () => {
    function Bad() {
      useConnectorRegistry()
      return null
    }
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {})
    expect(() => render(<Bad />)).toThrow(/ConnectorRegistryProvider/)
    spy.mockRestore()
  })

  it('registry-010 the optional hook returns null outside, the handle inside', () => {
    let outside: RegistryHandle | null | undefined
    let inside: RegistryHandle | null | undefined
    let real: RegistryHandle | null = null
    function Out() {
      outside = useConnectorRegistryOptional()
      return null
    }
    function In() {
      inside = useConnectorRegistryOptional()
      real = useConnectorRegistry()
      return null
    }
    render(<Out />)
    render(
      <ConnectorRegistryProvider>
        <In />
      </ConnectorRegistryProvider>,
    )
    expect(outside).toBeNull()
    expect(inside).not.toBeNull()
    expect(inside).toBe(real)
  })

  it('registry-011 useRegistrySnapshot throws outside and re-renders per change inside', () => {
    function Bad() {
      useRegistrySnapshot()
      return null
    }
    const spy = vi.spyOn(console, 'error').mockImplementation(() => {})
    expect(() => render(<Bad />)).toThrow(/ConnectorRegistryProvider/)
    spy.mockRestore()

    let renders = 0
    let seen: RegistrySnapshot | null = null
    let handle: RegistryHandle | null = null
    function Watch() {
      handle = useConnectorRegistry()
      seen = useRegistrySnapshot()
      renders++
      return null
    }
    render(
      <ConnectorRegistryProvider>
        <Watch />
      </ConnectorRegistryProvider>,
    )
    const base = renders
    let unreg: () => void = () => {}
    act(() => {
      unreg = handle!.register('btn1', el())
    })
    expect(renders).toBe(base + 1)
    expect(seen!.has('btn1')).toBe(true)
    act(() => unreg())
    expect(renders).toBe(base + 2)
    expect(seen!.has('btn1')).toBe(false)
  })

  it('registry-012 a fresh provider has an empty snapshot', () => {
    const snap = mount().snapshot()
    expect(snap.ids()).toEqual([])
    expect(snap.has('x')).toBe(false)
    expect(snap.get('x')).toBeUndefined()
  })

  it('registry-013 a stale unregister leaves the replacement in place', () => {
    const reg = mount()
    const b = el()
    const unregA = reg.register('btn1', el())
    reg.register('btn1', b)
    const listener = vi.fn()
    reg.subscribe(listener)
    unregA()
    expect(reg.snapshot().get('btn1')).toBe(b)
    expect(listener).not.toHaveBeenCalled()
  })

  it('registry-014 a listener unsubscribed mid-notify is skipped', () => {
    const reg = mount()
    const b = vi.fn()
    let unsubB: () => void = () => {}
    const a = vi.fn(() => unsubB())
    reg.subscribe(a)
    unsubB = reg.subscribe(b)
    reg.register('btn1', el())
    expect(a).toHaveBeenCalledTimes(1)
    expect(b).not.toHaveBeenCalled()
    reg.register('btn2', el())
    expect(a).toHaveBeenCalledTimes(2)
    expect(b).not.toHaveBeenCalled()
  })

  it('registry-015 an earlier snapshot keeps its ids but sees live membership', () => {
    const reg = mount()
    reg.register('btn1', el())
    const s = reg.snapshot()
    const two = el()
    reg.register('btn2', two)
    expect(s.ids()).toEqual(['btn1'])
    expect(s.has('btn2')).toBe(true)
    expect(s.get('btn2')).toBe(two)
    expect(reg.snapshot().ids()).toEqual(expect.arrayContaining(['btn1', 'btn2']))
  })
})
