
This recipe covers two independent components that share the name "popover" but little else:

- **Full-featured** (`Popover` / `PopoverTrigger` / `PopoverContent`, source: `packages/web/packages/ui/src/components/popover.tsx`): built on `@base-ui/react/popover`, with `dialog` role, non-modal focus management, and four-sided placement.
- **Lightweight** (`Popover`, source: `packages/web/packages/popover/src/Popover.tsx`): a hover-only panel with no positioning library and no dialog semantics, supporting only top/bottom placement.

Every requirement, test vector, and configuration option below is tagged with the variant(s) it applies to. Where the two disagree, each keeps its own behavior rather than being forced into a shared contract.

