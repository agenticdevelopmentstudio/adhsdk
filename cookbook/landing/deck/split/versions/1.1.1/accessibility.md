
Split is a generic container with no interactive semantics. Child elements retain their own accessibility properties. The component itself requires no special accessibility attributes — semantic meaning is determined by its children. Per **preserves-reading-order**, the root carries no ARIA role, and DOM order matches visual order (WCAG 1.3.2, Meaningful Sequence) in both the stacked and two-column layouts.

