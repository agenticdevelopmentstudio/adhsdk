import type { HTMLAttributes } from "react"

import { Progress } from "../components/progress"
import { cn } from "../lib/utils"

// "x of y items done" and the whole percentage over a Progress bar; the bar
// turns green once everything is done. Pure assembly of Progress.

export interface ProgressSummaryProps extends HTMLAttributes<HTMLDivElement> {
  done: number
  total: number
  /** The noun after the count; default "items". */
  label?: string
}

export function ProgressSummary({
  done,
  total,
  label = "items",
  className,
  ...rest
}: ProgressSummaryProps) {
  const percent = total > 0 ? Math.floor((done * 100) / total) : 0
  const text = `${done} of ${total} ${label} done`
  const complete = total > 0 && done === total
  return (
    <div className={cn("flex flex-col gap-2", className)} {...rest}>
      <div className="flex items-baseline justify-between gap-2 text-sm">
        <span className="text-apt-text">{text}</span>
        <span className="font-mono text-apt-text-muted">{`${percent}%`}</span>
      </div>
      <Progress
        value={percent}
        aria-label={text}
        indicatorClassName={complete ? "bg-apt-green" : undefined}
      />
    </div>
  )
}
