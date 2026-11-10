
Rule renders a semantic definition list (`<dl>`) of term-detail pairs. Each pair consists of a term (the label) and a detail (the explanation). The component accepts an array of step objects and renders them in order, delegating all visual styling to CSS. Use this component to display structured textual content such as oversight rules, definitions, guidelines, or any term-definition pattern. Rule SHOULD NOT be used to caption a screenshot or other captured image of a UI; it exists to present genuine text set in the package's own typeface when a feature's UI has not been captured yet.

The name comes from the source component (`Rule.tsx`) and its use for displaying oversight rules; it does not refer to a horizontal rule (`<hr>`). The `steps` prop holds an array of term/detail pairs — independent clauses, not necessarily sequential steps — that render in the order given but carry no required order of their own.

