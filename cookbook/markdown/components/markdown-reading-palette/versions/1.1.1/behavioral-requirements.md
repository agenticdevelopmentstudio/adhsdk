
- **render-children**: Component MUST render `children` prop without modification or transformation.
- **theme-data-attributes**: Component MUST set `data-mdv-theme` attribute to the theme's ID and `data-mdv-shiki-variant` attribute to the theme's syntax highlighting variant.
- **theme-palette-style**: Component MUST apply the theme's color palette as inline CSS custom properties via the `style` prop.
- **content-class**: Component MUST apply the `adh-mv-content` class to the wrapper element. This class provides load-bearing styles for background color, text color, padding, and overflow behavior that enable markdown content to be readable within its host context.
- **classname-merge**: Component MUST merge the `className` prop with `adh-mv-content` using the `cn` utility function, preserving both the theme-driven layout classes and any caller-supplied layout classes (e.g., sizing, borders, rounding).
- **theme-id-prop**: Component SHOULD accept an optional `themeId` prop. When provided, the component MUST use that theme ID; when omitted, the component MUST default to `DEFAULT_THEME_ID`.
- **data-slot-forwarding**: Component SHOULD accept an optional `data-slot` prop to enable callers to set a DOM identity marker for testing, styling, or selection purposes. When provided, this prop MUST be forwarded directly to the wrapper element's `data-slot` attribute.
- **server-safe**: Component MUST be server-safe, with no React hooks, no client-only APIs (e.g., browser globals, event handlers), and no "use client" directive. The component MUST be compatible with async React Server Components.

