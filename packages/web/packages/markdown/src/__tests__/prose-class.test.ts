import { describe, it, expect } from 'vitest'
import { proseClassName } from '../lib/prose-class'

describe('proseClassName', () => {
  it('is the bare prose class by default (the reading column)', () => {
    expect(proseClassName()).toBe('adh-mv-prose')
    expect(proseClassName({ measure: 'reading' })).toBe('adh-mv-prose')
  })

  it('adds the fill modifier for measure="fill"', () => {
    expect(proseClassName({ measure: 'fill' })).toBe('adh-mv-prose adh-mv-prose--fill')
  })

  it('combines wrap, measure and extra classes in a stable order', () => {
    expect(proseClassName({ wrap: true, measure: 'fill', className: 'x y' })).toBe(
      'adh-mv-prose adh-mv-prose--wrap adh-mv-prose--fill x y',
    )
  })
})
