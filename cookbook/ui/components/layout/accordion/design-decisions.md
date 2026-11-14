
1. **Decision**: Export `Accordion`, `AccordionItem`, `AccordionTrigger`, and `AccordionPanel` as four separate, composable components rather than one monolithic component.
   **Rationale**: Follows the composition pattern established by `@base-ui/react/accordion` and gives consumers maximum flexibility to customize each part independently.
   **Approved**: pending

2. **Decision**: Rotate the chevron 180 degrees via Tailwind's `rotate-180` utility (which sets the CSS `rotate` property, not `transform`) to indicate open/closed state, rather than swapping icons.
   **Rationale**: A recognizable UI pattern that gives clear visual feedback.
   **Approved**: pending

3. **Decision**: Wrap panel content in an inner `div` with fixed bottom padding (`pb-3`, 12px) rather than leaving spacing to consumers.
   **Rationale**: Creates consistent visual breathing room between the panel content and the next item's border/trigger by default; consumers can still override via `className`.
   **Approved**: pending

4. **Decision**: Set a `data-slot` attribute on every rendered element (`accordion`, `accordion-item`, `accordion-trigger`, `accordion-panel`).
   **Rationale**: Enables predictable CSS targeting (e.g. `[data-slot="accordion-trigger"]`) and makes automated testing more stable by decoupling tests from class names, which may change.
   **Approved**: pending

5. **Decision**: Delegate all expand/collapse logic, ARIA attribute management, and keyboard handling to the underlying primitive library (`@base-ui/react/accordion` on web).
   **Rationale**: Keeps the wrapper lightweight and keeps WCAG conformance current as the primitive is updated, rather than reimplementing accessible disclosure behavior per platform.
   **Approved**: pending

6. **Decision**: Ship `transition-colors` and `transition-transform` on the trigger and chevron unconditionally, without checking `prefers-reduced-motion`.
   **Rationale**: This is acknowledged debt, not a goal: the intended behavior is **respect-reduced-motion**, and the component does not meet it today. The fix is to disable the transitions inside the component when Reduce Motion is on, not to ask consumers to patch around them with their own media-query overrides.
   **Approved**: pending

