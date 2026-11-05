import type { Attachment } from '../contract/attachments/Attachment'
import type { ContentItem, PopoverData, ToolCallInfo } from '../types'

/**
 * Web-only display extras — link/image cards, a detail popover, a record of
 * the tool calls a reply made — carried through the contract as a single
 * inline attachment.
 *
 * The contract's message vocabulary is deliberately portable: text,
 * attachments, delivery status. `PopoverData` is not portable and never will
 * be — no Swift or Kotlin UI is going to render a `.pc-popover-toggle`. But
 * `ThreePaneChat` builds its entire topic pane out of `msg.popover`, and
 * `InlineChat` renders a popover per bubble, so these have to survive the trip
 * from a `ChatBackend` through the orchestrator to the bubble that draws them.
 *
 * They ride as one `Attachment` under a vendor media type rather than as
 * fields on `Message`, because that is the shape a platform which does not
 * recognise the identifier can ignore without knowing anything about it.
 * `AttachmentPresentation` is `'inline'` for the same reason: it is part of
 * the message, not a file hanging off it.
 *
 * Encoding the whole payload as JSON rather than mapping links onto
 * `AttachmentSource.remote` is deliberate. `remote` holds a parsed `URL`, and
 * a relative `src` — which `ImageContent` plainly permits — has no absolute
 * form until something supplies a base. Lossless beats semantically tidy for a
 * payload whose only reader is the bubble it came from.
 */
export const RICH_DISPLAY_MEDIA_TYPE = 'application/vnd.adhsdk.rich-display+json'

export interface RichDisplay {
  readonly content?: ContentItem[]
  readonly popover?: PopoverData
  /**
   * Tool calls as the web transcript displays them, frozen at commit time.
   *
   * This is NOT the command channel. `ChatViewModel.activeCommands` is where
   * running commands live, and it clears when the turn ends — deliberately,
   * so nothing stays pinned in the UI forever. That leaves no trace on the
   * committed message, which is right for the contract and wrong for a
   * transcript the user scrolls back through. A backend that wants the record
   * kept writes it here, as display, and the two channels stay separate.
   */
  readonly toolCalls?: ToolCallInfo[]
}

function isEmpty(display: RichDisplay): boolean {
  return (
    (display.content === undefined || display.content.length === 0) &&
    display.popover === undefined &&
    (display.toolCalls === undefined || display.toolCalls.length === 0)
  )
}

/**
 * Returns `null` for an empty payload rather than an attachment carrying
 * `{}` — an empty attachment list is how "no extras" is already spelled, and
 * two spellings of the same state is one more than the bubble should have to
 * check.
 */
export function encodeRichDisplay(display: RichDisplay, id: string): Attachment | null {
  if (isEmpty(display)) return null
  return {
    id,
    mediaType: { identifier: RICH_DISPLAY_MEDIA_TYPE },
    source: {
      kind: 'inline',
      data: new TextEncoder().encode(JSON.stringify(display)),
    },
    presentation: 'inline',
  }
}

export function decodeRichDisplay(attachments: ReadonlyArray<Attachment>): RichDisplay {
  for (const attachment of attachments) {
    if (attachment.mediaType.identifier !== RICH_DISPLAY_MEDIA_TYPE) continue
    if (attachment.source.kind !== 'inline') continue
    try {
      const parsed: unknown = JSON.parse(new TextDecoder().decode(attachment.source.data))
      // A hand-rolled attachment under our media type is the caller's bug, not
      // the transcript's. Drop it rather than let a malformed payload throw
      // inside a render pass and take the whole conversation down with it.
      if (typeof parsed !== 'object' || parsed === null) continue
      return parsed as RichDisplay
    } catch {
      continue
    }
  }
  return {}
}
