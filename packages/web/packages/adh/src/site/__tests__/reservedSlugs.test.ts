import { describe, it, expect } from 'vitest'
import { reservedWorkspaceSlugs } from '../reservedSlugs'

describe('reservedWorkspaceSlugs', () => {
  it('reserves the hub-data ecosystem names the server refuses', () => {
    // Mirrors HUB_DATA_ECOSYSTEM_SLUGS in the backend's lib/rdid.ts.
    const reserved = reservedWorkspaceSlugs()
    expect(reserved.has('personal')).toBe(true)
    expect(reserved.has('organization')).toBe(true)
  })

  it('reserves the product knobs that are hub routes: roles, sets, the sign-up list and the admin site', () => {
    // `/<workspace>/admin-site` (phase 6) is a hub route, so no workspace may take the word.
    const reserved = reservedWorkspaceSlugs()
    for (const slug of ['roles', 'sets', 'signup-list', 'admin-site']) {
      expect(reserved.has(slug)).toBe(true)
    }
  })
})
