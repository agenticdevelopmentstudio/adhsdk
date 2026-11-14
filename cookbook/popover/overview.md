
This ingredient covers two independent components that share the name "popover" but little else:

- **Full-featured** (`Popover` / `PopoverTrigger` / `PopoverContent`, source: `packages/web/packages/ui/src/components/popover.tsx`): built on `@base-ui/react/popover`, with `dialog` role, non-modal focus management, and four-sided placement.
- **Lightweight** (`Popover`, source: `packages/web/packages/popover/src/Popover.tsx`): a hover-only panel with no positioning library and no dialog semantics, supporting only top/bottom placement. It is positioned against a `PopoverAnchor` (`packages/web/packages/popover/src/PopoverAnchor.tsx`), a `position: relative` wrapper that holds both the trigger and the panel. A caller opens it by passing `open`; the package's `useHoverPopoverGroup` hook (`packages/web/packages/popover/src/useHoverPopoverGroup.ts`) keeps hover-intent state for a set of such popovers, with at most one open and a close delay (default 200ms) so the pointer can cross from trigger to panel.

Every requirement, test vector, and configuration option below is tagged with the variant(s) it applies to. Where the two disagree, each keeps its own behavior rather than being forced into a shared contract.

