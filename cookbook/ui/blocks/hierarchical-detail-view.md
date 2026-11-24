---
id: 8ce108f2-b64b-4e01-8dbb-94ef3397b46a
title: "Hierarchical Detail View"
type: ingredient
version: 1.1.2
status: review
language: en
created: 2026-09-22
modified: 2026-11-14
author: Mike Fullerton
copyright: 2026 Mike Fullerton
license: MIT
summary: "Context-driven switch between hierarchical menu and topic detail view implementations"
platforms:
  - typescript
  - web
tags:
  - layout
  - navigation
  - context
depends-on:
  - aaebd90e-991f-4133-a12d-0783586eae5a
  - 0bba1f5b-bc8d-4f76-b1c9-329b627f7ee8
related: []
references: []
approved-by: ""
approved-date: ""
---

# Hierarchical Detail View

## Overview

Hierarchical Detail View is a context provider and routing component that selects between two hierarchical detail view implementations — a cascading menu view and a classic topic view ([adhsdk.recipe.ui.blocks.hierarchical-topic-detail](cookbook:0bba1f5b-bc8d-4f76-b1c9-329b627f7ee8)) — at the application level. It allows consumers throughout the component tree to render the same logical interface with different disclosure patterns by reading a context value, rather than threading a configuration prop through multiple layers.

The component consists of three exports: a provider component that establishes the context, a hook to read the current view choice, and a router component that consumers render in place of choosing between the two implementations directly.

## Behavioral Requirements

- **context-value**: The `HierarchicalDetailViewProvider` MUST establish a React Context with the `menuDetail` boolean value provided via the `menuDetail` prop.
- **default-classic**: When no `HierarchicalDetailViewProvider` is rendered, the context MUST default to `false` (classic topic view).
- **route-to-menu-detail**: When context value is `true`, `HierarchicalDetailView` MUST render the `HierarchicalMenuDetail` component and pass all props to it.
- **route-to-topic-detail**: When context value is `false`, `HierarchicalDetailView` MUST render the `HierarchicalTopicDetail` component.
- **cascading-to-covered**: When `disclosureStyle: "cascading"` is passed and context value is `false`, `HierarchicalDetailView` MUST pass `disclosureStyle: "covered"` to `HierarchicalTopicDetail`.
- **preserve-other-props**: All props, including the cascade-only `autoHideTopics`, MUST pass through to the rendered detail view component unchanged; only `disclosureStyle: "cascading"` is rewritten, and only when context value is `false`. Whether `HierarchicalTopicDetail` ignores a prop it does not recognize is that component's own behavior, not a requirement of this router (see [adhsdk.recipe.ui.blocks.hierarchical-topic-detail](cookbook:0bba1f5b-bc8d-4f76-b1c9-329b627f7ee8)).
- **return-context-value**: The `useHierarchicalMenuDetailView()` hook MUST return the current context value (a boolean).

## Appearance

Not applicable: Hierarchical Detail View is a context provider and routing container with no visual rendering of its own. Visual appearance is determined entirely by the underlying detail view component selected.

## States

Not applicable: Hierarchical Detail View is a routing and context component with no interactive states or visual modes of its own.

## Accessibility

Not applicable: Accessibility is the responsibility of the detail view components (`HierarchicalMenuDetail` and `HierarchicalTopicDetail`) rendered by this router. This component does not introduce interactive controls or visual elements that require accessibility annotations.

## Conformance Test Vectors

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| hdv-001 | context-value | Render `HierarchicalDetailViewProvider` with `menuDetail={true}` around a component that calls `useHierarchicalMenuDetailView()`, and around `HierarchicalDetailView` | The hook returns `true`, and `HierarchicalDetailView` renders `HierarchicalMenuDetail` |
| hdv-002 | default-classic | Call `useHierarchicalMenuDetailView()` in a component with no provider, and render `HierarchicalDetailView` without a provider | The hook returns `false`, and `HierarchicalTopicDetail` renders |
| hdv-003 | route-to-menu-detail | Render `HierarchicalDetailView` with context value `true` | Renders `HierarchicalMenuDetail` component |
| hdv-004 | route-to-topic-detail | Render `HierarchicalDetailView` with context value `false` | Renders `HierarchicalTopicDetail` component |
| hdv-005 | cascading-to-covered | Pass `disclosureStyle: "cascading"` to `HierarchicalDetailView` with context value `false` | Underlying `HierarchicalTopicDetail` receives `disclosureStyle: "covered"` |
| hdv-006 | preserve-other-props | Pass `autoHideTopics={true}` to `HierarchicalDetailView` with context value `false` | Underlying `HierarchicalTopicDetail` receives `autoHideTopics` unchanged |
| hdv-007 | preserve-other-props | Pass `levels={[...]}` and `detail={{...}}` to `HierarchicalDetailView` | Underlying view component receives these props unmodified |
| hdv-008 | return-context-value | Call `useHierarchicalMenuDetailView()` inside `HierarchicalDetailViewProvider` with `menuDetail={false}` | Hook returns `false` |
| hdv-009 | preserve-other-props | Pass `disclosureStyle: "covered"` to `HierarchicalDetailView` with context value `false` | Underlying `HierarchicalTopicDetail` receives `disclosureStyle: "covered"` unchanged |
| hdv-010 | route-to-menu-detail | Pass `disclosureStyle: "cascading"` to `HierarchicalDetailView` with context value `true` | Underlying `HierarchicalMenuDetail` receives `disclosureStyle: "cascading"` unchanged |
| hdv-011 | preserve-other-props | Type-level: pass `surfaceScope="x"` to `HierarchicalDetailView` (a `@ts-expect-error` test) | The compiler rejects the prop, because `HierarchicalDetailView` takes `ComponentProps<typeof HierarchicalMenuDetail>` |
## Edge Cases

- **No provider mounted**: See #requirements/default-classic: `useHierarchicalMenuDetailView()` called without a `HierarchicalDetailViewProvider` ancestor returns `false` without error.
- **Cascading prop without cascading context**: When a consumer passes `disclosureStyle: "cascading"` while context is `false`, the component MUST map it to `disclosureStyle: "covered"` to avoid passing an invalid prop to `HierarchicalTopicDetail`.
- **autoHideTopics in topic view**: When a consumer passes `autoHideTopics` while context is `false`, the prop passes through unchanged to `HierarchicalTopicDetail` in the rest props (see **preserve-other-props**); `HierarchicalTopicDetail` ignores it as an unrecognized prop rather than erroring.
- **Prop surface tracks HierarchicalMenuDetail, not a true superset**: `HierarchicalDetailView`'s prop type is exactly `ComponentProps<typeof HierarchicalMenuDetail>`, which is not a superset of `HierarchicalTopicDetail`'s props. `HierarchicalTopicDetail`'s `surfaceScope` prop has no counterpart on `HierarchicalMenuDetail`, so passing `surfaceScope` to the router is a type error regardless of context value; every other topic-view prop that `HierarchicalMenuDetail` also declares passes through to whichever view is active, unmodified.

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `menuDetail` | `boolean` | `false` | Passed to `HierarchicalDetailViewProvider` to select the cascading menu view (`true`) or classic topic view (`false`) |
| `children` | `ReactNode` | — | Child components to render within the provider context |

`HierarchicalDetailView` itself takes `ComponentProps<typeof HierarchicalMenuDetail>`. This is not a full superset of `HierarchicalTopicDetail`'s props: `HierarchicalTopicDetail`'s `surfaceScope` prop is absent from `HierarchicalMenuDetail`, so it cannot be passed to the router at all, in either context. The props `HierarchicalMenuDetail` does declare are documented once, on `HierarchicalMenuDetail` ([adhsdk.ingredient.ui.blocks.hierarchical-menu-detail](cookbook:aaebd90e-991f-4133-a12d-0783586eae5a)), rather than restated here; see **preserve-other-props** and **cascading-to-covered** for how the router narrows that surface under the classic view.

## Deep Linking

Not applicable: Hierarchical Detail View is a context provider and routing component with no URL patterns or navigation destinations of its own. Deep linking is handled by the detail view components it routes to.

## Localization

Not applicable: Hierarchical Detail View does not render user-facing strings and introduces no localizable content.

## Accessibility Options

Not applicable: Hierarchical Detail View is a routing and context component that does not render interactive controls or visual elements that respond to accessibility display options. Accessibility concerns are delegated to the detail view components it routes to.

## Feature Flags

Not applicable: the toolkit is flag-agnostic. A host app MAY wire any boolean feature flag to the `menuDetail` prop of `HierarchicalDetailViewProvider` to enable the cascading menu view for A/B testing or gradual rollout.
## Analytics

Not applicable: Hierarchical Detail View is a routing and context component with no user interactions or events of its own. Analytics events are generated by the detail view components it selects.

## Privacy

Not applicable: Hierarchical Detail View does not collect, store, or transmit any data.

## Logging

Not applicable: Hierarchical Detail View is a routing and context component with no internal state changes, error conditions, or operations requiring logs.

## Platform Notes

- **React/Web**: Implemented in `packages/web/packages/ui/src/blocks/hierarchical-detail-view.tsx` using React Context API (`createContext`, `useContext`). The provider establishes the context value; `HierarchicalDetailView` consumes it with `useHierarchicalMenuDetailView()` and conditionally renders the two detail components. Only `disclosureStyle` is remapped within the component's render logic; every other prop, including `autoHideTopics`, passes through unchanged.
- **Compose**: Similar to React, Kotlin Compose provides a CompositionLocal API for context-like behavior. Implement a CompositionLocal to store the boolean view choice, provide it via a Composable provider function, and create a composable that reads the local to conditionally render the menu or topic detail composable. Remap only `disclosureStyle` and pass everything else through.
- **SwiftUI**: Implement using SwiftUI's EnvironmentKey protocol to create a custom environment value for the view choice boolean. Create a ViewModifier or custom modifier to provide this value to descendants. The main view reads the environment value and conditionally renders the two detail views. Remap only `disclosureStyle` and pass everything else through, via view builder logic or a separate function.
- **AppKit / UIKit**: Implement as a container view controller or custom view that receives the view choice injected by its parent — an initializer parameter, a dependency container, or an environment-style object passed down the view controller hierarchy — rather than read from `NSUserDefaults` or a singleton app state object, which would introduce the hidden global state the Context-over-props decision below rules out. Use conditional view controller/view presentation to render the appropriate detail view. Remap only `disclosureStyle` and pass everything else through, in the delegation or initialization logic.
- **WinUI 3**: Implement as a custom UserControl that reads a view choice boolean from an attached property, application resources, or a view model bound to the control. Use conditional rendering (if/else in code-behind or binding converters in XAML) to conditionally instantiate the menu detail or topic detail control and bind all props to the selected control. Remap only `disclosureStyle` via a value converter or helper method before binding props; pass every other property, including `autoHideTopics`, through unchanged.

## Reference Implementations

| Platform | Location | Conformance |
|----------|----------|-------------|
| web | `packages/web/packages/ui/src/blocks/hierarchical-detail-view.tsx` | confirmed (1.1.2) |

## Design Decisions

- **Context over props:**
  **Decision**: Configuration is read from React Context (the `menuDetail` value) rather than passed as a prop.
  **Rationale**: Many hierarchical detail stacks are rendered by internal components (ResourceExplorer, CrudDataBrowser, ApiBrowser, persona sections) several layers below application code. Threading a boolean through all intermediate layers would require changes at every call site and defeat the purpose of centralizing the choice. The context approach centralizes the decision at the provider level and makes it transparent to consumers.
  **Approved**: pending

- **Default to false:**
  **Decision**: The context defaults to `false` (classic topic view).
  **Rationale**: Existing applications that mount no provider continue to render the classic view, and the menu view is activated only by deliberately mounting a provider or wiring a feature flag. This preserves backward compatibility and keeps the toolkit flag-agnostic rather than changing behavior for existing users.
  **Approved**: pending

- **Cascading-to-covered mapping:**
  **Decision**: When a consumer passes `disclosureStyle: "cascading"` to the router component and the context is `false`, the component maps it to `disclosureStyle: "covered"`.
  **Rationale**: This graceful degradation prevents passing an invalid prop to `HierarchicalTopicDetail` and provides a reasonable fallback: the covered style borrows the cascade's rules for covering, pins, and hover reveal, so it approximates the cascade's visual behavior without the vertical step unique to the menu view. The source emits no dev-mode warning when this happens; the fallback is silent because the covered style is a deliberate approximation, and callers who need the exact cascade turn the provider on.
  **Approved**: pending

- **autoHideTopics passed through, not filtered:**
  **Decision**: The `autoHideTopics` prop is cascade-only and has no meaning in the classic topic view, but it is not filtered out — it is carried along in the destructured rest props and passed to `HierarchicalTopicDetail` unchanged.
  **Rationale**: `HierarchicalTopicDetail` ignores unknown props rather than throwing an error, so this allows consumers to pass superset props without conditional logic of their own; see **preserve-other-props**.
  **Approved**: pending

- **The router is temporary:**
  **Decision**: `HierarchicalDetailView`, its provider, and its hook exist only for the duration of the cascading-vs-classic experiment between `HierarchicalMenuDetail` and `HierarchicalTopicDetail`.
  **Rationale**: Once the experiment concludes, the losing detail-view component and this router file are deleted together; only the winning component remains, and consumers call it directly instead of going through the switch.
  **Approved**: pending

- **Three names, one switch:**
  **Decision**: The provider prop is `menuDetail`, the provider is `HierarchicalDetailViewProvider` and the hook is `useHierarchicalMenuDetailView`; the names are kept as they are.
  **Rationale**: The exports are already consumed under these names and renaming would touch every call site. `menuDetail` names the choice (the menu view), while the provider and router are named for the whole detail view they select.
  **Approved**: pending
## Compliance

| Check | Status | Category |
|-------|--------|----------|
| [adc.check.artifact-formatting.ingredient-formatting.if-frontmatter-complete](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/083aeeb8-a2fa-5fbc-a3e6-82df9a653872) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-behavioral-requirements](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/192770a1-b6b6-5782-bc29-251a8a941272) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-test-vectors](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/91ba975a-1f6a-5a85-8652-26e76cf324f4) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-design-decisions](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f5b5cbe6-22e8-5954-a18d-0362ee387941) | passed | Artifact Formatting |
| [adc.check.artifact-formatting.ingredient-formatting.if-change-history](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/14bf2d1d-875b-5e58-b43d-be492c9f941a) | passed | Artifact Formatting |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on this ingredient itself: all required frontmatter fields are present, the Behavioral Requirements use RFC 2119 keywords with subject-only kebab-case names, the Conformance Test Vectors table maps every requirement to at least one ID, Design Decisions follow the Decision/Rationale/Approved format, and the file ends with a Change History table. `separation-of-concerns` passes because `hierarchical-detail-view.tsx` is a thin switch that only picks between `HierarchicalTopicDetail` and `HierarchicalMenuDetail`, with no business logic of its own beyond that dispatch; `unit-test-coverage` passes because `hierarchicalDetailView.test.tsx` covers hdv-001 through hdv-011.

## Change History

| Version | Date | Author | Summary |
|---------|------|--------|---------|
| 1.0.0 | 2026-09-22 | Claude Haiku 4.5 | Initial creation |
| 1.1.0 | 2026-09-22 | Mike Fullerton | Lint pass: renamed requirements to subject-only kebab-case; resolved the autoHideTopics filter/pass-through contradiction between must-ignore-cascade-only-props and must-preserve-other-props; added a temporary-router design decision; reformatted design decisions to Decision/Rationale/Approved; replaced the compliance table with real Artifact Formatting checks; added depends-on references to the menu-detail and topic-detail ingredients; added two conformance test vectors; templated the feature-flag key; fixed the AppKit/UIKit platform note to avoid hidden global state; unquoted frontmatter dates |
| 1.1.1 | 2026-09-25 | Mike Fullerton | Corrected superset-prop-compatibility edge case and Configuration prop-type paragraph: HMD lacks surfaceScope, is not a true superset of HTDV props (bucket-14_2). Added best-practices compliance rows (separation-of-concerns: passed, unit-test-coverage: failed). |
| 1.1.2 | 2026-11-14 | Mike Fullerton | Merged cascade-only-props into preserve-other-props, stopped the router from requiring behavior of HierarchicalTopicDetail, recorded the naming and silent-fallback decisions, made Feature Flags not applicable, linked HierarchicalTopicDetail, corrected platform notes, and added hdv-011 plus a test-gap blocker note. |
