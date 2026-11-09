import { describe, expect, it } from 'vitest'
import { adminInvitationEndpoints, ecosystemInvitationEndpoints } from '../lib/invitations-endpoints'
import { toAdminNote, toHistoryEntry, toInvite, toPendingUser, toRequest } from '../lib/invitations-types'

describe('invitation endpoints over /v1', () => {
  it('platform-admin surface is unscoped', () => {
    const e = adminInvitationEndpoints()
    expect(e.requests).toBe('/api/v1/invitation_requests')
    expect(e.requestItem('a b')).toBe('/api/v1/invitation_requests/a%20b')
    expect(e.adminNotes('pending_users', 'p1')).toBe('/api/v1/admin_notes?subject_table=pending_users&subject_id=p1')
    expect(e.entityHistory('invitations', 'i1')).toBe('/api/v1/entity_history?subject_table=invitations&subject_id=i1')
    expect(e.withEcosystem({ users: [] })).toEqual({ users: [] })
  })

  it('ecosystem surface scopes reads and deletes by query, writes by body', () => {
    const e = ecosystemInvitationEndpoints('rdid:1')
    expect(e.pendingUsers).toBe('/api/v1/pending_users?ecosystem=rdid%3A1')
    expect(e.invitationItem('i1')).toBe('/api/v1/invitations/i1?ecosystem=rdid%3A1')
    expect(e.adminNotes('t', 's')).toBe('/api/v1/admin_notes?subject_table=t&subject_id=s&ecosystem=rdid%3A1')
    expect(e.invitationsSend).toBe('/api/v1/invitations')
    expect(e.adminNotesPut).toBe('/api/v1/admin_notes')
    expect(e.withEcosystem({ notes: [] })).toEqual({ notes: [], ecosystem: 'rdid:1' })
  })
})

describe('wire row mappers', () => {
  it('maps snake_case rows to the stable view types', () => {
    expect(toRequest({ id: 'r', pending_user_id: null, name: 'N', email: null, phone: null, source: null, note: null, created: 1700000000, user_number: 3 }))
      .toEqual({ id: 'r', userNumber: 3, name: 'N', email: '', phone: '', requestedDate: '2023-11-14', source: '', note: '' })
    expect(toPendingUser({ id: 'p', user_number: 1, name: 'N', email: 'e', phone: null, invited_count: 2, request_count: 4, last_request_at: '2026-01-02T00:00:00Z', last_invite_sent_at: null, first_requested_at: '2026-01-01T00:00:00Z', last_source: 's', last_note: null, status: 'pending' }))
      .toEqual({ id: 'p', name: 'N', email: 'e', phone: '', invitedCount: 2, requestCount: 4, lastRequestDate: '2026-01-02', lastInviteSentDate: null, requestedDate: '2026-01-01', lastSource: 's', lastNote: null })
    expect(toInvite({ id: 'i', name: 'N', channel: 'email', destination: 'd@x', sent_by: 'u', sent_at: '2026-03-04T00:00:00Z', status: 'sent' }))
      .toEqual({ id: 'i', name: 'N', email: 'd@x', sentBy: 'u', sentDate: '2026-03-04' })
    expect(toAdminNote({ id: 'n', content: 'c', created_by: 'u', subject_table: 't', subject_id: 's', created: 1700000000, updated: 1700086400 }))
      .toEqual({ id: 'n', content: 'c', author: 'u', addedDate: '2023-11-14', modifiedDate: '2023-11-15', subjectTable: 't', subjectId: 's' })
    expect(toHistoryEntry({ id: 'h', actor_label: null, actor_id: null, action: 'a', created: 1700000000 }))
      .toEqual({ id: 'h', actor: 'system', action: 'a', timestamp: '2023-11-14' })
  })
})
