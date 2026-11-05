import { act, renderHook, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import {
  useVersionedDocument,
  type VersionedDocumentSource,
  type VersionedSaveResult,
  type VersionedText,
} from '../hooks/useVersionedDocument'

class HttpError extends Error {
  constructor(public status: number) {
    super(`${status} failed`)
  }
}

const load = vi.fn<() => Promise<VersionedText>>()
const save = vi.fn<(text: string, base: string) => Promise<VersionedSaveResult>>()

function setup(key = 'a') {
  return renderHook((props: { key: string }) => useVersionedDocument({ key: props.key, load, save } satisfies VersionedDocumentSource), {
    initialProps: { key },
  })
}

async function loaded() {
  const hook = setup()
  await waitFor(() => expect(hook.result.current.doc).not.toBeNull())
  return hook
}

beforeEach(() => {
  load.mockReset().mockResolvedValue({ text: 'one', version: 'v1' })
  save.mockReset()
})

describe('useVersionedDocument', () => {
  it('loads the document and shows its text with no draft', async () => {
    const { result } = await loaded()
    expect(result.current.value).toBe('one')
    expect(result.current.dirty).toBe(false)
  })

  it('typing back to the stored text is not an unsaved edit', async () => {
    const { result } = await loaded()
    act(() => result.current.edit('two'))
    expect(result.current.dirty).toBe(true)
    expect(result.current.isDirty()).toBe(true)
    act(() => result.current.edit('one'))
    expect(result.current.dirty).toBe(false)
    expect(result.current.isDirty()).toBe(false)
  })

  it('saves against the loaded version and adopts the new one', async () => {
    save.mockResolvedValue({ ok: true, version: 'v2' })
    const { result } = await loaded()
    act(() => result.current.edit('two'))
    await act(() => result.current.save())
    expect(save).toHaveBeenCalledWith('two', 'v1')
    expect(result.current.doc).toEqual({ text: 'two', version: 'v2' })
    expect(result.current.dirty).toBe(false)
  })

  it('keeps edits typed while a save was in flight', async () => {
    let finish!: (r: VersionedSaveResult) => void
    save.mockReturnValue(new Promise((r) => { finish = r }))
    const { result } = await loaded()
    act(() => result.current.edit('two'))
    let pending!: Promise<void>
    act(() => { pending = result.current.save() })
    act(() => result.current.edit('three'))
    await act(async () => { finish({ ok: true, version: 'v2' }); await pending })
    expect(result.current.doc?.text).toBe('two')
    expect(result.current.value).toBe('three')
    expect(result.current.dirty).toBe(true)
  })

  it('on a conflict, overwrite saves against their version', async () => {
    save
      .mockResolvedValueOnce({ ok: false, conflict: { text: 'theirs', version: 'v9' } })
      .mockResolvedValueOnce({ ok: true, version: 'v10' })
    const { result } = await loaded()
    act(() => result.current.edit('mine'))
    await act(() => result.current.save())
    expect(result.current.conflict).toEqual({ text: 'theirs', version: 'v9' })
    await act(() => result.current.overwrite())
    expect(save).toHaveBeenLastCalledWith('mine', 'v9')
    expect(result.current.conflict).toBeNull()
    expect(result.current.doc).toEqual({ text: 'mine', version: 'v10' })
  })

  it('on a conflict, takeTheirs drops the draft and adopts their version', async () => {
    save.mockResolvedValue({ ok: false, conflict: { text: 'theirs', version: 'v9' } })
    const { result } = await loaded()
    act(() => result.current.edit('mine'))
    await act(() => result.current.save())
    act(() => result.current.takeTheirs())
    expect(result.current.value).toBe('theirs')
    expect(result.current.dirty).toBe(false)
    expect(result.current.conflict).toBeNull()
  })

  it('a change event while editing keeps the draft and flags it; revert then reloads', async () => {
    const { result } = await loaded()
    act(() => result.current.edit('two'))
    act(() => result.current.notifyChanged('v5'))
    expect(result.current.changedElsewhere).toBe(true)
    expect(result.current.value).toBe('two')
    load.mockResolvedValue({ text: 'five', version: 'v5' })
    act(() => result.current.revert())
    await waitFor(() => expect(result.current.value).toBe('five'))
    expect(result.current.changedElsewhere).toBe(false)
  })

  it('a change event carrying the version already shown is ignored', async () => {
    const { result } = await loaded()
    act(() => result.current.notifyChanged('v1'))
    expect(load).toHaveBeenCalledTimes(1)
  })

  it('a change event on a clean document reloads it', async () => {
    const { result } = await loaded()
    load.mockResolvedValue({ text: 'two', version: 'v2' })
    act(() => result.current.notifyChanged('v2'))
    await waitFor(() => expect(result.current.value).toBe('two'))
  })

  it('a reconnect while editing checks the version without touching the draft', async () => {
    const { result } = await loaded()
    act(() => result.current.edit('mine'))
    load.mockResolvedValue({ text: 'other', version: 'v2' })
    act(() => result.current.notifyChanged())
    await waitFor(() => expect(result.current.changedElsewhere).toBe(true))
    expect(result.current.value).toBe('mine')
  })

  it('a 404 load is missing; another failure is a load error that a reconnect retries', async () => {
    load.mockRejectedValueOnce(new HttpError(404))
    const missing = setup()
    await waitFor(() => expect(missing.result.current.missing).toBe(true))
    expect(missing.result.current.loadError).toBeNull()
    missing.unmount()

    load.mockRejectedValueOnce(new TypeError('Failed to fetch'))
    const failed = setup()
    await waitFor(() => expect(failed.result.current.loadError).toBe('Failed to fetch'))
    expect(failed.result.current.missing).toBe(false)
    act(() => failed.result.current.notifyChanged())
    await waitFor(() => expect(failed.result.current.value).toBe('one'))
    expect(failed.result.current.loadError).toBeNull()
  })

  it('a save that finds the document gone keeps the draft; another failure is a save error', async () => {
    save.mockRejectedValueOnce(new HttpError(404)).mockRejectedValueOnce(new Error('disk full'))
    const { result } = await loaded()
    act(() => result.current.edit('two'))
    await act(() => result.current.save())
    expect(result.current.gone).toBe(true)
    expect(result.current.value).toBe('two')
    await act(() => result.current.save())
    expect(result.current.saveError).toBe('disk full')
  })

  it('honours a host isMissing', async () => {
    load.mockRejectedValueOnce(new Error('ENOENT'))
    const { result } = renderHook(() =>
      useVersionedDocument({ key: 'a', load, save, isMissing: (e) => String(e).includes('ENOENT') }),
    )
    await waitFor(() => expect(result.current.missing).toBe(true))
  })

  it('a new key drops the draft and loads the other document; a stale load is ignored', async () => {
    let finishA!: (d: VersionedText) => void
    load.mockReturnValueOnce(new Promise((r) => { finishA = r }))
    const hook = setup('a')
    load.mockResolvedValueOnce({ text: 'bee', version: 'b1' })
    hook.rerender({ key: 'b' })
    await waitFor(() => expect(hook.result.current.value).toBe('bee'))
    await act(async () => finishA({ text: 'ay', version: 'a1' }))
    expect(hook.result.current.value).toBe('bee')
  })
  it('a load that lands after the user started typing keeps the edits and flags the newer version', async () => {
    const { result } = await loaded()
    let finish!: (d: VersionedText) => void
    load.mockReturnValueOnce(new Promise((r) => { finish = r }))
    act(() => result.current.notifyChanged('v2'))
    act(() => result.current.edit('mine'))
    await act(async () => finish({ text: 'two', version: 'v2' }))
    expect(result.current.value).toBe('mine')
    expect(result.current.doc?.version).toBe('v1')
    expect(result.current.changedElsewhere).toBe(true)
  })

  it('a 404 that lands after the user started typing marks it gone and keeps the editor', async () => {
    const { result } = await loaded()
    let fail!: (e: unknown) => void
    load.mockReturnValueOnce(new Promise((_, r) => { fail = r }))
    act(() => result.current.notifyChanged(''))
    act(() => result.current.edit('mine'))
    await act(async () => fail(new HttpError(404)))
    expect(result.current.missing).toBe(false)
    expect(result.current.gone).toBe(true)
    expect(result.current.value).toBe('mine')
  })

  it('takeTheirs clears a stale save error and gone notice, and reloads for anything newer', async () => {
    save
      .mockRejectedValueOnce(new Error('Failed to fetch'))
      .mockRejectedValueOnce(new HttpError(404))
      .mockResolvedValueOnce({ ok: false, conflict: { text: 'theirs', version: 'v2' } })
    const { result } = await loaded()
    act(() => result.current.edit('mine'))
    await act(() => result.current.save())
    expect(result.current.saveError).toBe('Failed to fetch')
    await act(() => result.current.save())
    expect(result.current.gone).toBe(true)
    await act(() => result.current.save())
    load.mockResolvedValue({ text: 'newer', version: 'v3' })
    act(() => result.current.takeTheirs())
    expect(result.current.saveError).toBeNull()
    expect(result.current.gone).toBe(false)
    await waitFor(() => expect(result.current.value).toBe('newer'))
  })

  it('typing back to the stored text clears a save error', async () => {
    save.mockRejectedValueOnce(new Error('disk full'))
    const { result } = await loaded()
    act(() => result.current.edit('two'))
    await act(() => result.current.save())
    act(() => result.current.edit('one'))
    expect(result.current.saveError).toBeNull()
  })

  it('a document that 404s then comes back with the same bytes loads again', async () => {
    const { result } = await loaded()
    load.mockRejectedValueOnce(new HttpError(404))
    act(() => result.current.notifyChanged(''))
    await waitFor(() => expect(result.current.missing).toBe(true))
    act(() => result.current.notifyChanged('v1'))
    await waitFor(() => expect(result.current.missing).toBe(false))
    expect(result.current.value).toBe('one')
  })

  it('typing back to the stored text under a change notice takes the change', async () => {
    const { result } = await loaded()
    act(() => result.current.edit('two'))
    act(() => result.current.notifyChanged('v5'))
    load.mockResolvedValue({ text: 'five', version: 'v5' })
    act(() => result.current.edit('one'))
    await waitFor(() => expect(result.current.value).toBe('five'))
    expect(result.current.changedElsewhere).toBe(false)
  })

  it('a reconnect check that lands after a revert reloads rather than flagging a clean document', async () => {
    const { result } = await loaded()
    act(() => result.current.edit('mine'))
    let finish!: (d: VersionedText) => void
    load.mockReturnValueOnce(new Promise((r) => { finish = r }))
    act(() => result.current.notifyChanged())
    act(() => result.current.revert())
    load.mockResolvedValue({ text: 'two', version: 'v2' })
    await act(async () => finish({ text: 'two', version: 'v2' }))
    await waitFor(() => expect(result.current.value).toBe('two'))
    expect(result.current.changedElsewhere).toBe(false)
  })

  it("the change event for the hook's own save, before a re-render, is not a change elsewhere", async () => {
    save.mockResolvedValue({ ok: true, version: 'v2' })
    const { result } = await loaded()
    act(() => result.current.edit('two'))
    const notify = result.current.notifyChanged
    await act(async () => {
      await result.current.save()
      notify('v2')
    })
    expect(result.current.changedElsewhere).toBe(false)
    expect(load).toHaveBeenCalledTimes(1)
  })

  it('a revert during a save keeps the reverted text as unsaved, rather than adopting the saved one', async () => {
    let finish!: (r: VersionedSaveResult) => void
    save.mockReturnValueOnce(new Promise((r) => { finish = r }))
    const { result } = await loaded()
    act(() => result.current.edit('two'))
    let pending!: Promise<void>
    act(() => { pending = result.current.save() })
    act(() => result.current.revert())
    await act(async () => { finish({ ok: true, version: 'v2' }); await pending })
    expect(result.current.doc).toEqual({ text: 'two', version: 'v2' })
    expect(result.current.value).toBe('one')
    expect(result.current.dirty).toBe(true)
  })

  it('overwrite after a revert during the save still writes the editor text', async () => {
    let finish!: (r: VersionedSaveResult) => void
    save.mockReturnValueOnce(new Promise((r) => { finish = r })).mockResolvedValueOnce({ ok: true, version: 'v10' })
    const { result } = await loaded()
    act(() => result.current.edit('two'))
    let pending!: Promise<void>
    act(() => { pending = result.current.save() })
    act(() => result.current.revert())
    await act(async () => { finish({ ok: false, conflict: { text: 'theirs', version: 'v9' } }); await pending })
    await act(() => result.current.overwrite())
    expect(save).toHaveBeenLastCalledWith('one', 'v9')
  })

  it('a new key never renders the old document under it', async () => {
    const seen: (string | null)[] = []
    load.mockResolvedValueOnce({ text: 'ay', version: 'a1' })
    const hook = renderHook((props: { key: string }) => {
      const d = useVersionedDocument({ key: props.key, load, save })
      seen.push(`${props.key}:${d.value}`)
      return d
    }, { initialProps: { key: 'a' } })
    await waitFor(() => expect(hook.result.current.value).toBe('ay'))
    act(() => hook.result.current.edit('edited'))
    let finishB!: (d: VersionedText) => void
    load.mockReturnValueOnce(new Promise((r) => { finishB = r }))
    seen.length = 0
    hook.rerender({ key: 'b' })
    expect(seen.every((v) => !v?.startsWith('b:') || v === 'b:null')).toBe(true)
    expect(hook.result.current.dirty).toBe(false)
    await act(async () => finishB({ text: 'bee', version: 'b1' }))
    expect(hook.result.current.value).toBe('bee')
  })
})
