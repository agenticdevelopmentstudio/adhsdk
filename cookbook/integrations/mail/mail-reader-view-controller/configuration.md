
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| model | MailBrowserModel | required | The shared model whose open message the reader shows; given at construction. |

Internal constants, not configurable: the external link schemes (`http`, `https`, `mailto`), the blocking policy text from blocking-policy-prefix, and the rule list identifier "mail-reader-block-remote" are fixed in the source (`externalSchemes` is a static constant); an implementation MUST NOT expose them as settings.
