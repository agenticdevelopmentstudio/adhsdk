
- **dangerouslySetInnerHTML over children**
  **Decision**: The component renders host-supplied HTML directly rather than accepting pre-rendered React elements as children.
  **Rationale**: The host needs to control the exact HTML string (for build-time markdown rendering, external content sources, etc.). This design pushes the responsibility for sanitization and trust onto the host, which is appropriate for build-time rendered content.
  **Approved**: pending

- **Scroll margin on headings**
  **Decision**: A scroll offset (5rem / 80px) is applied to headings.
  **Rationale**: The offset accounts for fixed navigation or header UI that may be present above the document, so anchor links to headings do not disappear under fixed UI. The 5rem value is a cross-platform default; hosts MAY override this via the `className` prop if their layout requires a different offset.
  **Approved**: pending

- **Removal of code pseudo-content**
  **Decision**: Pseudo-elements are stripped from code blocks (see **code-pseudo-content-removal**).
  **Rationale**: Tailwind Typography's own `code::before`/`::after` rules add quote glyphs around inline and block code by default. Removing them ensures clean code block rendering and accurate screen reader announcements.
  **Approved**: pending

- **No direct support for HTML sanitization**
  **Decision**: The component does not sanitize or validate the `html` prop.
  **Rationale**: The host MUST trust the HTML source and sanitize it before passing it to DocArticle. For user-submitted content, the host MUST use a sanitization library (e.g., `sanitize-html`, `DOMPurify`) before rendering.
  **Approved**: pending

- **HTMLAttributes spread**
  **Decision**: The component forwards standard HTML attributes to hosts via `Omit<HTMLAttributes<HTMLElement>, "children" | "dangerouslySetInnerHTML">`.
  **Rationale**: This allows hosts to pass arbitrary HTML attributes (id, data-* attributes, aria-* attributes) while explicitly blocking misuse of `children` and the HTML-rendering mechanism.
  **Approved**: pending

