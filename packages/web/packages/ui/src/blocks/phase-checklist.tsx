import type { HTMLAttributes } from "react"
import { CircleDot, Square, SquareCheck, SquareX, type LucideIcon } from "lucide-react"

import { countProgress, type ProgressPhase, type ProgressStatus } from "../lib/progress-count"
import { cn } from "../lib/utils"

// One section per phase (heading plus its own "done / total"), a list row per
// item with a status icon and an accessible status name. Stopped rows are
// struck through and muted.

export interface PhaseChecklistProps extends HTMLAttributes<HTMLDivElement> {
  phases: ProgressPhase[]
}

const STATUS: Record<ProgressStatus, { Icon: LucideIcon; name: string; iconClass: string }> = {
  done: { Icon: SquareCheck, name: "done", iconClass: "text-apt-green" },
  "in-progress": { Icon: CircleDot, name: "in progress", iconClass: "text-apt-gold" },
  todo: { Icon: Square, name: "to do", iconClass: "text-apt-text-muted" },
  stopped: { Icon: SquareX, name: "stopped", iconClass: "text-apt-text-dim" },
}

export function PhaseChecklist({ phases, className, ...rest }: PhaseChecklistProps) {
  return (
    <div className={cn("flex flex-col gap-6", className)} {...rest}>
      {phases.map((phase, p) => {
        const { done, total } = countProgress(phase.items)
        return (
          <section key={p} className="flex flex-col gap-2">
            <h3 className="flex items-baseline justify-between gap-2 text-sm font-semibold text-apt-text">
              <span>{phase.title}</span>
              <span className="font-mono text-xs font-normal text-apt-text-muted">{`${done} / ${total}`}</span>
            </h3>
            <ul className="flex flex-col gap-1.5">
              {phase.items.map((item, i) => {
                const { Icon, name, iconClass } = STATUS[item.status]
                const stopped = item.status === "stopped"
                return (
                  <li key={i} className="flex items-start gap-2 text-sm">
                    <Icon aria-hidden className={cn("mt-0.5 size-4 shrink-0", iconClass)} />
                    <span className="sr-only">{name}</span>
                    <span className={stopped ? "text-apt-text-dim line-through" : "text-apt-text"}>
                      {item.text}
                    </span>
                  </li>
                )
              })}
            </ul>
          </section>
        )
      })}
    </div>
  )
}
