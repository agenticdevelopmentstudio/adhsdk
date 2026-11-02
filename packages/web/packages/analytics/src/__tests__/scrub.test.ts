import { describe, it, expect } from 'vitest'
import { scrubPath, scrubUrl } from '../scrub'

describe('scrubPath', () => {
  it('redacts UUID and long-numeric segments and strips query/hash', () => {
    expect(scrubPath('/api/persona/services/3f8b1c2d-1234-4abc-89de-0123456789ab')).toBe(
      '/api/persona/services/:id',
    )
    expect(scrubPath('/api/users/123456?token=secret#frag')).toBe('/api/users/:id')
    expect(scrubPath('https://api.example.com/api/auth/me?q=1')).toBe('/api/auth/me')
  })

  it('keeps low-cardinality segments (versions, short numbers up to 3 digits, words)', () => {
    expect(scrubPath('/api/v2/items/42')).toBe('/api/v2/items/42')
    expect(scrubPath('/api/items/123')).toBe('/api/items/123') // 3 digits: kept (threshold is 4)
  })

  it('redacts ids embedded inside a segment, not just whole segments', () => {
    expect(scrubPath('/api/users/user-123456/posts')).toBe('/api/users/user-:id/posts')
    expect(scrubPath('/api/order_3f8b1c2d-1234-4abc-89de-0123456789ab')).toBe('/api/order_:id')
  })

  it('never emits the "pathname" of a non-http(s) URL (data:/mailto:/blob:)', () => {
    expect(scrubPath('data:text/plain,secret')).toBe(':non-http')
    expect(scrubPath('mailto:jane@example.com')).toBe(':non-http')
  })
})

describe('scrubUrl', () => {
  it('keeps the origin and a redacted path, dropping query and hash', () => {
    expect(scrubUrl('https://hub.example.com/u/123456?token=secret#frag')).toBe(
      'https://hub.example.com/u/:id',
    )
  })

  it('scrubs a relative value as a bare path', () => {
    expect(scrubUrl('/u/123456?x=1')).toBe('/u/:id')
  })

  it('passes an absent value through', () => {
    expect(scrubUrl(undefined)).toBeUndefined()
    expect(scrubUrl('')).toBe('')
  })
})
