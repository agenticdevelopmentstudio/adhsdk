'use client'

import { useCallback, useEffect, useRef, useState } from 'react'

import { errorMessage } from '../lib/errors'

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
  /** What the editor shows: the stored text plus any unsaved edits. */
  value: string | null
  /** True while the editor's text differs from the stored text. */
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
  /** Set the editor's text. Typing back to the stored text is not an unsaved edit. */
  edit: (text: string) => void
  /** Save the draft against the version it was loaded at. */
  save: () => Promise<void>
  /** After a conflict: save the draft over their version. */
  overwrite: () => Promise<void>
  /** Drop the draft (and reload, if the stored document changed or vanished meanwhile). */
  revert: () => void
  /** After a conflict: drop the draft, adopt their version, and reload in case of a newer one. */
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

interface State {
  /** Which document; a new key starts a fresh state, and `gen` with it. */
  key: string
  gen: number
  doc: VersionedText | null
  /** What the editor shows. Unsaved edits are exactly `text !== doc.text`. */
  text: string | null
  missing: boolean
  loadError: string | null
  gone: boolean
  changedElsewhere: boolean
  conflict: VersionedText | null
  saving: boolean
  saveError: string | null
}

let nextGen = 0
const fresh = (key: string): State => ({
  key,
  gen: ++nextGen,
  doc: null,
  text: null,
  missing: false,
  loadError: null,
  gone: false,
  changedElsewhere: false,
  conflict: null,
  saving: false,
  saveError: null,
})

const isDirtyState = (s: State): boolean => s.doc !== null && s.text !== null && s.text !== s.doc.text

/**
 * One editable document stored with optimistic versioning: load it, keep the editor's text,
 * save against the version that text started from, and say so — rather than clobber — when
 * someone else got there first or the document changed or vanished underneath unsaved edits.
 *
 * All state is one object, and every change goes through it synchronously, so callbacks fired
 * between renders (a change event right after a save) see what the hook already knows. A new
 * `key` resets it during render, so a different document never renders with the last one's
 * text. Every async result is dropped if the document changed or the component unmounted since
 * it started, and loads within one document apply in order, so a slow early load cannot
 * overwrite a later one.
 *
 * Rendering is the host's: pair it with `DocumentSaveBar` for the Cancel/Save button bar and its
 * notices, and with `UnsavedChangesGuard` for leaving the page.
 */
export function useVersionedDocument(source: VersionedDocumentSource): VersionedDocument {
  const { key } = source
  const sourceRef = useRef(source)
  sourceRef.current = source

  const [state, setState] = useState(() => fresh(key))
  const stateRef = useRef(state)
  let s = state
  if (s.key !== key) {
    // A different document: reset now, during render, rather than after a commit of the old one.
    s = fresh(key)
    stateRef.current = s
    setState(s)
  }

  const alive = useRef(true)
  const loadSeq = useRef(0)
  const update = useCallback((gen: number, change: (s: State) => Partial<State>) => {
    const cur = stateRef.current
    if (cur.gen !== gen || !alive.current) return
    const next = { ...cur, ...change(cur) }
    stateRef.current = next
    setState(next)
  }, [])

  const isMissing = useCallback(
    (err: unknown) => (sourceRef.current.isMissing ?? statusIs404)(err),
    [],
  )

  const load = useCallback(() => {
    const gen = stateRef.current.gen
    const seq = ++loadSeq.current
    const apply = (change: (s: State) => Partial<State>) =>
      seq === loadSeq.current && update(gen, change)
    sourceRef.current
      .load()
      .then((d) =>
        apply((cur) =>
          // Edits typed while the load was in flight keep their base; a newer stored version
          // is a change underneath them, so the next save conflicts instead of clobbering it.
          isDirtyState(cur)
            ? { changedElsewhere: cur.changedElsewhere || d.version !== cur.doc?.version }
            : { doc: d, text: d.text, missing: false, loadError: null, gone: false, changedElsewhere: false },
        ),
      )
      .catch((err: unknown) =>
        apply((cur) => {
          if (isDirtyState(cur)) return isMissing(err) ? { gone: true } : {}
          // Drop the old doc with it, so its version can't mask the document coming back.
          return isMissing(err)
            ? { missing: true, loadError: null, doc: null, text: null }
            : { missing: false, loadError: errorMessage(err) }
        }),
      )
  }, [isMissing, update])

  useEffect(() => {
    alive.current = true
    load()
    return () => {
      alive.current = false
    }
  }, [key, load])

  const isDirty = useCallback(() => isDirtyState(stateRef.current), [])

  const edit = useCallback(
    (text: string) => {
      const cur = stateRef.current
      update(cur.gen, (c) => ({ text, ...(c.doc && text === c.doc.text ? { saveError: null } : {}) }))
      // Back to the stored text under a change notice: clean now, so take the change.
      if (cur.changedElsewhere && cur.doc && text === cur.doc.text) load()
    },
    [load, update],
  )

  const write = useCallback(
    async (base: string) => {
      const start = stateRef.current
      const sent = start.text
      if (sent === null) return
      const gen = start.gen
      update(gen, () => ({ saving: true, saveError: null }))
      try {
        const result = await sourceRef.current.save(sent, base)
        // `text` is untouched: whatever the editor holds now (edits or a revert made during
        // the save) stays, and is unsaved exactly when it differs from what was stored.
        update(gen, () =>
          result.ok
            ? { doc: { text: sent, version: result.version }, conflict: null, changedElsewhere: false, gone: false }
            : { conflict: result.conflict },
        )
      } catch (err) {
        update(gen, () => (isMissing(err) ? { gone: true } : { saveError: errorMessage(err) }))
      } finally {
        update(gen, () => ({ saving: false }))
      }
    },
    [isMissing, update],
  )

  const save = useCallback(async () => {
    const cur = stateRef.current
    if (cur.doc && isDirtyState(cur)) await write(cur.doc.version)
  }, [write])

  const overwrite = useCallback(async () => {
    const theirs = stateRef.current.conflict
    if (theirs) await write(theirs.version)
  }, [write])

  const revert = useCallback(() => {
    const cur = stateRef.current
    update(cur.gen, (c) => ({ text: c.doc?.text ?? null, conflict: null, saveError: null }))
    if (cur.changedElsewhere || cur.gone) load()
  }, [load, update])

  const takeTheirs = useCallback(() => {
    const cur = stateRef.current
    const theirs = cur.conflict
    if (!theirs) return
    update(cur.gen, () => ({
      doc: theirs,
      text: theirs.text,
      conflict: null,
      changedElsewhere: false,
      gone: false,
      saveError: null,
    }))
    // Their snapshot is from the failed save; anything stored since then is newer still.
    load()
  }, [load, update])

  const notifyChanged = useCallback(
    (version?: string) => {
      const cur = stateRef.current
      if (version !== undefined && version === cur.doc?.version) return
      if (!isDirtyState(cur)) {
        load()
        return
      }
      if (version !== undefined) {
        update(cur.gen, () => ({ changedElsewhere: true }))
        return
      }
      // Unknown whether anything changed (a reconnect): look, without touching the edits.
      const gen = cur.gen
      sourceRef.current
        .load()
        .then((d) => {
          const now = stateRef.current
          if (now.gen !== gen || d.version === now.doc?.version) return
          if (isDirtyState(now)) update(gen, () => ({ changedElsewhere: true }))
          else load()
        })
        .catch(() => {})
    },
    [load, update],
  )

  return {
    doc: s.doc,
    value: s.text,
    dirty: isDirtyState(s),
    isDirty,
    missing: s.missing,
    loadError: s.loadError,
    gone: s.gone,
    changedElsewhere: s.changedElsewhere,
    conflict: s.conflict,
    saving: s.saving,
    saveError: s.saveError,
    edit,
    save,
    overwrite,
    revert,
    takeTheirs,
    notifyChanged,
  }
}
