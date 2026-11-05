"use client"

import { Alert } from "../components/alert"
import { Button } from "../components/button"
import { ErrorText } from "../components/error-text"
import type { VersionedDocument } from "../hooks/useVersionedDocument"

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
}

/**
 * The Save/Revert strip for a `useVersionedDocument` document, with its notices: the document
 * vanished, changed underneath the draft, or someone else saved first (Reload theirs /
 * Overwrite). A failed save is shown here too, rather than in a browser alert.
 */
export function DocumentSaveBar({ document: d, noun = "document", messages = {} }: DocumentSaveBarProps) {
  const gone = messages.gone ?? `This ${noun} no longer exists.`
  const changed = messages.changedElsewhere ?? `This ${noun} changed since it was opened.`
  const conflict = messages.conflict ?? `Someone else saved this ${noun}.`
  return (
    <>
      <div data-slot="document-save-bar" className="flex flex-wrap items-center gap-2">
        <Button size="sm" onClick={() => void d.save()} disabled={d.saving || !d.dirty}>Save</Button>
        <Button size="sm" variant="outline" onClick={d.revert} disabled={!d.dirty}>Revert</Button>
        {d.gone && <ErrorText error={gone} />}
        {d.changedElsewhere && !d.conflict && <p className="text-sm text-apt-orange">{changed}</p>}
        <ErrorText error={d.saveError && `Save failed: ${d.saveError}`} />
      </div>
      {d.conflict && (
        <Alert variant="warning" data-slot="document-save-conflict" className="flex flex-wrap items-center gap-2 p-2">
          <span>{conflict}</span>
          <Button size="sm" variant="outline" onClick={d.takeTheirs}>Reload theirs</Button>
          <Button size="sm" variant="destructive" onClick={() => void d.overwrite()} disabled={d.saving}>Overwrite</Button>
        </Alert>
      )}
    </>
  )
}
