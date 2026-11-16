import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { TimeSeriesChart, type TimeSeriesPoint } from '../components/time-series-chart'

// jsdom lays nothing out, so ResponsiveContainer measures 0×0 and draws no chart.
// Give the container a real box so the plot renders — and the legend a one-line one,
// since recharts subtracts the legend's measured height from the plot's.
function box(width: number, height: number): DOMRect {
  return { width, height, top: 0, left: 0, right: width, bottom: height, x: 0, y: 0, toJSON: () => ({}) } as DOMRect
}

beforeEach(() => {
  vi.spyOn(HTMLElement.prototype, 'getBoundingClientRect').mockImplementation(function (this: HTMLElement) {
    return this.classList.contains('recharts-legend-wrapper') ? box(600, 20) : box(600, 240)
  })
  vi.spyOn(HTMLElement.prototype, 'clientWidth', 'get').mockReturnValue(600)
  vi.spyOn(HTMLElement.prototype, 'clientHeight', 'get').mockReturnValue(240)
  vi.spyOn(HTMLElement.prototype, 'offsetWidth', 'get').mockReturnValue(600)
  vi.spyOn(HTMLElement.prototype, 'offsetHeight', 'get').mockReturnValue(240)
})

afterEach(() => {
  vi.restoreAllMocks()
})

const points: TimeSeriesPoint[] = [
  { x: '2026-09-01', direct: 1_000_000, fixed: 500_000 },
  { x: '2026-09-02', direct: null, fixed: 500_000 },
  { x: '2026-09-03', direct: 3_000_000, fixed: 500_000 },
]

// Recharts draws its lines a commit after the first render (once the legend has been
// measured), so read them after that settles.
async function linePaths(container: HTMLElement, expected: number) {
  await waitFor(() => expect(container.querySelectorAll('path.recharts-line-curve')).toHaveLength(expected))
  return [...container.querySelectorAll('path.recharts-line-curve')]
}

describe('TimeSeriesChart', () => {
  it('T1: draws one line per series with a legend naming each', async () => {
    const { container } = render(
      <TimeSeriesChart
        points={points}
        series={[
          { key: 'direct', label: 'Direct' },
          { key: 'fixed', label: 'Fixed' },
        ]}
      />,
    )
    await linePaths(container, 2)
    expect(screen.getByText('Direct')).toBeInTheDocument()
    expect(screen.getByText('Fixed')).toBeInTheDocument()
  })

  it('T2: colours series by position in the fixed order', async () => {
    const { container } = render(
      <TimeSeriesChart
        points={points}
        series={[
          { key: 'direct', label: 'Direct' },
          { key: 'fixed', label: 'Fixed' },
        ]}
      />,
    )
    const strokes = (await linePaths(container, 2)).map((p) => p.getAttribute('stroke'))
    expect(strokes).toEqual([
      'var(--color-apt-cat-blue, #2f80ff)',
      'var(--color-apt-cat-orange, #f6821f)',
    ])
  })

  it('T3: shows no legend for a single series', async () => {
    const { container } = render(
      <TimeSeriesChart points={points} series={[{ key: 'direct', label: 'Direct' }]} />,
    )
    await linePaths(container, 1)
    expect(container.querySelector('.recharts-legend-wrapper')).toBeNull()
  })

  it('T4: formats y-axis ticks with the given formatter', () => {
    render(
      <TimeSeriesChart
        points={points}
        series={[{ key: 'direct', label: 'Direct' }]}
        format={(v) => `v${v}`}
      />,
    )
    expect(screen.getAllByText(/^v\d+$/).length).toBeGreaterThan(0)
  })

  it('T5: refuses more series than it has colours', () => {
    const series = ['a', 'b', 'c', 'd', 'e'].map((k) => ({ key: k, label: k }))
    vi.spyOn(console, 'error').mockImplementation(() => {})
    expect(() => render(<TimeSeriesChart points={points} series={series} />)).toThrow(RangeError)
  })

  it('T6: breaks the line at a null value and plots no zero there', async () => {
    const gapPoints: TimeSeriesPoint[] = [
      { x: 'a', direct: 10, fixed: 5 },
      { x: 'b', direct: null, fixed: 5 },
      { x: 'c', direct: 30, fixed: 5 },
      { x: 'd', direct: 40, fixed: 5 },
    ]
    const { container } = render(
      <TimeSeriesChart
        points={gapPoints}
        series={[
          { key: 'direct', label: 'Direct' },
          { key: 'fixed', label: 'Fixed' },
        ]}
      />,
    )
    const [direct, fixed] = await linePaths(container, 2)
    // The unbroken series is one subpath; the gapped one is split in two.
    expect((fixed!.getAttribute('d') ?? '').match(/M/g)).toHaveLength(1)
    expect((direct!.getAttribute('d') ?? '').match(/M/g)?.length ?? 0).toBeGreaterThanOrEqual(1)
    // The null is not coerced to zero: the y axis never needs to reach below the data.
    const ticks = [...container.querySelectorAll('.recharts-yAxis .recharts-cartesian-axis-tick-value')].map((t) =>
      Number(t.textContent),
    )
    expect(Math.min(...ticks)).toBeGreaterThan(0)
  })

  it('T7: tooltip shows an em dash for a null value and the formatted number otherwise', async () => {
    const { container } = render(
      <TimeSeriesChart
        points={points}
        series={[
          { key: 'direct', label: 'Direct' },
          { key: 'fixed', label: 'Fixed' },
        ]}
        format={(v) => `#${v}`}
      />,
    )
    await linePaths(container, 2)
    const wrapper = container.querySelector('.recharts-wrapper') as HTMLElement
    // Hover the middle x position (2026-09-02), where direct is null.
    fireEvent.mouseMove(wrapper, { clientX: 300, clientY: 100 })
    await waitFor(() => expect(container.querySelector('.recharts-tooltip-item-list')).not.toBeNull())
    const rows = [...container.querySelectorAll('.recharts-tooltip-item')].map((r) => r.textContent)
    expect(rows.some((r) => r?.includes('Direct') && r.includes('—'))).toBe(true)
    expect(rows.some((r) => r?.includes('Fixed') && r.includes('#500000'))).toBe(true)
    expect(rows.join('|')).not.toContain('#null')
  })

  it('T7b: a single series still shows the tooltip, with an em dash, where its value is null', async () => {
    const { container } = render(
      <TimeSeriesChart points={points} series={[{ key: 'direct', label: 'Direct' }]} format={(v) => `#${v}`} />,
    )
    await linePaths(container, 1)
    const wrapper = container.querySelector('.recharts-wrapper') as HTMLElement
    fireEvent.mouseMove(wrapper, { clientX: 300, clientY: 100 })
    await waitFor(() => expect(container.querySelector('.recharts-tooltip-item-list')).not.toBeNull())
    const rows = [...container.querySelectorAll('.recharts-tooltip-item')].map((r) => r.textContent)
    expect(rows).toHaveLength(1)
    expect(rows[0]).toContain('Direct')
    expect(rows[0]).toContain('—')
  })

  it('T8: renders the plot 240 pixels high by default', async () => {
    const { container } = render(
      <TimeSeriesChart points={points} series={[{ key: 'direct', label: 'Direct' }]} />,
    )
    await linePaths(container, 1)
    expect((container.querySelector('.recharts-responsive-container') as HTMLElement).style.height).toBe('240px')
  })

  it('T9: colours four series blue, orange, violet, pink in series order', async () => {
    const four = ['a', 'b', 'c', 'd'].map((k) => ({ key: k, label: k }))
    const fourPoints: TimeSeriesPoint[] = [
      { x: '1', a: 1, b: 2, c: 3, d: 4 },
      { x: '2', a: 2, b: 3, c: 4, d: 5 },
    ]
    const { container } = render(<TimeSeriesChart points={fourPoints} series={four} />)
    const strokes = (await linePaths(container, 4)).map((p) => p.getAttribute('stroke'))
    expect(strokes).toEqual([
      'var(--color-apt-cat-blue, #2f80ff)',
      'var(--color-apt-cat-orange, #f6821f)',
      'var(--color-apt-cat-violet, #a855f7)',
      'var(--color-apt-cat-pink, #ff4d9e)',
    ])
  })

  it('T10: the fifth-series error names the limit and the count', () => {
    const series = ['a', 'b', 'c', 'd', 'e'].map((k) => ({ key: k, label: k }))
    vi.spyOn(console, 'error').mockImplementation(() => {})
    expect(() => render(<TimeSeriesChart points={points} series={series} />)).toThrow(
      /at most 4 series, got 5/,
    )
  })
})
