
Theme `name` strings such as "Charcoal" and "Terminal Split" are proper-noun labels copied verbatim from the web manifest and are held as English literals, not routed through a string catalogue; the file contains no other user-facing text. That is why `no-hardcoded-strings` is `partial` in Compliance: the names are proper nouns that are not translated, but a host that wants translated names has no catalogue to supply them from.

