// @vitest-environment jsdom
import { renderHook, act, cleanup } from '@testing-library/react'
import { afterEach, describe, expect, it } from 'vitest'
import { useTokenSubject } from '../use-token-subject'
import { clearTokens, writeTokens } from '../tokens'
import type { AuthTokens } from '../types'

const base64url = (json: string) =>
  btoa(json).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
const tokensFor = (sub: string) =>
  ({ accessToken: `x.${base64url(JSON.stringify({ sub }))}.y` }) as unknown as AuthTokens

afterEach(() => {
  cleanup()
  localStorage.clear()
})

describe('useTokenSubject', () => {
  it('is null signed out', () => {
    const { result } = renderHook(() => useTokenSubject())
    expect(result.current).toBeNull()
  })

  it('follows sign-in and sign-out in this tab', () => {
    const { result } = renderHook(() => useTokenSubject())
    act(() => writeTokens(tokensFor('user-1')))
    expect(result.current).toBe('user-1')
    act(() => clearTokens())
    expect(result.current).toBeNull()
  })

  it('follows a sign-in written by another tab (the storage event)', () => {
    const { result } = renderHook(() => useTokenSubject())
    act(() => {
      // Write the storage directly, as another tab would, so no session listener fires here.
      localStorage.setItem('auth_tokens', JSON.stringify(tokensFor('user-2')))
      window.dispatchEvent(new StorageEvent('storage', { key: 'auth_tokens' }))
    })
    expect(result.current).toBe('user-2')
  })
})
