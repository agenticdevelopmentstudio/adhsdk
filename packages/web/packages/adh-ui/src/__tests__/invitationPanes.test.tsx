import * as React from 'react'
import { render, screen, act, cleanup } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'

// Capture what the panes hand to their collaborators; the shared blocks are tested on their own.
const captured = vi.hoisted(() => ({
  list: null as any,
  send: null as any,
  add: null as any,
  sendMounts: 0,
}))

vi.mock('@adh-sdk/ui/blocks/list-with-details-pane', () => ({
  ListWithDetailsPane: (props: any) => {
    captured.list = props
    return <div data-testid="list-with-details" />
  },
}))

vi.mock('../blocks/send-invitation-modal', () => ({
  SendInvitationModal: (props: any) => {
    captured.send = props
    React.useEffect(() => {
      captured.sendMounts += 1
    }, [])
    return <div data-testid="send-modal" data-open={String(!!props.open)} />
  },
}))

vi.mock('@adh-sdk/ui/blocks/add-users-modal', () => ({
  AddUsersModal: (props: any) => {
    captured.add = props
    return <div data-testid="add-modal" data-open={String(!!props.open)} />
  },
}))

import {
  InvitationRequestsPane,
  InvitationPendingUsersPane,
  InvitationInvitesPane,
} from '../blocks/invitation-panes'

const request = { id: 'r1', userNumber: 1, name: 'R', phone: '', email: '', requestedDate: 'd', source: 'web', note: 'urgent' }
const pending = (over: Record<string, unknown> = {}) => ({
  id: 'u1', name: 'U', phone: '', email: 'a@x.io', invitedCount: 0, requestCount: 0,
  lastRequestDate: null, lastInviteSentDate: null, requestedDate: 'd', lastSource: 'referral', lastNote: 'thanks', ...over,
})
const invite = { id: 'i1', name: 'I', email: 'i@x.io', sentBy: 's', sentDate: 'd' }

let notes: ReturnType<typeof makeNotes>
function makeNotes() {
  const modal = vi.fn((s: any) => <div data-testid="notes-modal" data-open={String(s.open)} data-subject={s.subjectId} />)
  return {
    renderNotesAndHistory: vi.fn((s: any) => <div data-testid="notes-history">{`${s.subjectTable}:${s.subjectId}`}</div>),
    renderNotesModal: modal,
  }
}
const lastModalArgs = () => notes.renderNotesModal.mock.calls.at(-1)![0]

const requestsPane = (over: Record<string, unknown> = {}) => (
  <InvitationRequestsPane rows={[request]} onDelete={vi.fn()} {...notes} {...over} />
)
const pendingPane = (over: Record<string, unknown> = {}) => (
  <InvitationPendingUsersPane rows={[pending()]} onDelete={vi.fn()} onSend={vi.fn(() => Promise.resolve())} onAdd={vi.fn()} {...notes} {...over} />
)
const invitesPane = (over: Record<string, unknown> = {}) => (
  <InvitationInvitesPane rows={[invite]} onDelete={vi.fn()} {...notes} {...over} />
)

beforeEach(() => {
  captured.list = captured.send = captured.add = null
  captured.sendMounts = 0
  notes = makeNotes()
})
afterEach(cleanup)

const action = (id: string) => captured.list.actions.find((a: any) => a.id === id)

describe('invitation-panes', () => {
  it('invitation-panes-001 shows the loading placeholder on every pane', () => {
    for (const el of [requestsPane({ loading: true }), pendingPane({ loading: true }), invitesPane({ loading: true })]) {
      const { unmount } = render(el)
      expect(screen.getByText('Loading…')).toBeTruthy()
      expect(screen.queryByTestId('list-with-details')).toBeNull()
      unmount()
    }
  })

  it('invitation-panes-002 Requests pane delegates to the list layout', () => {
    render(requestsPane())
    expect(captured.list.columns.map((c: any) => c.header)).toEqual(['User #', 'Name', 'Phone', 'Email', 'Requested'])
    expect(captured.list.rows).toEqual([request])
    expect(captured.list.getRowId(request)).toBe('r1')
    expect(captured.list.emptyLabel).toBe('No invitation requests.')
    expect(captured.list.storageKey).toBe('adm-inv-requests')
    expect(captured.list.ariaLabel).toBe('Invitation requests')
  })

  it('invitation-panes-003 Pending Users pane delegates to the list layout', () => {
    render(pendingPane())
    expect(captured.list.columns.map((c: any) => c.header)).toEqual([
      'Name', 'Phone', 'Email', 'Invited', 'Requests', 'Last request', 'Last invite', 'Requested',
    ])
    expect(captured.list.emptyLabel).toBe('No pending users.')
    expect(captured.list.storageKey).toBe('adm-inv-pending')
  })

  it('invitation-panes-004 Invites pane delegates to the list layout', () => {
    render(invitesPane())
    expect(captured.list.columns.map((c: any) => c.header)).toEqual(['Name', 'Email', 'Sent by', 'Sent'])
    expect(captured.list.emptyLabel).toBe('No invites sent.')
    expect(captured.list.storageKey).toBe('adm-inv-invites')
  })

  it('invitation-panes-005 forwards the deep-linking param key', () => {
    for (const el of [requestsPane({ paramKey: 'sel' }), pendingPane({ paramKey: 'sel' }), invitesPane({ paramKey: 'sel' })]) {
      const { unmount } = render(el)
      expect(captured.list.paramKey).toBe('sel')
      unmount()
    }
  })

  it('invitation-panes-006 forwards the delete callback unchanged', () => {
    for (const make of [requestsPane, pendingPane, invitesPane]) {
      const onDelete = vi.fn()
      const { unmount } = render(make({ onDelete }))
      expect(captured.list.onDelete).toBe(onDelete)
      captured.list.onDelete(['a', 'b'])
      expect(onDelete).toHaveBeenCalledWith(['a', 'b'])
      unmount()
    }
  })

  it('invitation-panes-007 Admin notes action requires a selection', () => {
    for (const make of [requestsPane, pendingPane, invitesPane]) {
      const { unmount } = render(make())
      expect(action('notes').label).toBe('Admin notes')
      expect(action('notes').requiresSelection).toBe(true)
      unmount()
    }
  })

  it('invitation-panes-008 Admin notes targets the first selected id', () => {
    render(requestsPane({ rows: [request, { ...request, id: 'b' }] }))
    act(() => action('notes').onClick(['r1', 'b']))
    expect(lastModalArgs().subjectId).toBe('r1')
  })

  it('invitation-panes-009 Admin notes with no selection leaves the target unset', () => {
    render(requestsPane())
    act(() => action('notes').onClick(['r1']))
    expect(lastModalArgs().subjectId).toBe('r1')
    act(() => action('notes').onClick([]))
    expect(lastModalArgs().subjectId).toBe('')
    expect(lastModalArgs().open).toBe(false)
  })

  it('invitation-panes-010 notes modal opens for a row that is present', () => {
    render(requestsPane())
    act(() => action('notes').onClick(['r1']))
    expect(lastModalArgs().open).toBe(true)
    expect(screen.getByTestId('notes-modal').getAttribute('data-open')).toBe('true')
  })

  it('invitation-panes-011 notes modal closes when the row leaves the rows', () => {
    const { rerender } = render(requestsPane())
    act(() => action('notes').onClick(['r1']))
    expect(lastModalArgs().open).toBe(true)
    rerender(requestsPane({ rows: [] }))
    expect(lastModalArgs().open).toBe(false)
  })

  it('invitation-panes-012 closing the notes modal clears the target', () => {
    render(requestsPane())
    act(() => action('notes').onClick(['r1']))
    act(() => lastModalArgs().onClose())
    expect(lastModalArgs().open).toBe(false)
    expect(lastModalArgs().subjectId).toBe('')
  })

  it('invitation-panes-013 passes the required accessible names', () => {
    render(pendingPane())
    expect(captured.list.ariaLabel).toBe('Pending users')
    cleanup()
    render(requestsPane())
    expect(captured.list.ariaLabel).toBe('Invitation requests')
    cleanup()
    render(invitesPane())
    expect(captured.list.ariaLabel).toBe('Sent invites')
  })

  it('invitation-panes-014 Requests detail shows source and note above notes/history', () => {
    render(requestsPane())
    const { container } = render(<>{captured.list.renderDetail(request)}</>)
    expect(container.textContent).toContain('Source: web')
    expect(container.textContent).toContain('Note to the team: urgent')
    expect(container.textContent!.indexOf('Note to the team')).toBeLessThan(container.textContent!.indexOf('invitation_requests:r1'))
    expect(notes.renderNotesAndHistory).toHaveBeenCalledWith({ subjectTable: 'invitation_requests', subjectId: 'r1' })
  })

  it('invitation-panes-015 Invites detail is exactly the notes/history content', () => {
    render(invitesPane())
    const { container } = render(<>{captured.list.renderDetail(invite)}</>)
    expect(container.innerHTML).toBe('<div data-testid="notes-history">invitations:i1</div>')
    expect(container.textContent).not.toMatch(/Source:|Note/)
  })

  it('invitation-panes-016 Send invitation action requires a selection', () => {
    render(pendingPane())
    expect(action('send').label).toBe('Send invitation')
    expect(action('send').requiresSelection).toBe(true)
  })

  const twoRows = [
    pending({ id: 'u1', email: 'a@x.io', phone: '' }),
    pending({ id: 'u2', email: '', phone: '+15550100' }),
    pending({ id: 'u3', email: 'c@x.io', phone: '+15550111' }),
  ]

  it('invitation-panes-017 send seed is built only from the selected rows', () => {
    render(pendingPane({ rows: twoRows }))
    act(() => action('send').onClick(['u1', 'u2']))
    expect(captured.send.emails).toEqual(['a@x.io'])
    expect(captured.send.phones).toEqual(['+15550100'])
  })

  it('invitation-panes-018 send seed keeps only non-empty emails', () => {
    render(pendingPane({ rows: twoRows }))
    act(() => action('send').onClick(['u1', 'u2']))
    expect(captured.send.emails).toEqual(['a@x.io'])
  })

  it('invitation-panes-019 send seed keeps only non-empty phones', () => {
    render(pendingPane({ rows: twoRows }))
    act(() => action('send').onClick(['u1', 'u2']))
    expect(captured.send.phones).toEqual(['+15550100'])
  })

  it('invitation-panes-020 send seed carries the selected ids', async () => {
    const onSend = vi.fn(() => Promise.resolve())
    render(pendingPane({ rows: twoRows, onSend }))
    act(() => action('send').onClick(['u1', 'u2', 'ghost']))
    await act(async () => captured.send.onSend({ email: { recipients: ['a@x.io'], note: '' } }))
    expect(onSend).toHaveBeenCalledWith({ email: { recipients: ['a@x.io'], note: '' }, pendingUserIds: ['u1', 'u2', 'ghost'] })
  })

  it('invitation-panes-021 Send invitation opens the modal', () => {
    render(pendingPane({ rows: twoRows }))
    expect(screen.getByTestId('send-modal').getAttribute('data-open')).toBe('false')
    act(() => action('send').onClick(['u1']))
    expect(screen.getByTestId('send-modal').getAttribute('data-open')).toBe('true')
  })

  it('invitation-panes-022 send modal remounts when the seed changes', () => {
    render(pendingPane({ rows: twoRows }))
    expect(captured.sendMounts).toBe(1)
    act(() => action('send').onClick(['u1']))
    act(() => captured.send.onClose())
    const afterFirst = captured.sendMounts
    expect(afterFirst).toBe(2) // seed A differs from the initial empty seed
    act(() => action('send').onClick(['u3']))
    expect(captured.sendMounts).toBe(3) // seed B (different contacts) is a fresh instance
    expect(captured.send.emails).toEqual(['c@x.io'])
  })

  it('invitation-panes-023 send modal closes only when the send resolves', async () => {
    render(pendingPane({ rows: twoRows, onSend: vi.fn(() => Promise.resolve()) }))
    act(() => action('send').onClick(['u1']))
    expect(screen.getByTestId('send-modal').getAttribute('data-open')).toBe('true')
    await act(async () => captured.send.onSend({}))
    expect(screen.getByTestId('send-modal').getAttribute('data-open')).toBe('false')
  })

  it('invitation-panes-024 send modal stays open when the send rejects', async () => {
    render(pendingPane({ rows: twoRows, onSend: vi.fn(() => Promise.reject(new Error('boom'))) }))
    act(() => action('send').onClick(['u1']))
    await act(async () => {
      expect(() => captured.send.onSend({})).not.toThrow()
    })
    expect(screen.getByTestId('send-modal').getAttribute('data-open')).toBe('true')
  })

  it('invitation-panes-025 Add users action has a divider before it', () => {
    render(pendingPane())
    expect(action('add').label).toBe('Add users')
    expect(action('add').dividerBefore).toBe(true)
  })

  it('invitation-panes-026 Add users opens the add-users modal', () => {
    render(pendingPane())
    expect(screen.getByTestId('add-modal').getAttribute('data-open')).toBe('false')
    act(() => action('add').onClick())
    expect(screen.getByTestId('add-modal').getAttribute('data-open')).toBe('true')
  })

  it('invitation-panes-027 forwards onAdd to the add-users modal', () => {
    const onAdd = vi.fn()
    render(pendingPane({ onAdd }))
    expect(captured.add.onAdd).toBe(onAdd)
    const users = [{ name: 'n' }]
    captured.add.onAdd(users)
    expect(onAdd).toHaveBeenCalledWith(users)
  })

  it('invitation-panes-028 forwards sendBusy to the send modal', () => {
    render(pendingPane({ sendBusy: true }))
    expect(captured.send.busy).toBe(true)
  })

  it('invitation-panes-029 forwards addBusy to the add-users modal', () => {
    render(pendingPane({ addBusy: true }))
    expect(captured.add.busy).toBe(true)
  })

  it('invitation-panes-030 Requests delete-confirmation copy', () => {
    render(requestsPane())
    expect(captured.list.deleteConfirm).toEqual({ title: 'Delete requests?', description: 'This removes the selected invitation requests.' })
  })

  it('invitation-panes-031 Pending Users delete-confirmation copy', () => {
    render(pendingPane())
    expect(captured.list.deleteConfirm).toEqual({ title: 'Delete pending users?', description: 'This removes the selected pending users.' })
  })

  it('invitation-panes-032 Invites delete-confirmation copy', () => {
    render(invitesPane())
    expect(captured.list.deleteConfirm).toEqual({ title: 'Delete invites?', description: 'This removes the selected sent invites.' })
  })

  it('invitation-panes-033 Pending detail shows source and note above notes/history', () => {
    render(pendingPane())
    const { container } = render(<>{captured.list.renderDetail(pending())}</>)
    expect(container.textContent).toContain('Source: referral')
    expect(container.textContent).toContain('Note from user: thanks')
    expect(container.textContent!.indexOf('Note from user')).toBeLessThan(container.textContent!.indexOf('pending_users:u1'))
  })

  it('invitation-panes-034 Pending null dates render a dash', () => {
    render(pendingPane())
    const row = pending()
    const lastRequest = captured.list.columns.find((c: any) => c.header === 'Last request')
    const lastInvite = captured.list.columns.find((c: any) => c.header === 'Last invite')
    expect(lastRequest.render(row)).toBe('—')
    expect(lastInvite.render(row)).toBe('—')
    expect(lastRequest.render(pending({ lastRequestDate: '2026-01-02' }))).toBe('2026-01-02')
    expect(lastInvite.render(pending({ lastInviteSentDate: '2026-01-03' }))).toBe('2026-01-03')
  })
})
