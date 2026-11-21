// The one place the progress counting rule lives. A stopped item is shown but
// leaves the total, so stopped work never holds finished work below 100%.

export type ProgressStatus = "todo" | "in-progress" | "done" | "stopped"

export interface ProgressItem {
  text: string
  status: ProgressStatus
}

export interface ProgressPhase {
  title: string
  items: ProgressItem[]
}

export interface ProgressCount {
  done: number
  total: number
  /** Whole percent, rounded down so 100 means everything is done; 0 when total is 0. */
  percent: number
}

/** Count items (or every item of every phase): total excludes stopped items. */
export function countProgress(input: ProgressPhase[] | ProgressItem[]): ProgressCount {
  const items: ProgressItem[] = (input as Array<ProgressPhase | ProgressItem>).flatMap((entry) =>
    "items" in entry ? entry.items : [entry],
  )
  let done = 0
  let total = 0
  for (const item of items) {
    if (item.status === "stopped") continue
    total += 1
    if (item.status === "done") done += 1
  }
  return { done, total, percent: total ? Math.floor((done * 100) / total) : 0 }
}
