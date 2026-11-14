
- **Null or empty children**: When children is `null`, `undefined`, or an empty array, the component MUST render the wrapper div with the theme applied. The wrapper div renders but contains no child content. See palette-009.
- **No themeId provided**: When no `themeId` prop is supplied, the component MUST use the `DEFAULT_THEME_ID` constant from the themes registry. See palette-007.
- **Invalid themeId**: When a `themeId` is provided but does not match any entry in the themes registry, the component renders whatever theme `getThemeById` returns, using that theme's data attributes and palette (**theme-data-attributes**, **theme-palette-style**). The fallback to the `DEFAULT_THEME_ID` theme is the registry's behavior, specified in the markdown core ingredient ([adhsdk.ingredient.markdown.core](cookbook:9f938c20-ea6e-42d7-9ddf-9531a96e3ad0)). See palette-010.
- **Empty or whitespace-only className**: When `className` is an empty string or contains only whitespace, the rendered wrapper element's `class` attribute MUST be exactly `adh-mv-content`. See palette-011.
- **Multiple class names in className prop**: When `className` contains multiple classes (e.g., `"border rounded-lg shadow"`), all classes MUST be preserved in the merged output. See palette-005.

