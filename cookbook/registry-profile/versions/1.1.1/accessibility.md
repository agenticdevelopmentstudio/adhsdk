
- **Role**: The root element is an `<article>`, which defines the profile as a standalone, self-contained piece of content.
- **Heading structure**: The display name is an `<h1>`, which provides proper document structure.
- **Photo alt text**: The photo `alt` attribute is an empty string, signaling to assistive technology that it is decorative; the `<h1>` provides the identity.
- **Metadata structure**: The metadata (category, location, languages) is rendered in a description list (`<dl>`), providing semantic structure for screen readers.
- **Links section**: The links navigation has `aria-label="Elsewhere"` to describe the section purpose to assistive technology users.
- **Field labels**: Each field is rendered with a `<dt>` label paired with a `<dd>` value in a definition list, providing semantic structure.
- **Visibility markers**: Visibility markers are inline in the field label, ensuring users encounter the visibility restriction immediately when they reach the field.
- **Field values**: `FieldValue` renders each value by type: `url` as an `<a>` with `rel="noopener noreferrer nofollow"` and `target="_blank"`, `image` as an `<img>` whose `alt` is the field label, and every other type (text, textarea, markdown, date, select, multi_select, boolean, address, email, phone) as text content. The `<dt>` label supplies the accessible name for each `<dd>` value. See [adhsdk.ingredient.registry-profile.field-value](cookbook:6579e030-0455-453c-81cf-177dae3dd82e).
- **Services**: `ServiceList` is a static section headed by an `<h2>` ("Services") with one `<h3>` per service, continuing the heading hierarchy under the profile's `<h1>`. It has no interactive elements, so there is nothing to reach by keyboard. See [adhsdk.ingredient.registry-profile.service-list](cookbook:fe09968a-6575-40d0-b0b8-af6ce52d8efd).
- **Touch targets**: The only interactive elements are inline text links (the "Elsewhere" links and `url` field values). Inline links within text are exempt from the WCAG 2.5.8 minimum target size; the profile adds no buttons or controls.

