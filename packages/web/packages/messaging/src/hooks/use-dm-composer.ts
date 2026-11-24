// The DM composer's state (messaging P5): the draft, the sending flag and the send error, kept
// per conversation. `DmThread` is mounted once and handed a new `chatId` when the user picks
// another conversation, so this state would otherwise carry over: a draft typed to Alice would
// sit in Bob's composer and Enter would send it to Bob, and a send to Alice settling after the
// switch would clear what the user had started typing to Bob.

import { useCallback, useEffect, useRef, useState } from 'react'

/** The message a failed send shows. The backend answers 403 when a block/dial now denies contact. */
export function sendErrorMessage(err: unknown): string {
  const forbidden =
    err && typeof err === 'object' && 'status' in err && (err as { status?: number }).status === 403
  if (forbidden) return "You can't message this person."
  return err instanceof Error ? err.message : 'Failed to send message.'
}

export interface DmComposer {
  draft: string
  setDraft: (draft: string) => void
  sending: boolean
  sendError: string | null
  /** Send the trimmed draft; a no-op when it is empty or a send is in flight. */
  submit: () => Promise<void>
}

export function useDmComposer(
  chatId: string | null,
  send: (body: string) => Promise<unknown>,
): DmComposer {
  const [draft, setDraft] = useState('')
  const [sending, setSending] = useState(false)
  const [sendError, setSendError] = useState<string | null>(null)

  // Reset during render rather than in an effect, so no frame shows the old chat's draft.
  const [shownChatId, setShownChatId] = useState(chatId)
  if (shownChatId !== chatId) {
    setShownChatId(chatId)
    setDraft('')
    setSending(false)
    setSendError(null)
  }

  // The conversation now on screen, read when a send settles to drop a late result.
  const currentChatId = useRef(chatId)
  useEffect(() => {
    currentChatId.current = chatId
  }, [chatId])

  const submit = useCallback(async () => {
    const text = draft.trim()
    if (!text || sending) return
    const sentTo = chatId
    const stillShown = () => currentChatId.current === sentTo
    setSending(true)
    setSendError(null)
    try {
      await send(text)
      if (stillShown()) setDraft('')
    } catch (err) {
      if (stillShown()) setSendError(sendErrorMessage(err))
    } finally {
      if (stillShown()) setSending(false)
    }
  }, [chatId, draft, sending, send])

  return { draft, setDraft, sending, sendError, submit }
}
