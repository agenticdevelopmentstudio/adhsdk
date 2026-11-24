/** Conformance tests for NotesAndHistory — one test per vector in
 *  cookbook/adh/hub/admin/notes-and-history/conformance-test-vectors.md. */
/// <reference types="@testing-library/jest-dom/vitest" />
import * as React from 'react'
import { render, screen, within } from '@testing-library/react'
import { describe, it, expect, vi, afterEach } from 'vitest'

import { NotesAndHistory } from '../blocks/notes-and-history'
import type { AdminNote, HistoryEntry } from '../lib/invitations-types'

const note = (id: string, content: string, author: string, modifiedDate: string): AdminNote => ({
  id, content, author, addedDate: modifiedDate, modifiedDate, subjectTable: 't', subjectId: 's',
})
const entry = (id: string, actor: string, action: string, timestamp: string): HistoryEntry => ({
  id, actor, action, timestamp,
})

const noteA = note('1', 'First note', 'alice', '2026-01-02')
const noteB = note('2', 'Second note', 'bob', '2026-02-03')
const entryA = entry('1', 'alice', 'approved', '2026-01-02')
const entryB = entry('2', 'bob', 'rejected', '2026-02-03')

function sections(container: HTMLElement) {
  const [notesSec, historySec] = Array.from(container.querySelectorAll('section'))
  if (!notesSec || !historySec) throw new Error('expected a notes section and a history section')
  return { notesSec, historySec }
}

afterEach(() => vi.unstubAllGlobals())

describe('NotesAndHistory conformance', () => {
  it('notes-and-history-001: renders both headings as sibling sections in one container', () => {
    const { container } = render(<NotesAndHistory notes={[]} history={[]} notesLoading={false} historyLoading={false} />)
    expect(screen.getByRole('heading', { name: 'Admin notes' })).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'History' })).toBeInTheDocument()
    const { notesSec, historySec } = sections(container)
    expect(notesSec.parentElement).toBe(historySec.parentElement)
    expect(within(notesSec).getByText('Admin notes')).toBeInTheDocument()
    expect(within(historySec).getByText('History')).toBeInTheDocument()
  })

  it('notes-and-history-002: notes loading does not withhold loaded history', () => {
    const { container } = render(<NotesAndHistory notes={[]} history={[entryA]} notesLoading={true} historyLoading={false} />)
    const { notesSec, historySec } = sections(container)
    expect(within(notesSec).getByText('Loading…')).toBeInTheDocument()
    expect(within(historySec).queryByText('Loading…')).toBeNull()
    expect(within(historySec).getAllByRole('listitem')).toHaveLength(1)
  })

  it('notes-and-history-003: history loading does not withhold loaded notes', () => {
    const { container } = render(<NotesAndHistory notes={[noteA]} history={[]} notesLoading={false} historyLoading={true} />)
    const { notesSec, historySec } = sections(container)
    expect(within(historySec).getByText('Loading…')).toBeInTheDocument()
    expect(within(notesSec).queryByText('Loading…')).toBeNull()
    expect(within(notesSec).getAllByRole('listitem')).toHaveLength(1)
  })

  it('notes-and-history-004: empty notes show "No admin notes." and no list', () => {
    const { container } = render(<NotesAndHistory notes={[]} history={[entryA]} notesLoading={false} />)
    const { notesSec } = sections(container)
    expect(within(notesSec).getByText('No admin notes.')).toBeInTheDocument()
    expect(notesSec.querySelector('ul')).toBeNull()
  })

  it('notes-and-history-005: empty history shows "No history." and no list', () => {
    const { container } = render(<NotesAndHistory notes={[noteA]} history={[]} historyLoading={false} />)
    const { historySec } = sections(container)
    expect(within(historySec).getByText('No history.')).toBeInTheDocument()
    expect(historySec.querySelector('ul')).toBeNull()
  })

  it('notes-and-history-006: notes render in source order with content and "author · modifiedDate"', () => {
    const { container } = render(<NotesAndHistory notes={[noteA, noteB]} history={[]} notesLoading={false} />)
    const { notesSec } = sections(container)
    const items = within(notesSec).getAllByRole('listitem')
    expect(items).toHaveLength(2)
    expect(items[0]!.children[0]!.textContent).toBe('First note')
    expect(items[0]!.children[1]!.textContent).toBe('alice · 2026-01-02')
    expect(items[1]!.children[0]!.textContent).toBe('Second note')
    expect(items[1]!.children[1]!.textContent).toBe('bob · 2026-02-03')
  })

  it('notes-and-history-007: history renders in source order as "timestamp — actor action"', () => {
    const { container } = render(<NotesAndHistory notes={[]} history={[entryA, entryB]} historyLoading={false} />)
    const { historySec } = sections(container)
    const items = within(historySec).getAllByRole('listitem')
    expect(items).toHaveLength(2)
    expect(items[0]!.textContent).toBe('2026-01-02 — alice approved')
    expect(items[1]!.textContent).toBe('2026-02-03 — bob rejected')
  })

  it('notes-and-history-008: never touches network primitives on render or re-render', () => {
    const fetchStub = vi.fn(() => { throw new Error('fetch called') })
    const xhrStub = vi.fn(() => { throw new Error('XHR called') })
    vi.stubGlobal('fetch', fetchStub)
    vi.stubGlobal('XMLHttpRequest', xhrStub)
    const { rerender } = render(<NotesAndHistory notes={[noteA]} history={[entryA]} notesLoading={false} historyLoading={false} />)
    expect(() => rerender(<NotesAndHistory notes={[noteB]} history={[]} notesLoading={true} historyLoading={false} />)).not.toThrow()
    expect(fetchStub).not.toHaveBeenCalled()
    expect(xhrStub).not.toHaveBeenCalled()
  })

  it('notes-and-history-009: omitted loading flags default to false (empty messages, not Loading…)', () => {
    render(<NotesAndHistory notes={[]} history={[]} />)
    expect(screen.getByText('No admin notes.')).toBeInTheDocument()
    expect(screen.getByText('No history.')).toBeInTheDocument()
    expect(screen.queryByText('Loading…')).toBeNull()
  })
})
