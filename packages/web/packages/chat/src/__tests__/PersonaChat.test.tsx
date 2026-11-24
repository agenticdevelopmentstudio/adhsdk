import { describe, it, expect, vi } from 'vitest'
import { render, fireEvent } from '@testing-library/react'
import { useState } from 'react'

const calls = vi.hoisted(() => ({
  inline: [] as Record<string, unknown>[],
  threePane: [] as Record<string, unknown>[],
  mobile: [] as Record<string, unknown>[],
  mounts: [] as string[],
  unmounts: [] as string[],
}))

vi.mock('../modes/InlineChat', async () => {
  const React = await import('react')
  return {
    InlineChat: (props: Record<string, unknown>) => {
      calls.inline.push(props)
      React.useEffect(() => {
        calls.mounts.push('inline')
        return () => {
          calls.unmounts.push('inline')
        }
      }, [])
      const [n] = React.useState(Math.random())
      return <div data-testid="inline" data-n={n} />
    },
  }
})
vi.mock('../modes/ThreePaneChat', async () => {
  const React = await import('react')
  return {
    ThreePaneChat: (props: Record<string, unknown>) => {
      calls.threePane.push(props)
      React.useEffect(() => {
        calls.mounts.push('three-pane')
        return () => {
          calls.unmounts.push('three-pane')
        }
      }, [])
      return <div data-testid="three-pane" />
    },
  }
})
vi.mock('../modes/MobileChat', () => ({
  MobileChat: (props: Record<string, unknown>) => {
    calls.mobile.push(props)
    return <div data-testid="mobile" />
  },
}))

import { PersonaChat } from '../modes/PersonaChat'
import type { ChatBackend } from '../backends/types'
import type { ChatParticipant } from '../types'

const backend = { id: 'backend' } as unknown as ChatBackend
const persona = { id: 'persona', name: 'P' } as unknown as ChatParticipant
const user = { id: 'user', name: 'U' } as unknown as ChatParticipant
const sizing = { inactive: { mode: 'minimal' } } as never

function last(list: Record<string, unknown>[]) {
  return list[list.length - 1]
}

function reset() {
  calls.inline.length = 0
  calls.threePane.length = 0
  calls.mobile.length = 0
  calls.mounts.length = 0
  calls.unmounts.length = 0
}

describe('PersonaChat', () => {
  it('persona-chat-001 renders InlineChat for mode inline', () => {
    reset()
    const { queryByTestId } = render(<PersonaChat mode="inline" backend={backend} persona={persona} />)
    expect(queryByTestId('inline')).not.toBeNull()
    expect(queryByTestId('three-pane')).toBeNull()
    expect(queryByTestId('mobile')).toBeNull()
  })

  it('persona-chat-002 renders ThreePaneChat for mode three-pane', () => {
    reset()
    const { queryByTestId } = render(<PersonaChat mode="three-pane" backend={backend} persona={persona} />)
    expect(queryByTestId('three-pane')).not.toBeNull()
    expect(queryByTestId('inline')).toBeNull()
    expect(queryByTestId('mobile')).toBeNull()
  })

  it('persona-chat-003 renders MobileChat for mode mobile', () => {
    reset()
    const { queryByTestId } = render(<PersonaChat mode="mobile" backend={backend} persona={persona} />)
    expect(queryByTestId('mobile')).not.toBeNull()
    expect(queryByTestId('inline')).toBeNull()
    expect(queryByTestId('three-pane')).toBeNull()
  })

  it('persona-chat-004 forwards backend to every layout', () => {
    reset()
    render(<PersonaChat mode="inline" backend={backend} persona={persona} />)
    render(<PersonaChat mode="three-pane" backend={backend} persona={persona} />)
    render(<PersonaChat mode="mobile" backend={backend} persona={persona} />)
    expect(last(calls.inline).backend).toBe(backend)
    expect(last(calls.threePane).backend).toBe(backend)
    expect(last(calls.mobile).backend).toBe(backend)
  })

  it('persona-chat-005 forwards persona to every layout', () => {
    reset()
    render(<PersonaChat mode="inline" backend={backend} persona={persona} />)
    render(<PersonaChat mode="three-pane" backend={backend} persona={persona} />)
    render(<PersonaChat mode="mobile" backend={backend} persona={persona} />)
    expect(last(calls.inline).persona).toBe(persona)
    expect(last(calls.threePane).persona).toBe(persona)
    expect(last(calls.mobile).persona).toBe(persona)
  })

  it('persona-chat-006 forwards user when provided', () => {
    reset()
    render(<PersonaChat mode="inline" backend={backend} persona={persona} user={user} />)
    render(<PersonaChat mode="three-pane" backend={backend} persona={persona} user={user} />)
    render(<PersonaChat mode="mobile" backend={backend} persona={persona} user={user} />)
    expect(last(calls.inline).user).toBe(user)
    expect(last(calls.threePane).user).toBe(user)
    expect(last(calls.mobile).user).toBe(user)
  })

  it('persona-chat-007 child receives undefined user when omitted', () => {
    reset()
    render(<PersonaChat mode="inline" backend={backend} persona={persona} />)
    render(<PersonaChat mode="three-pane" backend={backend} persona={persona} />)
    render(<PersonaChat mode="mobile" backend={backend} persona={persona} />)
    expect(last(calls.inline).user).toBeUndefined()
    expect(last(calls.threePane).user).toBeUndefined()
    expect(last(calls.mobile).user).toBeUndefined()
  })

  it('persona-chat-008 forwards welcomeMessage when provided', () => {
    reset()
    render(<PersonaChat mode="inline" backend={backend} persona={persona} welcomeMessage="hi" />)
    render(<PersonaChat mode="three-pane" backend={backend} persona={persona} welcomeMessage="hi" />)
    render(<PersonaChat mode="mobile" backend={backend} persona={persona} welcomeMessage="hi" />)
    expect(last(calls.inline).welcomeMessage).toBe('hi')
    expect(last(calls.threePane).welcomeMessage).toBe('hi')
    expect(last(calls.mobile).welcomeMessage).toBe('hi')
  })

  it('persona-chat-009 child receives undefined welcomeMessage when omitted', () => {
    reset()
    render(<PersonaChat mode="inline" backend={backend} persona={persona} />)
    render(<PersonaChat mode="three-pane" backend={backend} persona={persona} />)
    render(<PersonaChat mode="mobile" backend={backend} persona={persona} />)
    expect(last(calls.inline).welcomeMessage).toBeUndefined()
    expect(last(calls.threePane).welcomeMessage).toBeUndefined()
    expect(last(calls.mobile).welcomeMessage).toBeUndefined()
  })

  it('persona-chat-010 forwards className in inline and three-pane modes', () => {
    reset()
    render(<PersonaChat mode="inline" backend={backend} persona={persona} className="x" />)
    render(<PersonaChat mode="three-pane" backend={backend} persona={persona} className="x" />)
    expect(last(calls.inline).className).toBe('x')
    expect(last(calls.threePane).className).toBe('x')
  })

  it('persona-chat-011 forwards sizing to InlineChat', () => {
    reset()
    render(<PersonaChat mode="inline" backend={backend} persona={persona} sizing={sizing} />)
    expect(last(calls.inline).sizing).toBe(sizing)
  })

  it('persona-chat-012 does not forward sizing to ThreePaneChat', () => {
    reset()
    render(<PersonaChat mode="three-pane" backend={backend} persona={persona} sizing={sizing} />)
    expect('sizing' in last(calls.threePane)).toBe(false)
  })

  it('persona-chat-013 forwards open=true to MobileChat', () => {
    reset()
    render(<PersonaChat mode="mobile" backend={backend} persona={persona} open />)
    expect(last(calls.mobile).open).toBe(true)
  })

  it('persona-chat-014 defaults open to false for MobileChat', () => {
    reset()
    render(<PersonaChat mode="mobile" backend={backend} persona={persona} />)
    expect(last(calls.mobile).open).toBe(false)
  })

  it('persona-chat-015 forwards onClose to MobileChat', () => {
    reset()
    const onClose = vi.fn()
    render(<PersonaChat mode="mobile" backend={backend} persona={persona} onClose={onClose} />)
    expect(last(calls.mobile).onClose).toBe(onClose)
  })

  it('persona-chat-016 forwards a default no-op onClose to MobileChat', () => {
    reset()
    render(<PersonaChat mode="mobile" backend={backend} persona={persona} />)
    const fn = last(calls.mobile).onClose as () => void
    expect(typeof fn).toBe('function')
    expect(fn()).toBeUndefined()
  })

  it('persona-chat-017 does not forward className to MobileChat', () => {
    reset()
    render(<PersonaChat mode="mobile" backend={backend} persona={persona} className="x" />)
    expect('className' in last(calls.mobile)).toBe(false)
  })

  it('persona-chat-018 does not forward sizing to MobileChat', () => {
    reset()
    render(<PersonaChat mode="mobile" backend={backend} persona={persona} sizing={sizing} />)
    expect('sizing' in last(calls.mobile)).toBe(false)
  })

  it('persona-chat-019 does not forward onClose to InlineChat', () => {
    reset()
    render(<PersonaChat mode="inline" backend={backend} persona={persona} onClose={() => {}} />)
    expect('onClose' in last(calls.inline)).toBe(false)
  })

  it('persona-chat-020 does not forward open to InlineChat', () => {
    reset()
    render(<PersonaChat mode="inline" backend={backend} persona={persona} open />)
    expect('open' in last(calls.inline)).toBe(false)
  })

  it('persona-chat-021 renders nothing for an unknown mode', () => {
    reset()
    const { container } = render(
      <PersonaChat mode={'bogus' as never} backend={backend} persona={persona} />,
    )
    expect(container.innerHTML).toBe('')
    expect(PersonaChat({ mode: 'bogus' as never, backend, persona })).toBeUndefined()
  })

  it('persona-chat-022 forwards undefined backend and persona without throwing', () => {
    reset()
    expect(() =>
      render(<PersonaChat mode="inline" backend={undefined as never} persona={undefined as never} />),
    ).not.toThrow()
    expect(last(calls.inline).backend).toBeUndefined()
    expect(last(calls.inline).persona).toBeUndefined()
  })

  it('persona-chat-023 changing mode unmounts the old layout and mounts the new one', () => {
    reset()
    function Harness() {
      const [mode, setMode] = useState<'inline' | 'three-pane'>('inline')
      return (
        <>
          <button onClick={() => setMode('three-pane')}>switch</button>
          <PersonaChat mode={mode} backend={backend} persona={persona} />
        </>
      )
    }
    const { getByText, queryByTestId } = render(<Harness />)
    const firstN = queryByTestId('inline')?.getAttribute('data-n')
    expect(firstN).not.toBeNull()
    fireEvent.click(getByText('switch'))
    expect(calls.unmounts).toContain('inline')
    expect(calls.mounts).toEqual(['inline', 'three-pane'])
    expect(queryByTestId('inline')).toBeNull()
    expect(queryByTestId('three-pane')).not.toBeNull()
  })
})
