import { describe, it, expect } from 'vitest'
import { countProgress, type ProgressItem, type ProgressPhase } from '../lib/progress-count'

const item = (status: ProgressItem['status']): ProgressItem => ({ text: status, status })

describe('countProgress (ui)', () => {
  it('T1: counts done over all items', () => {
    expect(countProgress([item('done'), item('todo'), item('in-progress')])).toEqual({
      done: 1,
      total: 3,
      percent: 33,
    })
  })

  it('T2: stopped items leave the total', () => {
    expect(countProgress([item('done'), item('stopped'), item('stopped')])).toEqual({
      done: 1,
      total: 1,
      percent: 100,
    })
  })

  it('T3: no items is 0 of 0, 0%', () => {
    expect(countProgress([])).toEqual({ done: 0, total: 0, percent: 0 })
  })

  it('T4: percent rounds down so 100 means everything is done', () => {
    const items = [...Array(199).fill(0).map(() => item('done')), item('todo')]
    expect(countProgress(items).percent).toBe(99)
  })

  it('T5: accepts phases and counts every phase', () => {
    const phases: ProgressPhase[] = [
      { title: 'a', items: [item('done'), item('todo')] },
      { title: 'b', items: [item('done'), item('stopped')] },
    ]
    expect(countProgress(phases)).toEqual({ done: 2, total: 3, percent: 66 })
  })

  it('T6: phases with no items count as zero', () => {
    expect(countProgress([{ title: 'a', items: [] }])).toEqual({ done: 0, total: 0, percent: 0 })
  })
})
