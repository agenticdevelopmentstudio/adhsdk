import { describe, it, expect } from 'vitest'
import { reservedWorkspaceSlugs } from '../reservedSlugs'

describe('reservedWorkspaceSlugs', () => {
  it('reserves the hub-data ecosystem names the server refuses', () => {
    // Mirrors HUB_DATA_ECOSYSTEM_SLUGS in the backend's lib/rdid.ts.
    const reserved = reservedWorkspaceSlugs()
    expect(reserved.has('personal')).toBe(true)
    expect(reserved.has('organization')).toBe(true)
  })
})
