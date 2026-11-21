'use client'

import { useLayoutEffect, useMemo, useRef } from 'react'
import type { CSSProperties, MouseEvent } from 'react'
import type { LogCellValue, LogColumn, LogLevel, LogLine, LogPanelProps } from './types'

const LEVEL_VAR: Record<LogLevel, string> = {
  info: 'var(--lp-color-info, var(--color-text-primary, #1a1a24))',
  warn: 'var(--lp-color-warn, var(--color-warn, #b45309))',
  error: 'var(--lp-color-error, var(--color-error, #c0392b))',
  success: 'var(--lp-color-success, var(--color-success, #1f7a4d))',
  debug: 'var(--lp-color-debug, var(--color-text-secondary, rgba(0,0,0,0.55)))',
  dim: 'var(--lp-color-dim, var(--color-text-dim, rgba(0,0,0,0.45)))',
  accent: 'var(--lp-color-accent, var(--color-accent, #1e3a5f))',
}

function trackSize(width: number | string | undefined): string {
  if (width === undefined) return 'minmax(120px, 1fr)'
  if (typeof width === 'number') return `${width}px`
  return width
}

type NormalizedCell = {
  text: string
  level?: LogLevel
  color?: string
  mono?: boolean
  strong?: boolean
  link?: boolean
}

function normalize(value: LogCellValue | undefined): NormalizedCell {
  if (value === undefined) return { text: '' }
  if (typeof value === 'string') return { text: value }
  return value
}

function cellStyle<TContext>(cell: NormalizedCell, column: LogColumn<TContext>): CSSProperties {
  const level = cell.level ?? column.defaultLevel
  const mono = cell.mono ?? column.defaultMono
  const style: CSSProperties = {
    textAlign: column.align ?? 'start',
  }
  if (cell.color) style.color = cell.color
  else if (level) style.color = LEVEL_VAR[level]
  if (mono) style.fontFamily = 'var(--font-mono, ui-monospace, SFMono-Regular, monospace)'
  if (cell.strong) style.fontWeight = 600
  return style
}

export function LogPanel<TContext = unknown>(props: LogPanelProps<TContext>) {
  const {
    columns,
    lines,
    followTail = true,
    maxLines,
    emptyMessage = '(no events)',
    showHeader = true,
    className,
    maxHeight,
  } = props

  const visible = useMemo(() => {
    if (typeof maxLines === 'number' && lines.length > maxLines) {
      return lines.slice(lines.length - maxLines)
    }
    return lines
  }, [lines, maxLines])

  const scrollerRef = useRef<HTMLDivElement | null>(null)
  const pinnedRef = useRef(true)

  const handleScroll = () => {
    const el = scrollerRef.current
    if (!el) return
    const slack = 4
    pinnedRef.current = el.scrollHeight - el.scrollTop - el.clientHeight <= slack
  }

  // Re-pin when followTail flips on. A layout effect declared before the follow effect
  // runs ahead of it in the same commit, so the flip itself snaps the view to the end;
  // a passive effect would run after it and leave the view put until the next append.
  useLayoutEffect(() => {
    if (followTail) pinnedRef.current = true
  }, [followTail])

  useLayoutEffect(() => {
    if (!followTail) return
    if (!pinnedRef.current) return
    const el = scrollerRef.current
    if (!el) return
    el.scrollTop = el.scrollHeight
    // Keyed on `visible` itself, not its length: once `maxLines` caps the list, each
    // append drops the oldest row and the length stops changing, but the slice is new.
  }, [visible, followTail])

  const gridTemplateColumns = columns.map((c) => trackSize(c.width)).join(' ')
  const rootClass = className ? `lp-root ${className}` : 'lp-root'

  return (
    <div className={rootClass}>
      {showHeader && (
        <div className="lp-header" style={{ gridTemplateColumns }} role="row">
          {columns.map((col) => (
            <div
              key={col.id}
              className="lp-header-cell"
              role="columnheader"
              style={{ textAlign: col.align ?? 'start' }}
            >
              {col.title}
            </div>
          ))}
        </div>
      )}
      <div
        ref={scrollerRef}
        className="lp-body"
        onScroll={handleScroll}
        style={maxHeight !== undefined ? { maxHeight } : undefined}
      >
        {visible.length === 0 ? (
          <div className="lp-empty">{emptyMessage}</div>
        ) : (
          <ul className="lp-rows" role="rowgroup">
            {visible.map((line) => (
              <Row key={line.id} line={line} columns={columns} gridTemplateColumns={gridTemplateColumns} />
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}

type RowProps<TContext> = {
  line: LogLine<TContext>
  columns: LogColumn<TContext>[]
  gridTemplateColumns: string
}

function Row<TContext>({ line, columns, gridTemplateColumns }: RowProps<TContext>) {
  return (
    <li className="lp-row" role="row" style={{ gridTemplateColumns }}>
      {columns.map((col) => {
        const cell = normalize(line.values[col.id])
        const interactive = col.isClickable || cell.link || Boolean(col.onCellClick)
        const handleClick = col.onCellClick
          ? (e: MouseEvent<HTMLDivElement>) => {
              e.stopPropagation()
              col.onCellClick?.(line)
            }
          : undefined
        const handleDoubleClick = col.onCellDoubleClick
          ? (e: MouseEvent<HTMLDivElement>) => {
              e.stopPropagation()
              col.onCellDoubleClick?.(line)
            }
          : undefined
        const className = [
          'lp-cell',
          interactive ? 'lp-cell--interactive' : '',
          cell.link ? 'lp-cell--link' : '',
        ]
          .filter(Boolean)
          .join(' ')
        return (
          <div
            key={col.id}
            role="cell"
            className={className}
            style={cellStyle(cell, col)}
            title={cell.text}
            onClick={handleClick}
            onDoubleClick={handleDoubleClick}
          >
            {cell.text}
          </div>
        )
      })}
    </li>
  )
}
