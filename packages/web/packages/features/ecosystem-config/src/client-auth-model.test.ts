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
  it('cleans to what a save sends: trimmed, no blanks, no duplicates, null and [] kept apart', () => {
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

  it('refuses more ids than the backend takes, or an id too long to be one', () => {
    expect(policyError(BASE)).toBeNull()
    expect(policyError(null)).toBeNull()
    expect(policyError(ids([]))).toBeNull()
    const many = Array.from({ length: MAX_LOGIN_ALLOWED_CUSTOMERS + 1 }, (_, i) => `c${i}`)
    expect(policyError(ids(many))).toMatch(/At most 500/)
    expect(policyError(ids(many.slice(0, MAX_LOGIN_ALLOWED_CUSTOMERS)))).toBeNull()
    expect(policyError(ids(['x'.repeat(37)]))).toMatch(/not a customer id/)
    expect(policyError(ids(['x'.repeat(36)]))).toBeNull()
  })
})
