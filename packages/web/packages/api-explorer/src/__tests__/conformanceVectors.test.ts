import { describe, it, expect } from 'vitest'

import { methodBadgeClass, methodDotClass, methodTextClass } from '../lib/tone'
import { buildRequest } from '../lib/buildRequest'
import { endpointSlug } from '../lib/slug'
import type { EndpointMeta } from '../types'

const meta = (method: string, path: string): EndpointMeta => ({
  key: `${method} ${path}`,
  method,
  path,
  params: [],
  responses: [],
  family: [`${method} ${path}`],
})

describe('api-toolkit conformance vectors (api-explorer)', () => {
  it('vector 1: method text class equals the first token of the badge class for every method', () => {
    for (const method of ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'TRACE']) {
      expect(methodTextClass(method)).toBe(methodBadgeClass(method).split(' ')[0])
    }
  })

  it('vector 2: method dot class falls back to the neutral dot class for TRACE', () => {
    expect(methodDotClass('TRACE')).toBe('bg-apt-text-dim')
    expect(methodDotClass('GET')).toBe('bg-apt-green')
  })

  it('vector 9: slug projection of GET /users/{id} strips braces and appends the lower-cased method', () => {
    expect(endpointSlug(meta('GET', '/users/{id}'))).toEqual(['users', 'id', 'get'])
    expect(endpointSlug(meta('GET', '/users/{id}')).join('/')).toBe('users/id/get')
  })

  it('vector 10: buildRequest sends no Authorization header without a token and a Bearer header with one', () => {
    const endpoint = meta('GET', '/users/{id}')
    const values = { pathValues: { id: '7' }, queryValues: {} }
    expect(buildRequest(endpoint, values).headers).not.toHaveProperty('Authorization')
    expect(buildRequest(endpoint, values, null).headers).not.toHaveProperty('Authorization')
    const withToken = buildRequest(endpoint, values, 'tok-123')
    expect(withToken.headers['Authorization']).toBe('Bearer tok-123')
    expect(withToken.url).toBe('/api/users/7')
  })
})
