import { renderHook } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { decodeJwtClaims, tenantIdFromToken, useTenantId } from '../tenant'

// Build a fake JWT whose middle segment is the base64url-encoded claims — the
// real shape `tenantIdFromToken` (via `atob`) decodes. Browser-native `btoa`
// (no Node `Buffer`) keeps this package's tests platform-pure.
const base64url = (json: string) =>
  btoa(json).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
const claims = (obj: object) => `x.${base64url(JSON.stringify(obj))}.y`

describe('tenantIdFromToken', () => {
  it('reads ecosystem_id (the real adh backend claim) first', () => {
    expect(tenantIdFromToken(claims({ ecosystem_id: 'e1' }))).toBe('e1')
  })
  it('prefers ecosystem_id over the tenant_id / project_id fallbacks', () => {
    expect(
      tenantIdFromToken(claims({ ecosystem_id: 'e1', tenant_id: 't1', project_id: 'p1' })),
    ).toBe('e1')
  })
  it('falls back to tenant_id, then project_id, in order', () => {
    expect(tenantIdFromToken(claims({ tenant_id: 't1', project_id: 'p1' }))).toBe('t1')
    expect(tenantIdFromToken(claims({ project_id: 'p1' }))).toBe('p1')
  })
  /**
   * Real tokens carry more than ids. A `name` or an `email` with a non-ASCII character makes
   * the payload multi-byte, and the decode this used to do — `JSON.parse(atob(...))` — read
   * those bytes one code unit each: at best a corrupted neighbouring claim, at worst a throw
   * that this function reports as "no tenant". A tenant-less read scopes the react-query cache
   * globally, which is the one failure this claim exists to prevent.
   */
  it('reads the tenant out of a payload whose other claims are multi-byte', () => {
    const utf8 = (json: string) =>
      btoa(String.fromCharCode(...new TextEncoder().encode(json)))
        .replace(/\+/g, '-')
        .replace(/\//g, '_')
        .replace(/=+$/, '')
    const token = `x.${utf8(JSON.stringify({ ecosystem_id: 'e1', name: '東京 José' }))}.y`
    expect(tenantIdFromToken(token)).toBe('e1')
  })

  it('returns null when no tenant claim is present, or the token is absent/garbage', () => {
    expect(tenantIdFromToken(claims({ sub: 'user-1' }))).toBeNull()
    expect(tenantIdFromToken(null)).toBeNull()
    expect(tenantIdFromToken('garbage')).toBeNull()
  })
})

// Conformance vectors for resource-data (cookbook/data/services/resource-data).
describe('tenant conformance', () => {
  afterEach(() => {
    localStorage.clear()
    vi.restoreAllMocks()
  })

  it('resource-data-032 decodeJwtClaims is null for a token without three parts', () => {
    expect(decodeJwtClaims('not-a-jwt')).toBeNull()
  })

  it('resource-data-033 decodeJwtClaims returns the decoded claims of a well-formed token', () => {
    expect(decodeJwtClaims(claims({ ecosystem_id: 'e1', sub: 'u' }))).toEqual({
      ecosystem_id: 'e1',
      sub: 'u',
    })
  })

  it('resource-data-034 decodeJwtClaims is null when the middle part is not base64url JSON', () => {
    expect(decodeJwtClaims('x.!!!not-base64!!!.y')).toBeNull()
  })

  it('resource-data-035 ecosystem_id wins over tenant_id', () => {
    expect(tenantIdFromToken(claims({ ecosystem_id: 'e1', tenant_id: 't1' }))).toBe('e1')
  })

  it('resource-data-036 tenant_id wins over project_id', () => {
    expect(tenantIdFromToken(claims({ tenant_id: 't1', project_id: 'p1' }))).toBe('t1')
  })

  it('resource-data-037 no token gives no tenant', () => {
    expect(tenantIdFromToken(null)).toBeNull()
  })

  it('resource-data-038 useTenantId returns the same tenant on a re-render without re-decoding', () => {
    localStorage.setItem('auth_tokens', JSON.stringify({ accessToken: claims({ ecosystem_id: 'e1' }) }))
    const { result, rerender } = renderHook(() => useTenantId())
    expect(result.current).toBe('e1')
    const atobSpy = vi.spyOn(globalThis, 'atob')
    rerender()
    expect(result.current).toBe('e1')
    expect(atobSpy).not.toHaveBeenCalled()
  })
})
