
Not applicable — this is a logic container with no rendered surface of its
own; the accessibility contract belongs to the shared controls it composes
(`FieldGroup`, `BoundField`'s underlying `Input`/`Textarea`/`Select`/
`Checkbox`, `ButtonBar`, `AlertModal`, `UnsavedChangesGuard`), each with its
own recipe. The one accessibility-relevant behavior this package itself adds
is `aria-invalid` toggling on a failing control, captured under
`error-replaces-hint` above.

