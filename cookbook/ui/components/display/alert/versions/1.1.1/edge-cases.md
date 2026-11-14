
- **Null and empty input**: `<Alert />` with no children MUST render an
  empty, bordered/padded `<div role="alert">` without throwing — `children`
  is not required by `React.ComponentProps<"div">`. `variant={undefined}`
  MUST behave identically to omitting the prop (falls back to `default`
  per **default-variant**).
- **Boundary values**: A `variant` value outside the five accepted
  literals (only reachable by bypassing the `VariantProps` TypeScript
  type, e.g. from untyped/unchecked data): `class-variance-authority`'s
  lookup finds no match for an unrecognized key, so it omits that
  variant's entire class string — border, background, foreground, and
  icon-color classes all drop out together — while the shared base classes
  (layout, padding, corner radius, text size) still apply. It does NOT
  fall back to the `default` variant's classes: `defaultVariants: {
  variant: "default" }` only substitutes when `variant` is omitted or
  `undefined`, not when it is set to an invalid value. See
  #test-vectors/alert-021.
- **Concurrent access**: Not applicable. `Alert`, `AlertTitle`, and
  `AlertDescription` are stateless, side-effect-free function components
  with no internal state, refs, or shared mutable resources.
- **Error states**: Alert performs no fallible operation (no network
  call, no parsing, no file/database I/O) and contains no `try`/`catch` or
  error-boundary logic. Any rendering failure surfaces as a standard React
  rendering error, not Alert-specific behavior.
- **Offline or disconnected state**: Not applicable. Alert performs no
  network communication.
- **Attribute-override quirk**: If a caller explicitly passes a `role` or
  `data-slot` prop, that value overrides the component's own
  `role="alert"` / `data-slot="alert"` attributes, because `{...props}` is
  spread in JSX after those two attributes on the root `<div>` — JSX's
  last-attribute-wins rule applies, so the default can be silently
  replaced. See #test-vectors/alert-019.
- **Icon detection is structural, not type-based**: See Design Decisions
  > Icon detection via CSS `:has()`, not an icon prop.

