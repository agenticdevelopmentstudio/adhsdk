import { describe, it, expect } from 'vitest'
import { RESERVED_SLUGS } from '@adh-sdk/adh-registry'
import {
  isReservedProductSiteHandle,
  PRODUCT_SITE_HANDLE_WORDS,
  reservedProductSiteHandles,
  reservedWorkspaceSlugs,
} from '../reservedSlugs'

describe('reservedWorkspaceSlugs', () => {
  it('reserves the hub-data ecosystem names the server refuses', () => {
    // Mirrors HUB_DATA_ECOSYSTEM_SLUGS in the backend's lib/rdid.ts.
    const reserved = reservedWorkspaceSlugs()
    expect(reserved.has('personal')).toBe(true)
    expect(reserved.has('organization')).toBe(true)
  })

  it('reserves the product knobs that are hub routes: roles, sets, the sign-up list and the product site', () => {
    // `/<workspace>/product-site` is a hub route, so no workspace may take the word; `admin-site`,
    // the route it replaced, stays held back so a stale link resolves predictably.
    const reserved = reservedWorkspaceSlugs()
    for (const slug of ['roles', 'sets', 'signup-list', 'product-site', 'admin-site']) {
      expect(reserved.has(slug)).toBe(true)
    }
  })

  // jobs-013: `/<workspace>/jobs` (phase 9) is the hub's Jobs feature segment.
  it('reserves jobs', () => {
    expect(reservedWorkspaceSlugs().has('jobs')).toBe(true)
  })
})

describe('reserved product site handles', () => {
  // Decision 5 of the product-sites checklist: a handle is a DNS label beside the family's hosts.
  const decisionFive = [
    'admin',
    'api',
    'app',
    'auth',
    'help',
    'mail',
    'product-admin',
    'sdk',
    'staging',
    'status',
    'support',
    'testing',
    'www',
  ]

  it('lists the thirteen words of decision 5', () => {
    expect([...PRODUCT_SITE_HANDLE_WORDS].sort()).toEqual([...decisionFive].sort())
  })

  it('reserves each of the thirteen words', () => {
    for (const word of decisionFive) {
      expect(isReservedProductSiteHandle(word)).toBe(true)
      expect(reservedProductSiteHandles().has(word)).toBe(true)
    }
  })

  it('reserves every word any site reserves, as the server does', () => {
    expect(isReservedProductSiteHandle('privacy')).toBe(true)
    const handles = reservedProductSiteHandles()
    for (const slug of Object.values(RESERVED_SLUGS).flat()) {
      expect(handles.has(slug)).toBe(true)
    }
  })

  it('leaves a word only a workspace path segment collides with claimable', () => {
    // A route word, reserved for `/<workspace>` but not in any site's RESERVED_SLUGS: the
    // server accepts it as a handle, so the form must too.
    expect(reservedWorkspaceSlugs().has('research')).toBe(true)
    expect(isReservedProductSiteHandle('research')).toBe(false)
  })

  it('leaves an ordinary word claimable', () => {
    expect(isReservedProductSiteHandle('notes')).toBe(false)
  })

  it('ignores case and surrounding whitespace', () => {
    expect(isReservedProductSiteHandle('  WWW ')).toBe(true)
    expect(isReservedProductSiteHandle('Product-Admin')).toBe(true)
    expect(isReservedProductSiteHandle(' Notes ')).toBe(false)
  })
})
