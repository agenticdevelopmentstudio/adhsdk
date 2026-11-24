
| ID | Requirements | Input | Expected |
|---|---|---|---|
| T1 | render-caption, associate-label-implicitly | `<Field label="Name"><input/></Field>` | One `<label>` wraps an uppercase-mono "Name" caption and the input; clicking the caption focuses the input |
| T2 | render-control | `children` is an `<Input/>` | The input renders between the caption and any supporting line |
| T3 | show-hint-when-no-error | `hint="Shown to teammates"`, no `error` | A dim-mono hint line renders below the control |
| T4 | show-error-in-place-of-hint | `hint="…"` AND `error="Required"` | A red-mono "Required" renders; the hint is absent |
| T5 | omit-supporting-line-when-empty | neither `hint` nor `error` | No supporting line renders below the control |
| T6 | merge-classname | `className="mt-4"` | Root keeps `flex flex-col …` and adds `mt-4` |
| T7 | render-inline-layout | `<Field label="Name" layout="inline"><input/></Field>` inside a wrapper setting `--apt-field-label-w` | Root renders as `grid grid-cols-[…]`; the caption is right-aligned in column 1; the control and the supporting line both render in column 2 |
| T8 | name-error-line | `<Field label="Name" errorId="name-error" error="Required"><input/></Field>` | The rendered error `<span>` has `id="name-error"`; when only `hint` is set instead, the hint `<span>` receives no `id` |

