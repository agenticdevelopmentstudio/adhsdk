
- **Container element**: `div` with class `lp-cta`
- **Layout**: Horizontal flex row (`display: flex`); children wrap onto additional rows via `flex-wrap: wrap` when they exceed the available width; `justify-content: center` centers the children on each row; `gap: 0.75rem` (~12px, assuming a 16px root) separates children. The axis never switches to vertical — there is no breakpoint that stacks children.
- **Background**: Transparent (no background declared on `.lp-cta`)
- **Padding**: None (`.lp-cta` declares no padding or margin)
- **Border**: None (container only)
- **Shadow**: None (container only)

