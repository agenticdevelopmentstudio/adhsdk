"use client"

import type { ReactNode } from "react"

import { Button } from "../components/button"
import type { VersionedDocument } from "../hooks/useVersionedDocument"

export interface DocumentSaveBarMessages {
  /** A save found the document gone. */
  gone?: ReactNode
  /** The stored document changed while there was a draft. */
  changedElsewhere?: ReactNode
  /** A save lost the race to someone else's. */
  conflict?: ReactNode
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
        {d.gone && <span className="text-sm text-destructive">{gone}</span>}
        {d.changedElsewhere && !d.conflict && <span className="text-sm text-amber-600">{changed}</span>}
        {d.saveError && <span role="alert" className="text-sm text-destructive">Save failed: {d.saveError}</span>}
      </div>
      {d.conflict && (
        <div data-slot="document-save-conflict" className="flex flex-wrap items-center gap-2 rounded border border-amber-500 p-2 text-sm">
          <span>{conflict}</span>
          <Button size="sm" variant="outline" onClick={d.takeTheirs}>Reload theirs</Button>
          <Button size="sm" variant="destructive" onClick={() => void d.overwrite()} disabled={d.saving}>Overwrite</Button>
        </div>
      )}
    </>
  )
}
