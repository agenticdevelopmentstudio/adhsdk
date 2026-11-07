import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { ApiBrowser } from '../ApiBrowser'

describe('ApiBrowser highlight', () => {
  it('says so when none of the endpoints asked for is in the spec', () => {
    render(<ApiBrowser readOnly highlight={[{ path: '/no/such/route' }]} highlightLabel="This tutorial" />)
    expect(screen.getByTestId('api-highlight-missed').textContent).toMatch(/None of the endpoints/)
    expect(screen.queryByText('This tutorial')).toBeNull()
  })

  it('says nothing about a miss when nothing was asked for', () => {
    render(<ApiBrowser readOnly />)
    expect(screen.queryByTestId('api-highlight-missed')).toBeNull()
  })
})
