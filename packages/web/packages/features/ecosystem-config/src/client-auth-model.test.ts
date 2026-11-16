import { describe, expect, it } from 'vitest'
import type { ClientAuthPolicy } from '@adh-sdk/data/ecosystem-config'
import {
  MAX_LOGIN_ALLOWED_EMAILS,
  allowListDropped,
  cleanEmailList,
  policyError,
  policyPatch,
  samePolicy,
} from './client-auth-model'

const BASE: ClientAuthPolicy = {
  signupMode: 'invite_only',
  loginEnabled: true,
  passwordEnabled: true,
  allowedProviders: null,
  loginAllowedEmails: null,
}
const list = (loginAllowedEmails: string[] | null): ClientAuthPolicy => ({ ...BASE, loginAllowedEmails })

describe('the login allow-list in the client auth model', () => {
  it('ecosystem-config-031: cleans to what a save sends: trimmed, lowercased, no blanks, no duplicates, null and [] kept apart', () => {
    expect(cleanEmailList([' A@x.com ', '', 'b@x.com', 'a@X.com'])).toEqual(['a@x.com', 'b@x.com'])
    expect(policyPatch(list([' a@x.com ', '', 'b@x.com', 'A@x.com']), BASE)).toEqual({ loginAllowedEmails: ['a@x.com', 'b@x.com'] })
    expect(policyPatch(BASE, list(['a@x.com']))).toEqual({ loginAllowedEmails: null })
    expect(policyPatch(list([]), BASE)).toEqual({ loginAllowedEmails: [] })
    // A blank row added to a saved list is not an edit.
    expect(policyPatch(list(['a@x.com', '']), list(['a@x.com']))).toBeUndefined()
    expect(cleanEmailList([''])).toEqual([])
    expect(cleanEmailList(null)).toBeNull()
  })

  it('compares as a set of cleaned emails, case-insensitively', () => {
    expect(samePolicy(list(['a@x.com', 'b@x.com']), list(['B@x.com', 'a@x.com', '']))).toBe(true)
    expect(samePolicy(list([]), list(null))).toBe(false)
    expect(samePolicy(list(['a@x.com']), list(['a@x.com', 'b@x.com']))).toBe(false)
  })

  it('patches only a real change, and sends it cleaned', () => {
    expect(policyPatch(list(['A@x.com', '']), list(['a@x.com']))).toBeUndefined()
    expect(policyPatch(list([' a@x.com ', 'a@x.com']), BASE)).toEqual({ loginAllowedEmails: ['a@x.com'] })
    expect(policyPatch(list(['']), BASE)).toEqual({ loginAllowedEmails: [] })
  })

  it('ecosystem-config-032: refuses more emails than the backend takes, or an entry that is not an email address', () => {
    expect(policyError(BASE)).toBeNull()
    expect(policyError(null)).toBeNull()
    expect(policyError(list([]))).toBeNull()
    const many = Array.from({ length: MAX_LOGIN_ALLOWED_EMAILS + 1 }, (_, i) => `p${i}@example.com`)
    expect(policyError(list(many))).toBe('At most 500 people can be listed.')
    expect(policyError(list(many.slice(0, MAX_LOGIN_ALLOWED_EMAILS)))).toBeNull()
    for (const bad of ['alice', 'alice@', '@x.com', 'a@x', 'a b@x.com', 'a@@x.com', '"a"@x.com', 'a@x..com']) {
      expect(policyError(list([bad]))).toBe(`"${bad}" is not an email address.`)
    }
    // 254 characters is the limit; 255 is over it.
    const at254 = `${'a'.repeat(64)}@${'b'.repeat(185)}.com`
    expect(at254).toHaveLength(254)
    expect(policyError(list([at254]))).toBeNull()
    expect(policyError(list([`a${at254}`]))).toMatch(/is not an email address/)
    expect(policyError(list(['first.last+tag@sub.example.co.uk']))).toBeNull()
  })

  it('ecosystem-config-037: a list the backend did not keep is a drop; an absent list reads as everyone', () => {
    const { loginAllowedEmails: _absent, ...old } = BASE
    expect(allowListDropped({ loginAllowedEmails: ['a@x.com'] }, old)).toBe(true)
    expect(allowListDropped({ loginAllowedEmails: [] }, old)).toBe(true)
    expect(allowListDropped({ loginAllowedEmails: null }, old)).toBe(false)
    expect(allowListDropped({ loginAllowedEmails: ['a@x.com'] }, list(['A@x.com']))).toBe(false)
    expect(allowListDropped({ signupMode: 'closed' }, old)).toBe(false)
  })
})

// Vectors 001-020 describe the Apple topics (`EcosystemConfigTopicsTests.swift` covers them); the web
// client has no counterpart for them. 022 names a web sign-in-app create client that does not exist:
// the web `clientAuthApi` only reads and updates registrations.
describe('Apple-only vectors', () => {
  it.skip('ecosystem-config-001: Apple-only, the user-auth topic detail is the Swift AuthSettings topic (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-002: Apple-only, the user-auth save is the Swift AuthSettings topic (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-003: Apple-only, path-depth dispatch is a Swift topic property (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-004: Apple-only, sign-in app list sorting is the Swift SigninAppsTopic (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-005: Apple-only, origin validation is the Swift SigninAppsTopic (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-006: Apple-only, origin canonicalization is the Swift SigninAppsTopic (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-007: Apple-only, sign-in app create validation is the Swift SigninAppsTopic (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-008: Apple-only, sign-in app create conflict mapping is the Swift SigninAppsTopic (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-009: Apple-only, sign-in app detail save is the Swift SigninAppsTopic (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-010: Apple-only, sign-in app delete confirmation is the Swift SigninAppsTopic (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-011: Apple-only, flag list sort and sublabel are the Swift FeatureFlagsTopic (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-012: Apple-only, flag duplicate-key check is the Swift FeatureFlagsTopic (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-013: Apple-only, flag delete confirmation is the Swift FeatureFlagsTopic (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-014: Apple-only, bag list preview is the Swift ServerBagsTopic (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-015: Apple-only, bag JSON-before-duplicate ordering is the Swift ServerBagsTopic (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-016: Apple-only, bag detail save and delete confirmation are the Swift ServerBagsTopic (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-017: Apple-only, token reveal-once is the Swift StorageTokensRail (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-018: Apple-only, token create three-way catch is the Swift StorageTokensRail (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-019: Apple-only, token revoke is the Swift StorageTokensRail (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-020: Apple-only, the shared token rail parameterization is the Swift StorageTokensRail (covered by EcosystemConfigTopicsTests.swift)', () => {})
  it.skip('ecosystem-config-022: no web sign-in-app create client exists; the web clientAuthApi has no create operation', () => {})
})
