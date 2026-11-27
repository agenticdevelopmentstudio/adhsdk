
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| The site roster | list of site definitions | fixed at build time | The whole family roster; not caller-configurable at runtime, a new site is added by editing the registry (its mechanically generated region for the mechanically-added fields, or the hand-authored part directly). |
| The hostname (environment detection, the cross-site URL builder, the persona profile URL builder) | string | caller-supplied; the persona profile URL builder defaults to the current environment's hostname when available, else an empty string | The current request/browser host, used to resolve which deploy environment and, for local dev, which suite the caller is on. |
| The current hostname / path (cross-site link construction) | string | caller-supplied; required | The visitor's current host and path, used to resolve the target site's href in the same environment and to decide whether `/home` is carried. |
| `NEXT_PUBLIC_LOCAL_SITES` (environment variable) | comma-separated list of site identifiers | unset, meaning every site is served locally | The site identifiers the local server actually runs; a local hop to any other site resolves to its production host. |
| The recognized local suite domains | fixed list of strings (internal constant) | `['sites.localhost', 'dev.test', 'dev.local']` | The domain suffixes recognized as a local-suite host; not caller-configurable. |
| The environment (the OAuth return-origin allowlist) | one of `'production'`, `'staging'`, `'testing'` | caller-supplied; required | Which deploy environment's OAuth-return-origin allowlist to compute. |
| The build configuration table | optional build configuration entry per site identifier | fixed at build time | Per-site build behavior flags read by the shared build-configuration package; not caller-configurable at runtime. |

| A site's `wildcardHost` (site definition field) | host pattern string, `*.<domain>` | absent, meaning a single-host site | Marks a wildcard site, one app serving every `<handle>.<domain>` host (today only `product-sites`, `*.agenticdeveloperhub.com`). Its env hosts put the env after the `*.`, its `prodHost` becomes only its folder's name, and every single-URL helper refuses it, the SEO helpers' `siteIdentity` included. |
