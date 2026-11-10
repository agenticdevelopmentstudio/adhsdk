
- **Empty status string**: Status label renders as empty; tooltip is nil (see **hover-tooltip**); trailing accessories have the full trailing slot width available since the minimum gap (**minimum-gap**) applies only when both status text and accessories are present.
- **Very long status string**: Text is truncated by middle (**middle-truncation**); the full string remains available via tooltip on pointer platforms and via the accessible label (**full-text-accessible-label**) on all platforms; no horizontal scroll occurs.
- **Empty trailing accessories array**: Trailing slot is empty; no layout errors occur; status label can expand to available width.
- **Rapid status updates**: Status text and tooltip update without layout thrashing; component remains at fixed 22pt height.
- **Trailing accessories with varying heights**: All accessories center-aligned vertically to bar center (**trailing-vertical-centering**); no clipping or overflow.
- **Accessory replacement**: Existing accessories removed from the view hierarchy and replaced with the new array; no memory leaks or dangling views.
- **Long accessory list**: Accessories squeeze toward the trailing edge; 6pt spacing (**trailing-spacing**) maintained; minimum gap (**minimum-gap**, 8pt) from status preserved until width is exhausted.
- **Large system text size**: Bar height remains fixed at 22pt (`WindowFooterBar.height` is a constant, not derived from font metrics); at very large caption text sizes (Dynamic Type or a platform text scale) the status label's text may be vertically clipped rather than the bar growing to fit it.

