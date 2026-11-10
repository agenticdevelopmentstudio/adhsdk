
- **Empty trigger text**: If `AccordionTrigger` receives no children or null children, chevron MUST still render and rotate on panel open. Screen reader announcement is degraded but component does not error.
- **Empty panel content**: If `AccordionPanel` receives no children or null children, wrapper div with pb-3 still renders. Component does not error.
- **Null or undefined className**: If className prop is null, undefined, or omitted, default classes MUST apply via `cn()` utility. No runtime error occurs.
- **Conflicting className properties**: If className prop contains a Tailwind class that conflicts with a default class (e.g., py-4 vs. py-3), the merge order in `cn()` determines precedence. Consumers who specify a class take precedence over defaults.
- **Only one panel open by default**: MUST default to single-open — see #requirements/default-single-open. Passing `multiple` to `Accordion` allows multiple panels to be open simultaneously.
- **Very long trigger text**: No special handling; text wraps naturally. Chevron remains positioned to the right via flex layout (flex flex-1 items-center justify-between).
- **Very long panel content**: No special handling; panel height is not constrained. Consumers can add max-height and overflow-y: auto via className if needed.

