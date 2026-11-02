'use client'

import {
  useCallback,
  useRef,
  useState,
  type CSSProperties,
  type KeyboardEvent,
  type MouseEvent,
  type ReactElement,
} from 'react'
import {
  CHAT_INSIDE_ATTR,
  submitChatInput,
  type ChatBackend,
  type GazeVector,
} from '@agenticdevelopertoolkit/chat'
import type { ThemeKey } from '@agenticdevelopertoolkit/themes'
import { BitbagChat } from './BitbagChat'
import { BitbagInfo } from './BitbagInfo'
import { Bitbag, type BitbagExpression, type BitbagHandle } from './avatar'
import { DEFAULT_THEME, type BitbagVoice } from './voice'

/** His size on the chat's corner, as a share of `size` — the same proportion the
 *  open avatar-rest dock uses (BitbagDock's CORNER_SCALE), so the two read as one. */
const CORNER_SCALE = 0.75

/** The engaged signal is pinned: an in-page chat never folds (see below). */
const ALWAYS_ENGAGED = true
const ignoreFold = (): void => {}

export interface BitbagInlineProps {
  /** The toolkit theme that skins his chat. Defaults to the adh house style. */
  theme?: ThemeKey
  /** The chat backend driving his conversation. Defaults to his scripted mock. */
  backend?: ChatBackend
  /** Pixel width of bitbag at full size; he sits on the corner at 3/4 of it. */
  size?: number
  /** Extra classes on the root — the host's sizing and spacing. */
  className?: string
  /** What he says on this host (see `BitbagVoice`). Default: his own voice. */
  voice?: BitbagVoice
}

/**
 * bitbag IN THE PAGE: the open avatar-rest dock (his chat, his face on its
 * lower-right corner as the send button, his `i` on its top-left), laid out in
 * flow instead of fixed to the viewport's corner.
 *
 * For a page whose main area IS the conversation — the help landing — where the
 * dock's fixture behaviour is wrong in every particular: there is no rest to fold
 * back to (the chat is the page's content, so it stays open), no scrim (nothing to
 * dim it over), no page scroll lock and no keyboard ride (it is in the document, so
 * the page scrolls it into view like any input). What it keeps from the dock is
 * everything that makes him HIM — the same `BitbagChat` in its `dock` variant, so
 * he arrives connected ("connection established…") and greets, the same mood,
 * gaze and utterance wiring, and the same corner-send gesture with its giggle.
 *
 * Its own `.bb-inline` root, NOT a `.bb-dock` modifier: every dock rule (fixed
 * position, scrim, doze scale) is keyed on `.bb-dock`, and this must inherit none
 * of them. A host that mounts this should not also mount the dock on the same page.
 */
export function BitbagInline({
  theme = DEFAULT_THEME,
  backend,
  size = 112,
  className,
  voice,
}: BitbagInlineProps): ReactElement {
  const [chatHint, setChatHint] = useState<BitbagExpression | null>(null)
  const [gaze, setGaze] = useState<GazeVector | null>(null)
  const [utterance, setUtterance] = useState<{ text: string; id: number } | null>(null)
  const [mute, setMute] = useState(false)
  const bitbagRef = useRef<HTMLDivElement>(null)
  const panelRef = useRef<HTMLDivElement>(null)
  const face = useRef<BitbagHandle>(null)
  const utterId = useRef(0)

  const onHint = useCallback((hint: BitbagExpression | null) => setChatHint(hint), [])
  const onGaze = useCallback((g: GazeVector | null) => setGaze(g), [])
  const onMute = useCallback((m: boolean) => setMute(m), [])
  const onSpeak = useCallback((text: string) => {
    utterId.current += 1
    setUtterance({ text, id: utterId.current })
  }, [])

  // He is the send button: a tap sends what is in the composer, and pokes him.
  const send = (): void => {
    face.current?.poke()
    submitChatInput(panelRef.current)
  }
  const onAvatarKey = (e: KeyboardEvent<HTMLDivElement>): void => {
    if (e.key !== 'Enter' && e.key !== ' ') return
    e.preventDefault()
    send()
  }
  // A send button keeps focus in the composer; so does he — otherwise the caret
  // leaves the box on every send and a phone keyboard drops.
  const keepComposerFocus = (e: MouseEvent<HTMLDivElement>): void => {
    e.preventDefault()
  }

  const cornerWidth = Math.round(size * CORNER_SCALE)
  const rootClass = ['bb-inline', className].filter(Boolean).join(' ')

  return (
    <div
      ref={panelRef}
      className={rootClass}
      style={{ '--bb-inline-corner-w': `${cornerWidth}px` } as CSSProperties}
    >
      <BitbagChat
        className="bb-inline__chat"
        variant="dock"
        theme={theme}
        backend={backend}
        voice={voice}
        anchorRef={bitbagRef}
        onExpressionHint={onHint}
        onGazeHint={onGaze}
        utterance={utterance}
        onMute={onMute}
        // Pinned open: the dock variant folds an idle chat to its entry line, which
        // on a page whose content IS the chat would collapse the page.
        engaged={ALWAYS_ENGAGED}
        onEngagedChange={ignoreFold}
        sendButton={false}
      />
      <div
        ref={bitbagRef}
        className="bb-inline__avatar"
        style={{ width: cornerWidth }}
        role="button"
        tabIndex={0}
        aria-label="Send to bitbag"
        {...{ [CHAT_INSIDE_ATTR]: '' }}
        onClick={send}
        onKeyDown={onAvatarKey}
        onMouseDown={keepComposerFocus}
      >
        <Bitbag
          expression={chatHint ?? undefined}
          gaze={gaze}
          onSpeak={onSpeak}
          mute={mute}
          pokeOnClick={false}
          handleRef={face}
        />
      </div>
      <BitbagInfo />
    </div>
  )
}
