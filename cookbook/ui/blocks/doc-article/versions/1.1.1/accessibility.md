
- **Semantic element selection**: The `as` prop allows the host to choose semantically appropriate elements (`article` for standalone documents, `div` for document fragments, `section` for sections within larger pages). This choice directly affects accessibility announcements and document structure.
- **Heading navigation**: The HTML the host supplies MUST use correctly nested heading levels (`<h1>`–`<h6>`). This is a host responsibility, not something DocArticle can enforce — headings are ordinary elements inside the rendered HTML, and screen readers announce them based on standard heading semantics the host's markup provides.
- **Scroll offset for anchor navigation**: The scroll offset ensures that when an anchor link jumps a page to a heading, the heading is not obscured by fixed navigation bars above, preserving readability and accessibility for keyboard and screen reader users.
- **Code block clarity**: Removal of pseudo-content from code blocks ensures screen reader announcements of code are accurate and not cluttered with generated content.
- **Link semantics**: Links within the rendered HTML MUST be properly marked and MUST be navigable via keyboard and assistive technology. This is a host responsibility — DocArticle renders whatever anchor markup the HTML string contains.
- **Image alternatives**: Any images in the rendered HTML MUST have alt text. This is a host responsibility — DocArticle does not inspect or modify the HTML it renders.
- **Color contrast**: The prose classes inherit text and background colors from the document's theme; the host is responsible for ensuring color contrast meets WCAG standards.
- **Resize text**: Text and spacing within prose rendering SHOULD scale appropriately if the user enlarges text via browser or OS settings (inherited from prose classes and browser rendering).

