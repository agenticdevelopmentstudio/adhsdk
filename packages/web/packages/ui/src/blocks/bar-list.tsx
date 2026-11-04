"use client"

import { useState, type ReactElement } from "react"

import { cn } from "../lib/utils"
import { formatCount } from "./trend-chart"

// A ranked breakdown: name and value together from the left, a thin bar under them. Long names are the norm
// here (paths, referrers, hostnames), and a label column beside the bar would leave them either
// truncated to nothing or crowding the bars out at phone width. Nothing is hidden for good: a long
// name wraps, and the rows past the limit open in place.

export interface BarListItem {
  name: string
  value: number
  /** Replaces the formatted value, e.g. "12 issues · 340 events". */
  detail?: string
}

export interface BarListProps {
  items: readonly BarListItem[]
  /** Says what is being ranked, for a screen reader. */
  ariaLabel: string
  /** Any CSS color: a theme token, normally. */
  color?: string
  formatValue?: (value: number) => string
  /** Rows shown at first; a button beneath opens the rest. */
  maxItems?: number
  /** Makes each row a button. */
  onSelect?: (name: string) => void
  selected?: string | null
  emptyLabel?: string
  className?: string
}

function Row({
  item,
  max,
  color,
  formatValue,
}: {
  item: BarListItem
  max: number
  color: string
  formatValue: (value: number) => string
}): ReactElement {
  return (
    <>
      <span className="flex items-baseline gap-2 font-mono text-[11px]">
        <span className="min-w-0 text-apt-text-muted [overflow-wrap:anywhere]">
          {item.name}
        </span>
        <span className="flex-none font-semibold text-apt-text">{item.detail ?? formatValue(item.value)}</span>
      </span>
      <span aria-hidden className="mt-1 block h-1.5">
        <span
          className="block h-full rounded-r"
          style={{ width: `${max > 0 ? (item.value / max) * 100 : 0}%`, minWidth: item.value > 0 ? 2 : 0, backgroundColor: color }}
        />
      </span>
    </>
  )
}

export function BarList({
  items,
  ariaLabel,
  color = "var(--color-apt-cat-blue)",
  formatValue = formatCount,
  maxItems = 8,
  onSelect,
  selected = null,
  emptyLabel = "Nothing to show.",
  className,
}: BarListProps): ReactElement {
  const [expanded, setExpanded] = useState(false)

  if (items.length === 0) {
    return <div className={cn("font-mono text-xs text-apt-text-dim", className)}>{emptyLabel}</div>
  }

  const shown = expanded ? items : items.slice(0, maxItems)
  const canExpand = items.length > maxItems
  const max = Math.max(...items.map((item) => item.value))

  return (
    <div className={cn("min-w-0", className)}>
      <ul aria-label={ariaLabel} className="m-0 flex list-none flex-col gap-2 p-0">
        {shown.map((item) => (
          <li key={item.name} className="min-w-0">
            {onSelect ? (
              <button
                type="button"
                aria-pressed={selected === item.name}
                onClick={() => onSelect(item.name)}
                className={cn(
                  "block w-full cursor-pointer rounded-sm text-left outline-none focus-visible:ring-2 focus-visible:ring-apt-gold/40",
                  selected !== null && selected !== item.name && "opacity-55",
                )}
              >
                <Row item={item} max={max} color={color} formatValue={formatValue} />
              </button>
            ) : (
              <Row item={item} max={max} color={color} formatValue={formatValue} />
            )}
          </li>
        ))}
      </ul>
      {canExpand && (
        <button
          type="button"
          aria-expanded={expanded}
          onClick={() => setExpanded(!expanded)}
          className="mt-2 cursor-pointer rounded-sm p-0 font-mono text-[10px] text-apt-text-muted underline underline-offset-2 outline-none hover:text-apt-text focus-visible:ring-2 focus-visible:ring-apt-gold/40"
        >
          {expanded ? "Show fewer" : `Show all ${items.length}`}
        </button>
      )}
    </div>
  )
}
