import type { ReactNode } from "react"

import { EmptyState } from "../components/empty-state"
import { StatusDot } from "../components/status-dot"
import { cn } from "../lib/utils"
import type { Tone } from "../lib/tone"

// A vertical timeline: one row per event, in the order given. Each row has a
// state-toned StatusDot on a connector line, the time, the title and an
// optional markdown detail. `ui` has no markdown dependency: the caller passes
// the renderer, and without one the detail is plain text.

export type TimelineState = "info" | "running" | "done" | "warning" | "failed"

export interface TimelineEvent {
  /** ISO 8601 timestamp. */
  time: string
  title: ReactNode
  /** Markdown, rendered by `renderMarkdown`. */
  detail?: string
  /** Defaults to `info`. */
  state?: TimelineState
}

export interface EventTimelineProps {
  events: TimelineEvent[]
  /** Renders a detail's markdown; omitted, the detail is plain text. */
  renderMarkdown?: (md: string) => ReactNode
  /** Formats an event's ISO time; defaults to `new Date(iso).toLocaleString()`. */
  formatTime?: (iso: string) => string
  /** Shown when there are no events. */
  emptyLabel?: string
  className?: string
}

const STATE: Record<TimelineState, { tone: Tone; pulse: boolean }> = {
  info: { tone: "neutral", pulse: false },
  running: { tone: "blue", pulse: true },
  done: { tone: "success", pulse: false },
  warning: { tone: "orange", pulse: false },
  failed: { tone: "error", pulse: false },
}

const defaultFormatTime = (iso: string) => new Date(iso).toLocaleString()

export function EventTimeline({
  events,
  renderMarkdown,
  formatTime = defaultFormatTime,
  emptyLabel = "No events yet.",
  className,
}: EventTimelineProps) {
  if (events.length === 0) return <EmptyState title={emptyLabel} className={className} />
  return (
    <ol className={cn("flex flex-col", className)}>
      {events.map((event, i) => {
        const state = event.state ?? "info"
        const { tone, pulse } = STATE[state]
        const last = i === events.length - 1
        return (
          <li key={i} className="flex gap-3">
            <div className="flex flex-col items-center">
              <span className="mt-1.5 flex shrink-0">
                <StatusDot tone={tone} className={pulse ? "animate-pulse" : undefined} />
              </span>
              {!last && <span data-testid="timeline-connector" className="w-px flex-1 bg-apt-border" />}
            </div>
            <div className={cn("flex min-w-0 flex-col gap-0.5", last ? "" : "pb-4")}>
              <time dateTime={event.time} className="font-mono text-xs text-apt-text-dim">
                {formatTime(event.time)}
              </time>
              <div className="text-sm text-apt-text">
                <span className="sr-only">{state}</span>
                {event.title}
              </div>
              {event.detail &&
                (renderMarkdown ? (
                  <div className="text-sm text-apt-text-muted">{renderMarkdown(event.detail)}</div>
                ) : (
                  <p className="whitespace-pre-wrap text-sm text-apt-text-muted">{event.detail}</p>
                ))}
            </div>
          </li>
        )
      })}
    </ol>
  )
}
