
`PhaseChecklist` in `@adh-sdk/ui` renders `phases` (`ProgressPhase[]`). Each phase is a `<section>` whose heading is the phase title with its own count "`{done} / {total}`" from `countProgress` (stopped items leave the total). Each item is an `<li>` with a lucide icon for its status and a visually hidden status name. The types and the counting rule live in `@adh-sdk/ui/lib/progress-count`.
