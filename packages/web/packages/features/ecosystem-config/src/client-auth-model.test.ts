import { describe, expect, it } from 'vitest'
import type { ClientAuthPolicy } from '@adh-sdk/data/ecosystem-config'
import {
  MAX_LOGIN_ALLOWED_CUSTOMERS,
  cleanCustomerList,
  policyError,
  policyPatch,
  samePolicy,
} from './client-auth-model'

const BASE: ClientAuthPolicy = {
  signupMode: 'invite_only',
  loginEnabled: true,
  passwordEnabled: true,
  allowedProviders: null,
  loginAllowedCustomerIds: null,
}
const ids = (loginAllowedCustomerIds: string[] | null): ClientAuthPolicy => ({ ...BASE, loginAllowedCustomerIds })

describe('the login allow-list in the client auth model', () => {
  it('ecosystem-config-031: cleans to what a save sends: trimmed, no blanks, no duplicates, null and [] kept apart', () => {
    expect(cleanCustomerList([' cus_a ', '', 'cus_b', 'cus_a'])).toEqual(['cus_a', 'cus_b'])
    expect(policyPatch(ids([' cus_a ', '', 'cus_b', 'cus_a']), BASE)).toEqual({ loginAllowedCustomerIds: ['cus_a', 'cus_b'] })
    expect(policyPatch(BASE, ids(['cus_a']))).toEqual({ loginAllowedCustomerIds: null })
    expect(policyPatch(ids([]), BASE)).toEqual({ loginAllowedCustomerIds: [] })
    // A blank row added to a saved list is not an edit.
    expect(policyPatch(ids(['cus_a', '']), ids(['cus_a']))).toBeUndefined()
    expect(cleanCustomerList([' a ', '', 'b', 'a', '  '])).toEqual(['a', 'b'])
    expect(cleanCustomerList([''])).toEqual([])
    expect(cleanCustomerList(null)).toBeNull()
  })

  it('compares as a set of cleaned ids', () => {
    expect(samePolicy(ids(['a', 'b']), ids(['b', 'a', '']))).toBe(true)
    expect(samePolicy(ids([]), ids(null))).toBe(false)
    expect(samePolicy(ids(['a']), ids(['a', 'b']))).toBe(false)
  })

  it('patches only a real change, and sends it cleaned', () => {
    expect(policyPatch(ids(['a', '']), ids(['a']))).toBeUndefined()
    expect(policyPatch(ids([' a ', 'a']), BASE)).toEqual({ loginAllowedCustomerIds: ['a'] })
    expect(policyPatch(BASE, ids(['a']))).toEqual({ loginAllowedCustomerIds: null })
    expect(policyPatch(ids(['']), BASE)).toEqual({ loginAllowedCustomerIds: [] })
  })

  it('ecosystem-config-032: refuses more ids than the backend takes, or an id too long to be one', () => {
    expect(policyError(BASE)).toBeNull()
    expect(policyError(null)).toBeNull()
    expect(policyError(ids([]))).toBeNull()
    const many = Array.from({ length: MAX_LOGIN_ALLOWED_CUSTOMERS + 1 }, (_, i) => `c${i}`)
    expect(policyError(ids(many))).toMatch(/At most 500/)
    expect(policyError(ids(many.slice(0, MAX_LOGIN_ALLOWED_CUSTOMERS)))).toBeNull()
    expect(policyError(ids(['x'.repeat(37)]))).toBe(`"${'x'.repeat(37)}" is not a customer id.`)
    expect(policyError(ids(many))).toBe('At most 500 customers can be listed.')
    expect(policyError(ids(['x'.repeat(37)]))).toMatch(/not a customer id/)
    expect(policyError(ids(['x'.repeat(36)]))).toBeNull()
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
