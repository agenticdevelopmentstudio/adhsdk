
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| model | MailBrowserModel | required | The shared model whose open message the reader shows; given at construction. |
| externalSchemes | Set of String | `http`, `https`, `mailto` | The link schemes allowed to open outside the reader. |
| blockRemotePolicy | String | the policy in blocking-policy-prefix | The Content-Security-Policy meta tag that starts a blocked document. |
| rule-list identifier | String | "mail-reader-block-remote" | The name the compiled content rule list is stored under. |

