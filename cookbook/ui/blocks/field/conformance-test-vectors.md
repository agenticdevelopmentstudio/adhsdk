
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-caption, associate-label-implicitly | `<Field label="Name"><input/></Field>` | One `<label>` wraps an uppercase-mono "Name" caption and the input; clicking the caption focuses the input |
| T2 | render-control | `children` is an `<Input/>` | The input renders between the caption and any supporting line |
| T3 | show-hint-when-no-error | `hint="Shown to teammates"`, no `error` | A dim-mono hint line renders below the control |
| T4 | show-error-in-place-of-hint | `hint="…"` AND `error="Required"` | A red-mono "Required" renders; the hint is absent |
| T5 | omit-supporting-line-when-empty | neither `hint` nor `error` | No supporting line renders below the control |
| T6 | merge-classname | `className="mt-4"` | Root keeps `flex flex-col …` and adds `mt-4` |
| T7 | render-inline-layout | `<Field label="Name" layout="inline"><input/></Field>` inside a wrapper setting `--apt-field-label-w` (for example via `FIELD_LABEL_GROUP_CLASS`, which sets it to `6.5rem`) | Root renders as `grid grid-cols-[…]`; column 1 takes its width from `--apt-field-label-w`; the caption is right-aligned in column 1; the control and the supporting line both render in column 2 |
| T8 | name-error-line | `<Field label="Name" errorId="name-error" error="Required"><input/></Field>` | The rendered error `<span>` has `id="name-error"`; when only `hint` is set instead, the hint `<span>` receives no `id` |
| T9 | name-error-line | `<Field label="Name" errorId="name-error" hint="Shown to teammates"><input/></Field>` (no `error`) | No element in the field has `id="name-error"` |
| T10 | uppercase-caption-locale | `<Field label="straße">` (or Turkish `i`) rendered under a document or ancestor with the matching `lang` | The caption is uppercased by the locale's rules, via CSS `text-transform`, not by an invariant uppercase call |
| T11 | no-disabled-dimming | `<Field label="Name"><input disabled/></Field>` | `Field` adds no opacity or dimming class of its own; the control's own disabled styling is the only change |
