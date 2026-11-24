
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| doc-article-001 | html-prop | `html="<p>Hello world</p>"` | Component renders without error; paragraph is displayed |
| doc-article-002 | unescaped-html-rendering | `html="<strong>Bold text</strong>"` | Text appears bold in the rendered output (HTML is not escaped) |
| doc-article-003 | prose-typography | `html="<h1>Heading</h1><p>Body</p>"` | Heading and paragraph receive prose typography styling |
| doc-article-004 | default-article-element | `html="<p>Content</p>"` (no `as` prop) | Component renders as `<article>` element in the DOM |
| doc-article-005 | semantic-element-selection | `as="div"` with `html="<p>Content</p>"` | Component renders as `<div>` element |
| doc-article-006 | semantic-element-selection | `as="section"` with `html="<p>Content</p>"` | Component renders as `<section>` element |
| doc-article-007 | attribute-passthrough | `id="doc-1" data-test="value"` with `html="<p>Test</p>"` | Attributes are present on the rendered element |
| doc-article-008 | class-name-override | `className="custom-class"` with `html="<p>Test</p>"` | Component has both prose class and custom class applied |
| doc-article-009 | heading-scroll-offset | `html="<h2>Section</h2>"` | Heading has `scroll-margin-top: 5rem` applied |
| doc-article-010 | code-pseudo-content-removal | `html="<code>const x = 1;</code><pre><code>const y = 2;</code></pre>"` | Both the inline `<code>` and the `<pre><code>` block have computed `::before` and `::after` `content` of `none` |
| doc-article-011 | children-prop-excluded | `children="Ignored"` with `html="<p>From HTML</p>"` | `children` is excluded from the props type at compile time, so this requires a type-system bypass to construct at all. Forced through at runtime, `children` lands in `...rest` and is spread onto the element alongside `dangerouslySetInnerHTML`; React throws "Can only set one of `children` or `props.dangerouslySetInnerHTML`." and nothing renders — the component fails fast rather than silently ignoring `children` |
| doc-article-012 | html-prop | `html=""` | Component renders the element with no content and no error |
| doc-article-013 | semantic-element-selection | `as="span"` (an unsupported value) | TypeScript rejects the value at compile time; runtime behavior for a value outside `article`, `div` and `section` is unspecified |
| doc-article-015 | class-name-override, heading-scroll-offset | `className="prose-headings:scroll-mt-10"` with `html="<h2>Section</h2>"` | Heading has `scroll-margin-top: 2.5rem`; the override replaces the default `scroll-mt-20` while the prose class stays applied |
| doc-article-014 | unescaped-html-rendering | `html='<img src="x" onerror="handler()">'` | The `onerror` handler fires: inline event-handler attributes execute when the browser parses HTML inserted this way, unlike `<script>` content. Hosts MUST NOT pass untrusted HTML to this component without sanitizing it first |

Vectors doc-article-009, doc-article-010 and doc-article-015 assert computed style only in a test environment where the compiled Tailwind CSS is loaded; without that stylesheet, assert the presence of the prose typography classes on the element instead of the computed style. Vector doc-article-011 needs a `@ts-expect-error` (or equivalent) comment to pass a `children` prop past the type system, since `Omit` excludes it at compile time; expect the render itself (`renderToString` or `createRoot().render`) to throw rather than to succeed with `children` dropped. Vector doc-article-013 asserts only the compile-time rejection.

