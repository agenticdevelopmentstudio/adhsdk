
The set holds provider credentials (PostHog, GlitchTip and Vercel tokens) from `config.credentials` and passes them to the section loaders; it never returns them, and it sends them only to those providers' APIs. Per-site traffic and issue titles it returns are operator-only data, gated by the routes.

