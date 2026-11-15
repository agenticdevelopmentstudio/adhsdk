// Conformance tests for resource-data's host-injectable config (config.ts). Vitest isolates
// modules per test file, so the first test sees the module's own initial state.
import { afterEach, describe, expect, it } from 'vitest'
import { configureData, dataConfig } from '../config'

afterEach(() => {
  configureData({ storageKeyPrefix: 'adh' })
})

describe('data config', () => {
  it('resource-data-009 defaults the storage-key prefix to "adh"', () => {
    expect(dataConfig().storageKeyPrefix).toBe('adh')
  })

  it('resource-data-010 configureData merges a new storage-key prefix', () => {
    configureData({ storageKeyPrefix: 'x' })
    expect(dataConfig().storageKeyPrefix).toBe('x')
  })
})
