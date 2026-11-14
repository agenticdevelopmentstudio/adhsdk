
The container draws no chrome of its own beyond four surfaces; every other visible element (`FieldGroup`, `BoundField`, `ButtonBar`, `AlertModal`) is a shared component from
`@adh-sdk/ui` with its own recipe. The four surfaces are the layout-fault alert block (red-bordered, monospaced, `role="alert"`, above the sections), the form-level `validate` message and the save-error line (red, monospaced, `role="alert"`, below the sections), the optional section description line (dim, monospaced), and the danger-zone styling, which colors a `dangerZone` section's title and border red.
