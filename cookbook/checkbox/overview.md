
A controlled checkbox input component available in two visual modes: checkbox or switch toggle. The component supports optional label and hint text, disabled state, and keyboard focus management. Built for use in forms where binary (true/false) choices are needed.

The recipe covers two source files that together make up "Checkbox": the form-field **wrapper** (`packages/web/packages/controls/src/user-settings/components/Checkbox.tsx`), which owns `value`/`onChange`, label/hint, and DOM association; and the styled **primitive** (`packages/web/packages/ui/src/components/checkbox.tsx`), a thin skin over `@base-ui/react/checkbox` that owns the visual indicator, focus ring, and `checked`/`onCheckedChange`/`defaultChecked`. Every requirement, appearance note, configuration option, and test vector below is tagged with the layer (Wrapper or Primitive) it describes, since the two components have distinct props and do not share an API.

