/**
 * A tutorial's Steps pane: every step with a checkbox, the step being worked on drawn with a
 * border. Ticking a step moves the border to the next step not yet done; the header's Start
 * clears every box and puts the border back on the first step, which is also how the pane opens
 * the first time. A step made of several actions lists them as sub-steps, each with an indented
 * box of its own: ticking the step ticks them all, and ticking the last of them ticks the step and
 * moves on. Progress is kept in this browser's localStorage per tutorial, so a reader who
 * comes back finds their place, and a tick in one tab shows in another.
 *
 * Its own tsup entry, imported by package path from the server DocumentDetail, so its
 * 'use client' marks this module only.
 */
import { type ReactNode } from 'react';
import type { TutorialStep } from './parts';
export declare function TutorialSteps({ tutorialId, steps, title, icon, }: {
    tutorialId: string;
    steps: TutorialStep[];
    title: string;
    icon?: ReactNode;
}): import("react").JSX.Element;
//# sourceMappingURL=TutorialSteps.d.ts.map