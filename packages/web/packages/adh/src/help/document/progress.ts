/**
 * A tutorial's saved progress, and how a tick changes it. Pure, so the Steps pane and its tests
 * share one definition of what ticking a step does.
 *
 * A step may have sub-steps (see `stepOf`). Ticking or clearing the step ticks or clears every
 * one of them; ticking the last of them ticks the step too and moves on to the next step, and
 * clearing any of them clears the step.
 */

import type { Substep, TutorialStep } from './parts'

/** What progress needs of a step: its id, and its sub-steps' ids when it has any. */
export type StepShape = Pick<TutorialStep, 'id'> & { substeps?: readonly Pick<Substep, 'id'>[] }

/**
 * What is saved for one tutorial. `v` versions the shape, so a change to it can drop old saves.
 * `done` holds the ids of the steps and the sub-steps ticked.
 */
export interface TutorialProgress {
  v: 1
  done: string[]
  active: string | null
}

/** The localStorage key a tutorial's progress is saved under. */
export function progressKey(tutorialId: string): string {
  return `adh-help:tutorial-progress:${tutorialId}`
}

/** The state a tutorial starts in: nothing done, the first step active. */
export function startOf(steps: readonly StepShape[]): TutorialProgress {
  return { v: 1, done: [], active: steps[0]?.id ?? null }
}

/**
 * Saved progress, checked against the steps the tutorial has now: a step since renamed or removed
 * is dropped rather than counted. Anything unreadable is the starting state.
 */
export function readProgress(
  raw: string | null,
  steps: readonly StepShape[],
): TutorialProgress {
  if (!raw) return startOf(steps)
  try {
    const saved = JSON.parse(raw) as Partial<TutorialProgress>
    if (saved?.v !== 1 || !Array.isArray(saved.done)) return startOf(steps)
    const ids = new Set(steps.flatMap((s) => [s.id, ...(s.substeps ?? []).map((sub) => sub.id)]))
    const kept = saved.done.filter((id): id is string => typeof id === 'string' && ids.has(id))
    const done = settle(steps, kept)
    const active =
      typeof saved.active === 'string' && steps.some((s) => s.id === saved.active)
        ? saved.active
        : nextOpen(steps, done, -1)
    return { v: 1, done, active }
  } catch {
    return startOf(steps)
  }
}

/** The first step after index `from` not yet done, wrapping round; null when every step is. */
export function nextOpen(
  steps: readonly StepShape[],
  done: readonly string[],
  from: number,
): string | null {
  for (let k = 1; k <= steps.length; k++) {
    const step = steps[(from + k) % steps.length]
    if (step && !done.includes(step.id)) return step.id
  }
  return null
}

/** The ids of a step's sub-steps. */
function subIds(step: StepShape): string[] {
  return (step.substeps ?? []).map((sub) => sub.id)
}

/**
 * `done` made consistent with the steps: a step ticked has every sub-step ticked, and a step whose
 * sub-steps are all ticked is ticked. Order is kept, additions at the end.
 */
function settle(steps: readonly StepShape[], done: readonly string[]): string[] {
  const out = [...new Set(done)]
  for (const step of steps) {
    const subs = subIds(step)
    if (!subs.length) continue
    if (out.includes(step.id)) {
      for (const sub of subs) if (!out.includes(sub)) out.push(sub)
    } else if (subs.every((sub) => out.includes(sub))) {
      out.push(step.id)
    }
  }
  return out
}

/** The number of steps ticked, sub-steps not counted. */
export function stepsDone(progress: TutorialProgress, steps: readonly StepShape[]): number {
  return steps.filter((step) => progress.done.includes(step.id)).length
}

/** The progress after the reader ticks or clears step or sub-step `id`. */
export function toggle(
  progress: TutorialProgress,
  steps: readonly StepShape[],
  id: string,
  checked: boolean,
): TutorialProgress {
  const at = steps.findIndex((s) => s.id === id || subIds(s).includes(id))
  const step = steps[at]
  if (!step) return progress
  const subs = subIds(step)
  // Ticking or clearing a step takes all its sub-steps with it; a sub-step takes only itself, and
  // clearing it un-ticks its step.
  const touched = id === step.id ? [step.id, ...subs] : checked ? [id] : [id, step.id]
  if (!checked) {
    return { v: 1, done: progress.done.filter((d) => !touched.includes(d)), active: step.id }
  }
  const done = settle(steps, [...progress.done, ...touched])
  return { v: 1, done, active: done.includes(step.id) ? nextOpen(steps, done, at) : step.id }
}
