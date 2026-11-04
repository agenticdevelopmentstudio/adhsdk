"use client"

import { useState, type PointerEvent, type ReactElement } from "react"

import { cn } from "../lib/utils"

// A count over time: one axis, a crosshair and tooltip, a legend when there is more than one
// series, and a table view for anyone who cannot read the marks. It takes colors as CSS values
// so the caller's series keep their hue when a filter changes which of them are shown.
//
// Dependency-free on purpose. The plot is an SVG stretched over its box
// (preserveAspectRatio="none", non-scaling strokes), and everything that must not stretch
// (tick labels, dots, the tooltip) is HTML positioned by percent over it. That keeps the chart
// fluid without measuring anything, so it needs no ResizeObserver and renders the same on the
// server.

export interface TrendSeries {
  name: string
  /** Any CSS color: a theme token, normally. */
  color: string
  /** One per label. Null is a gap, not a zero. */
  values: readonly (number | null)[]
}

export interface TrendChartProps {
  labels: readonly string[]
  series: readonly TrendSeries[]
  /** Says what the chart shows, for a screen reader. */
  ariaLabel: string
  /** `bars` draws the first series only; use it for a single count per period. */
  variant?: "line" | "bars"
  /** Height of the plot, in pixels. */
  height?: number
  formatValue?: (value: number) => string
  /** Formats a label under the axis. */
  formatLabel?: (label: string) => string
  /** Formats a label in the tooltip and the table; defaults to `formatLabel`. */
  formatDetail?: (label: string) => string
  emptyLabel?: string
  className?: string
}

const COMPACT = new Intl.NumberFormat("en", { notation: "compact", maximumFractionDigits: 1 })
const WHOLE = new Intl.NumberFormat("en")

/** Whole numbers below 10,000, and compact from there, where the digits stop being readable. */
export function formatCount(value: number): string {
  return Math.abs(value) >= 10_000 ? COMPACT.format(value) : WHOLE.format(value)
}

/**
 * Round axis ticks from zero to at or above `max`, on a 1/2/5 step. These are counts, so the step
 * is never below one: a tick of "0.5 pageviews" names something that cannot happen.
 */
export function niceTicks(max: number, count = 4): number[] {
  if (!(max > 0)) return [0, 1]
  const raw = max / count
  const magnitude = 10 ** Math.floor(Math.log10(raw))
  const normalized = raw / magnitude
  const nice = normalized <= 1 ? 1 : normalized <= 2 ? 2 : normalized <= 5 ? 5 : 10
  const step = Math.max(1, nice * magnitude)
  const ticks: number[] = []
  for (let tick = 0; tick < max + step; tick += step) ticks.push(tick)
  return ticks
}

/** Where label `i` of `n` sits across the plot, as a percentage. */
function xPercent(i: number, n: number, variant: "line" | "bars"): number {
  if (variant === "bars") return ((i + 0.5) / n) * 100
  return n === 1 ? 50 : (i / (n - 1)) * 100
}

/** The runs of consecutive non-null values. A null breaks the line rather than dropping to zero. */
function runs(values: readonly (number | null)[]): { i: number; value: number }[][] {
  const out: { i: number; value: number }[][] = []
  let current: { i: number; value: number }[] = []
  values.forEach((value, i) => {
    if (value === null) {
      if (current.length > 0) out.push(current)
      current = []
    } else {
      current.push({ i, value })
    }
  })
  if (current.length > 0) out.push(current)
  return out
}

/**
 * Up to five labels at a constant step, counted back from the newest bucket. The step has to be a
 * whole number of buckets or the gaps between dates vary (a week labelled Oct 29, 31, Nov 1, 3, 4),
 * so when the buckets do not divide evenly it is the oldest end that goes unlabelled, not the newest.
 */
export function axisLabelIndexes(n: number): number[] {
  if (n <= 5) return Array.from({ length: n }, (_, i) => i)
  const step = Math.ceil((n - 1) / 4)
  const indexes: number[] = []
  for (let i = n - 1; i >= 0; i -= step) indexes.unshift(i)
  return indexes
}

export function TrendChart({
  labels,
  series,
  ariaLabel,
  variant = "line",
  height = 200,
  formatValue = formatCount,
  formatLabel = (label) => label,
  formatDetail,
  emptyLabel = "No data in this range.",
  className,
}: TrendChartProps): ReactElement {
  const [hover, setHover] = useState<number | null>(null)
  const detail = formatDetail ?? formatLabel
  const shown = variant === "bars" ? series.slice(0, 1) : series
  const n = labels.length
  const all = shown.flatMap((s) => s.values).filter((v): v is number => v !== null)

  if (n === 0 || all.length === 0) {
    return (
      <div
        className={cn("flex items-center justify-center font-mono text-xs text-apt-text-dim", className)}
        style={{ height }}
      >
        {emptyLabel}
      </div>
    )
  }

  const ticks = niceTicks(Math.max(...all))
  const top = ticks[ticks.length - 1] ?? 1
  const yPercent = (value: number): number => 100 - (value / top) * 100

  function onPointerMove(event: PointerEvent<HTMLDivElement>): void {
    const box = event.currentTarget.getBoundingClientRect()
    if (box.width === 0) return
    const fraction = Math.min(1, Math.max(0, (event.clientX - box.left) / box.width))
    setHover(variant === "bars" ? Math.min(n - 1, Math.floor(fraction * n)) : Math.round(fraction * (n - 1)))
  }

  const active = hover !== null && hover < n ? hover : null
  const activeX = active === null ? 0 : xPercent(active, n, variant)

  return (
    <figure className={cn("m-0 min-w-0", className)} aria-label={ariaLabel}>
      <div className="flex gap-2">
        {/* Y ticks are text, so they stay crisp however far the plot beside them stretches. */}
        <div aria-hidden className="relative w-10 flex-none" style={{ height }}>
          {ticks.map((tick) => (
            <span
              key={tick}
              className="absolute right-0 translate-y-1/2 font-mono text-[10px] leading-none text-apt-text-dim"
              style={{ bottom: `${(tick / top) * 100}%` }}
            >
              {formatCount(tick)}
            </span>
          ))}
        </div>

        <div
          data-slot="trend-plot"
          className="relative min-w-0 flex-1 touch-pan-y"
          style={{ height }}
          onPointerMove={onPointerMove}
          onPointerDown={onPointerMove}
          onPointerLeave={() => setHover(null)}
        >
          {ticks.map((tick) => (
            <div
              key={tick}
              aria-hidden
              className="absolute inset-x-0 border-t border-apt-border"
              style={{ bottom: `${(tick / top) * 100}%`, opacity: tick === 0 ? 1 : 0.5 }}
            />
          ))}

          {variant === "line" ? (
            <svg
              aria-hidden
              viewBox="0 0 100 100"
              preserveAspectRatio="none"
              className="absolute inset-0 size-full overflow-visible"
            >
              {shown.map((s) =>
                runs(s.values).map((run) => {
                  const points = run.map((p) => `${xPercent(p.i, n, "line")},${yPercent(p.value)}`)
                  const first = xPercent(run[0]!.i, n, "line")
                  const last = xPercent(run[run.length - 1]!.i, n, "line")
                  return (
                    <g key={`${s.name}-${run[0]!.i}`}>
                      {/* A fill only for a lone series: two would muddy each other. */}
                      {shown.length === 1 && run.length > 1 && (
                        <polygon
                          points={`${first},100 ${points.join(" ")} ${last},100`}
                          style={{ fill: `color-mix(in srgb, ${s.color} 10%, transparent)` }}
                        />
                      )}
                      <polyline
                        points={points.join(" ")}
                        fill="none"
                        strokeWidth={2}
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        vectorEffect="non-scaling-stroke"
                        style={{ stroke: s.color }}
                      />
                    </g>
                  )
                }),
              )}
            </svg>
          ) : (
            <div aria-hidden className="absolute inset-0 flex items-end justify-around gap-0.5">
              {(shown[0]?.values ?? []).map((value, i) => (
                <div
                  key={labels[i] ?? i}
                  className="min-w-0 flex-1 rounded-t"
                  style={{
                    height: `${((value ?? 0) / top) * 100}%`,
                    maxWidth: 24,
                    backgroundColor: shown[0]?.color,
                    opacity: active === null || active === i ? 1 : 0.55,
                  }}
                />
              ))}
            </div>
          )}

          {/* A point with no neighbour has no line to be seen on, so it gets a dot. */}
          {variant === "line" &&
            shown.map((s) =>
              runs(s.values)
                .filter((run) => run.length === 1)
                .map((run) => (
                  <Dot key={`${s.name}-${run[0]!.i}`} color={s.color} x={xPercent(run[0]!.i, n, "line")} y={yPercent(run[0]!.value)} />
                )),
            )}

          {active !== null && (
            <>
              {variant === "line" && (
                <>
                  <div
                    aria-hidden
                    className="pointer-events-none absolute inset-y-0 w-px bg-apt-text-dim"
                    style={{ left: `${activeX}%` }}
                  />
                  {shown.map((s) => {
                    const value = s.values[active] ?? null
                    return value === null ? null : (
                      <Dot key={s.name} color={s.color} x={activeX} y={yPercent(value)} />
                    )
                  })}
                </>
              )}
              <div
                role="status"
                className="pointer-events-none absolute top-0 z-10 w-max max-w-[220px] rounded-md border border-apt-border bg-apt-surface px-2.5 py-1.5 font-mono text-[11px] shadow-md"
                style={{
                  left: `${activeX}%`,
                  transform: activeX > 55 ? "translateX(calc(-100% - 10px))" : "translateX(10px)",
                }}
              >
                <div className="mb-1 text-apt-text-dim">{detail(labels[active] ?? "")}</div>
                {shown.map((s) => {
                  const value = s.values[active] ?? null
                  return (
                    <div key={s.name} className="flex items-center gap-1.5">
                      <span aria-hidden className="size-2 flex-none rounded-full" style={{ backgroundColor: s.color }} />
                      <span className="min-w-0 truncate text-apt-text-muted">{s.name}</span>
                      <span className="ml-auto pl-3 font-semibold text-apt-text">
                        {value === null ? "—" : formatValue(value)}
                      </span>
                    </div>
                  )
                })}
              </div>
            </>
          )}
        </div>
      </div>

      {/* X labels: the ends anchor inward so neither hangs off the plot. */}
      <div aria-hidden className="relative ml-12 mt-1.5 h-3.5">
        {axisLabelIndexes(n).map((i) => {
          const x = xPercent(i, n, variant)
          const anchor = x < 8 ? "translate-x-0" : x > 92 ? "-translate-x-full" : "-translate-x-1/2"
          return (
            <span
              key={i}
              className={cn("absolute whitespace-nowrap font-mono text-[10px] leading-none text-apt-text-dim", anchor)}
              style={{ left: `${x}%` }}
            >
              {formatLabel(labels[i] ?? "")}
            </span>
          )
        })}
      </div>

      {shown.length > 1 && (
        <ul className="m-0 mt-2.5 flex list-none flex-wrap gap-x-4 gap-y-1 p-0 pl-12">
          {shown.map((s) => (
            <li key={s.name} className="flex items-center gap-1.5 font-mono text-[11px] text-apt-text-muted">
              <span aria-hidden className="h-0.5 w-3.5 rounded-full" style={{ backgroundColor: s.color }} />
              {s.name}
            </li>
          ))}
        </ul>
      )}

      <details className="mt-2 pl-12">
        <summary className="cursor-pointer font-mono text-[11px] text-apt-text-dim hover:text-apt-text-muted">
          View as table
        </summary>
        <div className="mt-1.5 max-h-56 overflow-auto">
          <table className="w-full border-collapse font-mono text-[11px]">
            <caption className="sr-only">{ariaLabel}</caption>
            <thead>
              <tr className="text-apt-text-dim">
                <th scope="col" className="px-2 py-1 text-left font-medium">
                  Period
                </th>
                {shown.map((s) => (
                  <th key={s.name} scope="col" className="px-2 py-1 text-right font-medium">
                    {s.name}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {labels.map((label, i) => (
                <tr key={label} className="border-t border-apt-border text-apt-text-muted">
                  <th scope="row" className="px-2 py-1 text-left font-normal">
                    {detail(label)}
                  </th>
                  {shown.map((s) => {
                    const value = s.values[i] ?? null
                    return (
                      <td key={s.name} className="px-2 py-1 text-right">
                        {value === null ? "—" : formatValue(value)}
                      </td>
                    )
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </details>
    </figure>
  )
}

/** A marker with a surface-colored ring, so it reads where it crosses another line. */
function Dot({ color, x, y }: { color: string; x: number; y: number }): ReactElement {
  return (
    <span
      aria-hidden
      className="pointer-events-none absolute size-2 -translate-x-1/2 -translate-y-1/2 rounded-full"
      style={{
        left: `${x}%`,
        top: `${y}%`,
        backgroundColor: color,
        boxShadow: "0 0 0 2px var(--color-apt-surface)",
      }}
    />
  )
}
