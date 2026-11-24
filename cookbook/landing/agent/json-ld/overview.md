
JSON-LD is a pair of helpers that publish a page's structured data for search engines and answer engines. `JsonLd` renders one `<script type="application/ld+json">` element holding a schema.org document, and escapes `<` so no string in the data can close the element. `withWebSite` builds that document: it takes a site's name, URL and description plus any entities the page already has, and returns one `{ "@context", "@graph" }` document with a `WebSite` entity added unless one is already present. The data type, `JsonLdValue`, is a plain record of string keys to unknown values.

