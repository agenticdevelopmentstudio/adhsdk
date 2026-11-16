// Conformance vectors hub-domain-hooks-035..036 (cookbook adh/hub/messaging/inbox-state): the DM
// composer starts empty for each conversation and ignores a send that settles after a switch.
import { act } from 'react'
import { describe, expect, it } from 'vitest'

import { deferred, renderHook } from './render-hook'
import { useDmComposer } from '../use-dm-composer'

type Props = { chatId: string | null; send: (body: string) => Promise<unknown> }

function mount(chatId: string, send: Props['send']) {
  return renderHook((p: Props) => useDmComposer(p.chatId, p.send), { chatId, send })
}

describe('useDmComposer', () => {
  it('hub-domain-hooks-035: a draft typed to one chat is gone when another is opened', () => {
    const send = async () => undefined
    const h = mount('c1', send)
    act(() => h.result.current.setDraft('hi Alice'))
    h.rerender({ chatId: 'c2', send })
    expect(h.result.current.draft).toBe('')
    h.unmount()
  })

  it('hub-domain-hooks-036: a send that resolves after the switch leaves the new draft alone', async () => {
    const pending = deferred<void>()
    const sent: string[] = []
    const send = (body: string) => {
      sent.push(body)
      return pending.promise
    }
    const h = mount('c1', send)
    act(() => h.result.current.setDraft('hi Alice'))
    let done!: Promise<void>
    act(() => {
      done = h.result.current.submit()
    })
    expect(h.result.current.sending).toBe(true)
    h.rerender({ chatId: 'c2', send })
    act(() => h.result.current.setDraft('hi Bob'))
    await act(async () => {
      pending.resolve()
      await done
    })
    expect(sent).toEqual(['hi Alice'])
    expect(h.result.current.draft).toBe('hi Bob')
    expect(h.result.current.sending).toBe(false)
    expect(h.result.current.sendError).toBeNull()
    h.unmount()
  })

  it('hub-domain-hooks-036: a send that fails after the switch shows no error in the new chat', async () => {
    const pending = deferred<void>()
    const send = () => pending.promise
    const h = mount('c1', send)
    act(() => h.result.current.setDraft('hi Alice'))
    let done!: Promise<void>
    act(() => {
      done = h.result.current.submit()
    })
    h.rerender({ chatId: 'c2', send })
    act(() => h.result.current.setDraft('hi Bob'))
    await act(async () => {
      pending.reject(Object.assign(new Error('forbidden'), { status: 403 }))
      await done
    })
    expect(h.result.current.draft).toBe('hi Bob')
    expect(h.result.current.sendError).toBeNull()
    h.unmount()
  })

  it('clears the draft after a send in the same chat, and shows its error', async () => {
    const h = mount('c1', async () => undefined)
    act(() => h.result.current.setDraft('hi'))
    await act(async () => {
      await h.result.current.submit()
    })
    expect(h.result.current.draft).toBe('')
    const failing = renderHook((p: Props) => useDmComposer(p.chatId, p.send), {
      chatId: 'c1',
      send: () => Promise.reject(Object.assign(new Error('x'), { status: 403 })),
    })
    act(() => failing.result.current.setDraft('hi'))
    await act(async () => {
      await failing.result.current.submit()
    })
    expect(failing.result.current.sendError).toBe("You can't message this person.")
    expect(failing.result.current.draft).toBe('hi')
    h.unmount()
    failing.unmount()
  })
})
