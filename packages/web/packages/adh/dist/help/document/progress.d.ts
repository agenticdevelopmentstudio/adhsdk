/**
 * A tutorial's saved progress, and how a tick changes it. Pure, so the Steps pane and its tests
 * share one definition of what ticking a step does.
 *
 * A step may have sub-steps (see `stepOf`). Ticking or clearing the step ticks or clears every
 * one of them; ticking the last of them ticks the step too and moves on to the next step, and
 * clearing any of them clears the step.
 */
import type { Substep, TutorialStep } from './parts';
/** What progress needs of a step: its id, and its sub-steps' ids when it has any. */
export type StepShape = Pick<TutorialStep, 'id'> & {
    substeps?: readonly Pick<Substep, 'id'>[];
};
/**
 * What is saved for one tutorial. `v` versions the shape, so a change to it can drop old saves.
 * `done` holds the ids of the steps and the sub-steps ticked.
 */
export interface TutorialProgress {
    v: 1;
    done: string[];
    active: string | null;
}
/** The localStorage key a tutorial's progress is saved under. */
export declare function progressKey(tutorialId: string): string;
/** The state a tutorial starts in: nothing done, the first step active. */
export declare function startOf(steps: readonly StepShape[]): TutorialProgress;
/**
 * Saved progress, checked against the steps the tutorial has now: a step since renamed or removed
 * is dropped rather than counted. Anything unreadable is the starting state.
 */
export declare function readProgress(raw: string | null, steps: readonly StepShape[]): TutorialProgress;
/** The first step after index `from` not yet done, wrapping round; null when every step is. */
export declare function nextOpen(steps: readonly StepShape[], done: readonly string[], from: number): string | null;
/** The number of steps ticked, sub-steps not counted. */
export declare function stepsDone(progress: TutorialProgress, steps: readonly StepShape[]): number;
/** The progress after the reader ticks or clears step or sub-step `id`. */
export declare function toggle(progress: TutorialProgress, steps: readonly StepShape[], id: string, checked: boolean): TutorialProgress;
//# sourceMappingURL=progress.d.ts.map