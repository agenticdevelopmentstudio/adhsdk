import { afterEach, describe, expect, it, vi } from 'vitest'
import { configureData } from '../config'
import { clearLastId, readLastId, readViewMode, writeLastId, writeViewMode } from '../ftd-storage'

afterEach(() => {
  localStorage.clear()
  // Restore the default so one test's override can't leak into the next.
  configureData({ storageKeyPrefix: 'adh' })
})

describe('ftd-storage key prefix', () => {
  it('defaults to the unchanged "adh:ftd:…" key shape', () => {
    writeLastId('/ecosystems', 'eco-1')
    expect(localStorage.getItem('adh:ftd:/ecosystems:lastId')).toBe('eco-1')
    writeViewMode('/ecosystems', 'list')
    expect(localStorage.getItem('adh:ftd:/ecosystems:viewMode')).toBe('list')
  })

  it('respects a configured storageKeyPrefix override', () => {
    configureData({ storageKeyPrefix: 'acme' })
    writeLastId('/teams', 'team-9')
    expect(localStorage.getItem('acme:ftd:/teams:lastId')).toBe('team-9')
    expect(localStorage.getItem('adh:ftd:/teams:lastId')).toBeNull()
    // The read side uses the same configured prefix, so it round-trips.
    expect(readLastId('/teams')).toBe('team-9')
  })
})

// Conformance vectors for resource-data (cookbook/data/services/resource-data). The workspace
// localStorage shim keeps getItem/setItem as its own properties, so failures are injected there.
const failing = (method: 'getItem' | 'setItem' | 'removeItem') =>
  vi.spyOn(window.localStorage, method).mockImplementation(() => {
    throw new Error('storage failed')
  })

describe('ftd-storage conformance', () => {
  afterEach(() => {
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
  })

  it('resource-data-011 writes the last id under "<prefix>:ftd:<collection>:lastId"', () => {
    configureData({ storageKeyPrefix: 'x' })
    writeLastId('projects', 'p-1')
    expect(localStorage.getItem('x:ftd:projects:lastId')).toBe('p-1')
  })

  it('resource-data-012 reads no last id when nothing is stored', () => {
    expect(readLastId('projects')).toBeNull()
  })

  it('resource-data-013 reading the last id swallows a storage failure', () => {
    failing('getItem')
    expect(readLastId('projects')).toBeNull()
  })

  it('resource-data-014 writing the last id swallows a storage failure', () => {
    failing('setItem')
    expect(() => writeLastId('projects', 'p-1')).not.toThrow()
  })

  it('resource-data-015 clearing the last id swallows a storage failure', () => {
    failing('removeItem')
    expect(() => clearLastId('projects')).not.toThrow()
  })

  it('resource-data-016 view mode is "cards" with no window', () => {
    localStorage.setItem('adh:ftd:projects:viewMode', 'list')
    vi.stubGlobal('window', undefined)
    expect(readViewMode('projects')).toBe('cards')
  })

  it('resource-data-017 view mode rejects an invalid stored value', () => {
    localStorage.setItem('adh:ftd:projects:viewMode', 'grid')
    expect(readViewMode('projects')).toBe('cards')
  })

  it('resource-data-018 view mode reads a valid stored value', () => {
    localStorage.setItem('adh:ftd:projects:viewMode', 'list')
    expect(readViewMode('projects')).toBe('list')
  })

  it('resource-data-019 writing the view mode swallows a storage failure', () => {
    failing('setItem')
    expect(() => writeViewMode('projects', 'list')).not.toThrow()
  })
})
