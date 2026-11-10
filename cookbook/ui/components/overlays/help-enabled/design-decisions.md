
**Horizontal inline layout with gap**

**Decision**: The component uses `inline-flex items-center gap-1` to position the badge adjacent to the text without adding extra line height or block layout.
**Rationale**: This keeps the help affordance compact and preserves the caller's line metrics.
**Approved**: pending

**Badge transparency by default**

**Decision**: The Info badge is rendered but fully transparent (`opacity-0`) so that its presence does not reflow the layout when invisible; revealing it on hover/focus is a smooth transition without layout shift.
**Rationale**: A badge that mounts/unmounts on hover would shift surrounding layout; keeping it always mounted and only changing its opacity avoids that.
**Approved**: pending

**Warning throttling by id, not per-render**

**Decision**: Missing help entries emit a warning once per unique `id` per session (not per render).
**Rationale**: The component may be rendered multiple times on the same page, and per-render warnings would produce console noise without additional value.
**Approved**: pending

**Fallback as HelpEntry, not plain text**

**Decision**: When a fallback string is provided, it is wrapped in a HelpEntry object with flavor `"info"` so that it flows through the same rendering pipeline as stored entries.
**Rationale**: This keeps the implementation simple and consistent — one rendering path for both stored and fallback content.
**Approved**: pending

**Preserve className on plain text variant**

**Decision**: When help is not available and no fallback is provided, the component preserves the caller's `className` on the plain text span.
**Rationale**: Caller-specific layout styles (e.g., centering, ellipsis clipping) must not be lost due to the missing help entry.
**Approved**: pending

**data-slot attributes for variant detection**

**Decision**: The component applies `data-slot="help-enabled"` and `data-slot="help-enabled-plain"` to distinguish interactive and plain text variants in CSS and for testing.
**Rationale**: This avoids requiring pseudo-class selectors or attribute mutations to detect state.
**Approved**: pending

**Focus ring uses gold token**

**Decision**: The focus indicator uses `ring-apt-gold/40` (gold at 40% opacity) for consistency with other interactive controls in the design system (the `quietControlClass` pattern).
**Rationale**: This token is shared with chevrons, split dividers, dialog close buttons, and collapse toggles, so keyboard focus reads the same way across the family.
**Approved**: pending

**Badge contrast not guaranteed**

**Decision**: The Info badge's hover/focus/open opacity (`opacity-70`) is not verified against every possible caller-supplied background; contrast sufficiency is left to the design system's color tokens (`apt-surface-2`, `apt-gold/40`) rather than guaranteed by this component.
**Rationale**: HelpEnabled is a layout/behavior wrapper, not a color-token owner; enforcing contrast for arbitrary backgrounds would require knowledge of the surrounding page that this component does not have.
**Approved**: pending

