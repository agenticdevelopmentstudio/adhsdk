'use client'

import type { ReactNode } from 'react'

import {
  DocumentSaveBar,
  type DocumentSaveBarMessages,
  type DocumentSaveBarProps,
} from '@adh-sdk/ui/blocks/document-save-bar'

import { MarkdownDocumentEditor, type MarkdownDocumentEditorProps } from './MarkdownDocumentEditor'

export interface MarkdownDocumentPaneProps
  extends Omit<MarkdownDocumentEditorProps, 'value' | 'onChange' | 'readOnly'> {
  /** The document, from `useVersionedDocument`. Until its `value` loads the pane shows its body empty. */
  document: DocumentSaveBarProps['document'] & {
    value: string | null
    edit: (text: string) => void
  }
  /** Whether the document may be changed here. Read-only shows the same view, without the bar. */
  editable: boolean
  /** What the document is called in the bar's notices ("file", "note"). */
  noun?: string
  /** Replace any of the bar's notices. */
  messages?: DocumentSaveBarMessages
  /** The host's own content above the editor (its actions, a notice), inside the padded body. */
  children?: ReactNode
}

/**
 * A whole detail pane for one markdown document: the platform's Cancel/Save bar and, below
 * it, the document's Source / Preview view.
 *
 * The bar is the shared full-bleed `ButtonBar` strip, so it sits flush against the top and
 * sides of the pane, and only the body below it is padded. A host renders this as the pane's
 * content with no padding of its own; that is the whole point of the pane owning the layout,
 * so no host can wrap the bar in padding by mistake.
 *
 * The bar shows for an editable document. It also stays while a draft or a conflict is
 * pending after the document stops being editable, so Cancel and Reload theirs stay within
 * reach. A read-only document gets the same view with its source selectable but not editable.
 *
 * Every other prop is forwarded to `MarkdownDocumentEditor`.
 */
export function MarkdownDocumentPane({
  document: doc,
  editable,
  noun = 'document',
  messages,
  children,
  ...editor
}: MarkdownDocumentPaneProps): React.JSX.Element {
  const pending = doc.dirty || doc.conflict !== null
  return (
    <div data-slot="markdown-document-pane" className="flex h-full min-h-0 min-w-0 flex-col">
      {(editable || pending) && <DocumentSaveBar document={doc} noun={noun} messages={messages} />}
      <MarkdownDocumentPaneBody>
        {children}
        {doc.value !== null && (
          <MarkdownDocumentEditor {...editor} value={doc.value} onChange={doc.edit} readOnly={!editable} />
        )}
      </MarkdownDocumentPaneBody>
    </div>
  )
}

/**
 * The padded body of a {@link MarkdownDocumentPane}, for a host showing something in the
 * pane's place (loading, not found, an error) so it lines up with the loaded pane.
 */
export function MarkdownDocumentPaneBody({ children }: { children?: ReactNode }): React.JSX.Element {
  return (
    <div data-slot="markdown-document-pane-body" className="flex min-h-0 min-w-0 flex-1 flex-col gap-3 p-4">
      {children}
    </div>
  )
}
