
The source does not read `prefers-reduced-motion` itself. The pulsing animation is not suppressed automatically; per **reduced-motion-support**, a consumer opts in via a `motion-reduce:animate-none` override in `className`, which class-merge preserves alongside the built-in `animate-pulse` class.

