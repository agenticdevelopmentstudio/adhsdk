
- **Empty or missing children**: If `children` is `null`, `undefined`, or an empty string, the link renders with no visible text. This is not an error condition; the anchor is still navigable but semantically incomplete. Parent code is responsible for ensuring meaningful link text.
- **Missing href prop**: `href` is a required prop per TypeScript. If called without `href`, the type system prevents the call. At runtime, if `href` is `undefined`, the anchor's `href` attribute is `undefined`, resulting in a non-functional link. This is a usage error.
- **Invalid variant value**: `variant` is constrained to `'primary' | 'ghost'` by TypeScript. Passing any other string value triggers a type error. At runtime, an invalid variant string produces a class name like `lp-btn--invalid`, which may not match any CSS rules and the link may lack expected styling. This is a usage error.

