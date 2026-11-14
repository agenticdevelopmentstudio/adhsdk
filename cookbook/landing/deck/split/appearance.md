
- **Layout**: CSS Grid — single column (stacked, top-to-bottom) below `62rem` (992px); two-column grid (`minmax(0, 5fr) minmax(0, 6fr)`) at and above it
- **Container**: `display: grid` (a single layout model; see Design Decisions and Platform Notes)
- **Breakpoint**: `62rem` is the authority; `992px` is its value only at the browser's default 16px root font size, and a reader who has raised the default font size gets the two-column layout at a proportionally wider viewport. Native ports match `62rem`, not a fixed `992`. Defined in `packages/web/packages/landing/src/css/base.css`
- **Gap**: `2rem` below the breakpoint, `3rem` at and above it
- **Padding**: Inherited from component nesting and layout context
- **Background**: Transparent (inherits from parent)
- **Foreground/Text**: Inherits from child elements
- **Border**: None by default
- **Shadow**: None by default
- **Min/Max size**: No explicit constraints; see `#edge-cases/very-wide-viewports`

