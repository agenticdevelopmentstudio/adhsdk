import { describe, expect, it } from 'vitest'
import { parseColor, resolveColor } from './color.js'

describe('parseColor', () => {
  it('text-lens-001: reads six-digit hex', () => {
    expect(parseColor('#c4a35a')).toEqual([196, 163, 90])
  })

  it('text-lens-002: doubles the digits of short hex', () => {
    expect(parseColor('#e93')).toEqual([238, 153, 51])
  })

  it('text-lens-003: drops the alpha channel from hex', () => {
    expect(parseColor('#c4a35a80')).toEqual([196, 163, 90])
  })

  it('text-lens-004: drops the alpha digit from short hex', () => {
    expect(parseColor('#e93f')).toEqual([238, 153, 51])
  })

  it('text-lens-005: reads rgb() and rgba(), comma- or space-separated', () => {
    expect(parseColor('rgb(138, 138, 154)')).toEqual([138, 138, 154])
    expect(parseColor('rgb(138 138 154)')).toEqual([138, 138, 154])
    expect(parseColor('rgba(138, 138, 154, 0.5)')).toEqual([138, 138, 154])
  })

  it('text-lens-006: tolerates surrounding whitespace', () => {
    expect(parseColor('  #c4a35a\n')).toEqual([196, 163, 90])
  })

  it('text-lens-007: rejects anything it cannot read as three channels', () => {
    expect(parseColor('rebeccapurple')).toBeNull()
    expect(parseColor('hsl(40 50% 50%)')).toBeNull()
    expect(parseColor('#12345')).toBeNull()
    expect(parseColor('#gggggg')).toBeNull()
    expect(parseColor('')).toBeNull()
  })
})

describe('resolveColor', () => {
  it('text-lens-008: passes a literal colour straight through', () => {
    const el = document.createElement('div')
    expect(resolveColor('#c4a35a', el)).toEqual([196, 163, 90])
  })

  it('text-lens-009: reads a custom property off the element', () => {
    const el = document.createElement('div')
    el.style.setProperty('--accent', '#e8a33d')
    document.body.appendChild(el)
    try {
      expect(resolveColor('--accent', el)).toEqual([232, 163, 61])
    } finally {
      el.remove()
    }
  })

  it('text-lens-010: throws naming the property when it is not set', () => {
    const el = document.createElement('div')
    document.body.appendChild(el)
    try {
      expect(() => resolveColor('--missing', el)).toThrow(/"--missing"/)
    } finally {
      el.remove()
    }
  })

  it('text-lens-011: throws showing what an unreadable property resolved to', () => {
    const el = document.createElement('div')
    el.style.setProperty('--accent', 'rebeccapurple')
    document.body.appendChild(el)
    try {
      expect(() => resolveColor('--accent', el)).toThrow(/resolved to "rebeccapurple"/)
    } finally {
      el.remove()
    }
  })
})
