'use client'

import { useCallback, useEffect, useRef, useState } from 'react'

/** A document's text at one stored version. */
export interface VersionedText {
  text: string
  version: string
}

/** What a save reports: the new version, or the version someone else stored first. */
export type VersionedSaveResult =
  | { ok: true; version: string }
  | { ok: false; conflict: VersionedText }

export interface VersionedDocumentSource {
  /**
   * Which document this is. When it changes, the hook drops the draft and every notice and
   * loads the new document from scratch.
   */
  key: string
  /** Fetch the stored text and its version. */
  load: () => Promise<VersionedText>
  /** Store `text` only if the stored version is still `baseVersion`; otherwise report theirs. */
  save: (text: string, baseVersion: string) => Promise<VersionedSaveResult>
  /**
   * Whether a load or save error means the document does not exist (rather than "could not
   * reach it"). Defaults to an error carrying `status === 404`.
   */
  isMissing?: (err: unknown) => boolean
}

export interface VersionedDocument {
  /** The stored text and version, once loaded. */
  doc: VersionedText | null
  /** What an editor shows: the draft while there is one, else the stored text. */
  value: string | null
  /** True while the draft differs from the stored text. */
  dirty: boolean
  /** `dirty` read at call time — stable identity, for exit guards that outlive a render. */
  isDirty: () => boolean
  /** The load said the document does not exist. */
  missing: boolean
  /** The load failed for another reason (network, 5xx); `notifyChanged()` retries it. */
  loadError: string | null
  /** A save said the document no longer exists. The draft is kept. */
  gone: boolean
  /** The stored document changed while there was a draft. The draft is kept. */
  changedElsewhere: boolean
  /** A save lost the race: someone else stored this version first. */
  conflict: VersionedText | null
  saving: boolean
  /** The last save failed for a reason other than a conflict or a missing document. */
  saveError: string | null
  /** Set the draft. Typing back to the stored text clears it, so that is not an unsaved edit. */
  edit: (text: string) => void
  /** Save the draft against the version it was loaded at. */
  save: () => Promise<void>
  /** After a conflict: save the draft over their version. */
  overwrite: () => Promise<void>
  /** Drop the draft (and reload, if the stored document changed meanwhile). */
  revert: () => void
  /** After a conflict: drop the draft and adopt their version. */
  takeTheirs: () => void
  /**
   * Tell the hook the stored document may have changed. With a `version` (a change event),
   * a matching version is ignored. Without one (a reconnect), the hook checks. Either way a
   * clean document reloads, and a document with a draft keeps it and sets `changedElsewhere`.
   */
  notifyChanged: (version?: string) => void
}

const statusIs404 = (err: unknown): boolean =>
  (err as { status?: unknown } | null)?.status === 404

const message = (err: unknown): string => (err instanceof Error ? err.message : String(err))

/**
 * One editable document stored with optimistic versioning: load it, keep a draft, save against
 * the version the draft started from, and say so — rather than clobber — when someone else got
 * there first or the document changed or vanished underneath the draft.
 *
 * The draft is `null` whenever it matches the stored text, so "there is a draft" always means
 * "there are unsaved edits". Every async result is dropped if the document (`key`) changed or
 * the component unmounted since it started, and loads within one document apply in order, so a
 * slow early load cannot overwrite a later one.
 *
 * Rendering is the host's: pair it with `DocumentSaveBar` for the Save/Revert strip and its
 * notices, and with `UnsavedChangesGuard` for leaving the page.
 */
export function useVersionedDocument(source: VersionedDocumentSource): VersionedDocument {
  const { key } = source
  const sourceRef = useRef(source)
  sourceRef.current = source

  const [doc, setDoc] = useState<VersionedText | null>(null)
  const [draft, setDraft] = useState<string | null>(null)
  const [missing, setMissing] = useState(false)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [gone, setGone] = useState(false)
  const [changedElsewhere, setChangedElsewhere] = useState(false)
  const [conflict, setConflict] = useState<VersionedText | null>(null)
  const [saving, setSaving] = useState(false)
  const [saveError, setSaveError] = useState<string | null>(null)

  const docRef = useRef(doc)
  docRef.current = doc
  const draftRef = useRef(draft)
  draftRef.current = draft
  const changedRef = useRef(changedElsewhere)
  changedRef.current = changedElsewhere

  // epoch moves with the document shown (key) and on unmount; loadSeq orders loads within one.
  const epoch = useRef(0)
  const loadSeq = useRef(0)

  const isMissing = useCallback(
    (err: unknown) => (sourceRef.current.isMissing ?? statusIs404)(err),
    [],
  )

  const load = useCallback(() => {
    const mineEpoch = epoch.current
    const mineSeq = ++loadSeq.current
    const current = () => mineEpoch === epoch.current && mineSeq === loadSeq.current
    sourceRef.current
      .load()
      .then((d) => {
        if (!current()) return
        setDoc(d)
        setMissing(false)
        setLoadError(null)
        setGone(false)
        setChangedElsewhere(false)
      })
      .catch((err: unknown) => {
        if (!current()) return
        if (isMissing(err)) {
          setMissing(true)
          setLoadError(null)
        } else {
          setMissing(false)
          setLoadError(message(err))
        }
      })
  }, [isMissing])

  useEffect(() => {
    epoch.current++
    setDoc(null)
    setDraft(null)
    setConflict(null)
    setChangedElsewhere(false)
    setSaving(false)
    setSaveError(null)
    setMissing(false)
    setLoadError(null)
    setGone(false)
    load()
    return () => {
      epoch.current++
    }
  }, [key, load])

  const isDirty = useCallback(
    () => draftRef.current !== null && draftRef.current !== docRef.current?.text,
    [],
  )

  const edit = useCallback((text: string) => {
    setDraft(text === docRef.current?.text ? null : text)
  }, [])

  const write = useCallback(
    async (base: string) => {
      const sent = draftRef.current
      if (sent === null) return
      const mineEpoch = epoch.current
      setSaving(true)
      setSaveError(null)
      try {
        const result = await sourceRef.current.save(sent, base)
        if (mineEpoch !== epoch.current) return
        if (result.ok) {
          setDoc({ text: sent, version: result.version })
          // Edits typed while the save was in flight stay a draft.
          setDraft((d) => (d === sent ? null : d))
          setConflict(null)
          setChangedElsewhere(false)
          setGone(false)
        } else {
          setConflict(result.conflict)
        }
      } catch (err) {
        if (mineEpoch !== epoch.current) return
        if (isMissing(err)) setGone(true)
        else setSaveError(message(err))
      } finally {
        if (mineEpoch === epoch.current) setSaving(false)
      }
    },
    [isMissing],
  )

  const save = useCallback(async () => {
    const base = docRef.current?.version
    if (base !== undefined) await write(base)
  }, [write])

  const conflictRef = useRef(conflict)
  conflictRef.current = conflict
  const overwrite = useCallback(async () => {
    const theirs = conflictRef.current
    if (theirs) await write(theirs.version)
  }, [write])

  const revert = useCallback(() => {
    const stale = changedRef.current
    setDraft(null)
    setConflict(null)
    setSaveError(null)
    if (stale) load()
  }, [load])

  const takeTheirs = useCallback(() => {
    const theirs = conflictRef.current
    if (!theirs) return
    setDoc(theirs)
    setDraft(null)
    setConflict(null)
    setChangedElsewhere(false)
  }, [])

  const notifyChanged = useCallback(
    (version?: string) => {
      if (version !== undefined && version === docRef.current?.version) return
      if (draftRef.current === null) {
        load()
        return
      }
      if (version !== undefined) {
        setChangedElsewhere(true)
        return
      }
      // Unknown whether anything changed (a reconnect): look, without touching the draft.
      const mineEpoch = epoch.current
      sourceRef.current
        .load()
        .then((d) => {
          if (mineEpoch === epoch.current && d.version !== docRef.current?.version) {
            setChangedElsewhere(true)
          }
        })
        .catch(() => {})
    },
    [load],
  )

  const dirty = draft !== null && draft !== doc?.text
  return {
    doc,
    value: draft ?? doc?.text ?? null,
    dirty,
    isDirty,
    missing,
    loadError,
    gone,
    changedElsewhere,
    conflict,
    saving,
    saveError,
    edit,
    save,
    overwrite,
    revert,
    takeTheirs,
    notifyChanged,
  }
}
