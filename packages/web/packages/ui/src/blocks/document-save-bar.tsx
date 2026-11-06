"use client"

import { Alert } from "../components/alert"
import { Button } from "../components/button"
import { ErrorText } from "../components/error-text"
import type { VersionedDocument } from "../hooks/useVersionedDocument"
import { ButtonBar } from "./button-bar"

export interface DocumentSaveBarMessages {
  /** A save found the document gone. */
  gone?: string
  /** The stored document changed while there was a draft. */
  changedElsewhere?: string
  /** A save lost the race to someone else's. */
  conflict?: string
}

export interface DocumentSaveBarProps {
  /** The document, from `useVersionedDocument`. */
  document: Pick<
    VersionedDocument,
    | "dirty"
    | "saving"
    | "gone"
    | "changedElsewhere"
    | "conflict"
    | "saveError"
    | "save"
    | "overwrite"
    | "revert"
    | "takeTheirs"
  >
  /** What the document is called in the notices ("file", "note"). Defaults to "document". */
  noun?: string
  /** Replace any notice's wording, e.g. "This file changed on disk." for a file-backed host. */
  messages?: DocumentSaveBarMessages
  className?: string
}

/**
 * The editing button bar for a `useVersionedDocument` document: the platform's standard
 * {@link ButtonBar} with Cancel and Save, so a document reads the same as every other editing
 * surface. Cancel drops the draft. Its notices sit at the bar's leading edge: the document
 * vanished, changed underneath the draft, or a save failed (shown here rather than in a
 * browser alert). When someone else saved first, a warning below the bar offers Reload theirs
 * or Overwrite.
 */
export function DocumentSaveBar({
  document: d,
  noun = "document",
  messages = {},
  className,
}: DocumentSaveBarProps) {
  const gone = messages.gone ?? `This ${noun} no longer exists.`
  const changed = messages.changedElsewhere ?? `This ${noun} changed since it was opened.`
  const conflict = messages.conflict ?? `Someone else saved this ${noun}.`
  return (
    <div data-slot="document-save-bar" className={className}>
      <ButtonBar
        showCreate={false}
        showDelete={false}
        leading={
          <div className="flex min-w-0 flex-wrap items-center gap-2">
            {d.gone && <ErrorText error={gone} />}
            {d.changedElsewhere && !d.conflict && <p className="text-sm text-apt-orange">{changed}</p>}
            <ErrorText error={d.saveError && `Save failed: ${d.saveError}`} />
          </div>
        }
        actions={{
          onCancel: d.revert,
          canCancel: d.dirty,
          onSave: () => void d.save(),
          canSave: d.dirty,
          saving: d.saving,
        }}
      />
      {d.conflict && (
        <Alert variant="warning" data-slot="document-save-conflict" className="mt-2 flex flex-wrap items-center gap-2 p-2">
          <span>{conflict}</span>
          <Button size="sm" variant="outline" onClick={d.takeTheirs}>Reload theirs</Button>
          <Button size="sm" variant="destructive" onClick={() => void d.overwrite()} disabled={d.saving}>Overwrite</Button>
        </Alert>
      )}
    </div>
  )
}
