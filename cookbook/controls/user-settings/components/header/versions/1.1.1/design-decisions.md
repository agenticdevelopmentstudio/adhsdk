
1. **Decision**: The component renders `<h2>` rather than a generic `<div>`, with the heading level fixed rather than configurable.
**Rationale**: A fixed level-2 heading ensures proper document outline and accessibility for the component's intended use inside `user-settings` sections, which sit at a single, known depth in the page outline (see [adhsdk.ingredient.ui.settings.settings-panel](cookbook:432e8d4b-43c3-49fd-b481-036a759e7c55)). Consumers who need a different heading level should wrap the content or use a different component rather than parameterize this one.
**Approved**: pending

2. **Decision**: The component always includes the `aws-header` class as a fixed, non-removable default identity class.
**Rationale**: `aws-header` represents the component's identity and gives every instance a consistent styling baseline; additional classes are composed alongside it (see #requirements/class-composition) so consumers can customize without losing the base style.
**Approved**: pending

3. **Decision**: Class composition uses a simple array-filter-and-join pattern (`['aws-header', className].filter(Boolean).join(' ')`) rather than conditional rendering or a CSS-in-JS library.
**Rationale**: This keeps the component lightweight and compatible with plain CSS, CSS Modules, and other styling systems. The filter step prevents double spaces when `className` is falsy (see #requirements/class-composition).
**Approved**: pending

4. **Decision**: Children accept any ReactNode.
**Rationale**: `HeaderProps` defines `children?: ReactNode`, which permits any React-renderable content — fragments, components, or strings — without type checking (see #requirements/children-content). This flexibility allows the component to be used in many contexts without modification.
**Approved**: pending

