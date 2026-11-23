// @vitest-environment jsdom
import { renderHook, cleanup } from '@testing-library/react'
import { describe, it, expect, afterEach, vi } from 'vitest'

/**
 * The Support access section is in the rail only while the backend's consented-access switch
 * is on. The switch's one visible signal is `/v1/account/support/grants` answering 404, so the
 * rail hides the section on exactly that and on nothing else: a slow read or a 500 keeps it,
 * and the pane then says what failed.
 */

const { grants } = vi.hoisted(() => ({
  grants: { current: { data: undefined as unknown, error: null as unknown } },
}))

vi.mock('@adh-sdk/data/support', () => ({
  useSupportGrants: () => grants.current,
  isSupportOff: (e: unknown) =>
    typeof e === 'object' && e !== null && (e as { status?: number }).status === 404,
}))
vi.mock('@adh-sdk/support-access', () => ({ SupportAccessPane: () => null }))
vi.mock('next/navigation', () => ({ useRouter: () => ({ push: vi.fn() }) }))
vi.mock('@adh-sdk/account', () => ({
  SettingsLayout: () => null,
  AccountPanel: () => null,
  ArchivedPanel: () => null,
  ContactInfoPanel: () => null,
  NotificationsWorkspace: () => null,
  ProfilePanel: () => null,
  SecurityWorkspace: () => null,
  SubscriptionPanel: () => null,
}))
vi.mock('../AppearancePanel', () => ({ AppearancePanel: () => null }))
vi.mock('@adh-sdk/profile', () => ({
  UsagePanel: () => null,
  SocialLinksPanel: () => null,
  AddressesPanel: () => null,
}))
vi.mock('@adh-sdk/authentication', () => ({ TokensPanel: () => null }))
vi.mock('@adh-sdk/personas', () => ({ AssistantsPanel: () => null }))
vi.mock('@adh-sdk/api-explorer', () => ({ RecordApiButton: () => null }))

import { buildSettingsTopics, useSettingsTopics } from '../registry'

afterEach(() => {
  cleanup()
  grants.current = { data: undefined, error: null }
})

const ids = () => renderHook(() => useSettingsTopics()).result.current.map((t) => t.id)

describe('the Support access section', () => {
  it('is in the full list, labelled for the reader', () => {
    const topic = buildSettingsTopics().find((t) => t.id === 'support-access')
    expect(topic?.label).toBe('Support access')
    expect(topic?.href).toBe('/settings/support-access')
  })

  it('is shown when the account has grants', () => {
    grants.current = { data: [], error: null }
    expect(ids()).toContain('support-access')
  })

  it('is shown while the read is still in flight', () => {
    grants.current = { data: undefined, error: null }
    expect(ids()).toContain('support-access')
  })

  it('is hidden when the backend answers 404, which is the switch being off', () => {
    grants.current = { data: undefined, error: { status: 404 } }
    expect(ids()).not.toContain('support-access')
  })

  it('hides nothing else when it is hidden', () => {
    grants.current = { data: undefined, error: { status: 404 } }
    const all = buildSettingsTopics().map((t) => t.id).filter((id) => id !== 'support-access')
    expect(ids()).toEqual(all)
  })

  it('is kept on any other failure, so a broken network never hides it', () => {
    grants.current = { data: undefined, error: { status: 500 } }
    expect(ids()).toContain('support-access')
  })
})

describe('buildSettingsTopics', () => {
  it('leaves out exactly the sections it is told to hide', () => {
    const all = buildSettingsTopics().map((t) => t.id)
    const shown = buildSettingsTopics({ hidden: new Set(['usage', 'support-access']) }).map(
      (t) => t.id,
    )
    expect(shown).toEqual(all.filter((id) => id !== 'usage' && id !== 'support-access'))
  })
})
