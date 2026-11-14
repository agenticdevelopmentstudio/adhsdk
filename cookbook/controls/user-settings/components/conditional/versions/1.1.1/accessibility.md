
Conditional does not add any accessibility features or roles itself. Content rendered within Conditional inherits the accessibility properties of the `children` and `fallback` components; because the component adds no wrapper node (**no-wrapper-element**), it MUST NOT alter the accessibility tree structure of whichever branch is rendered. Implementors SHOULD ensure that both branches meet accessibility requirements independently.

