
`StenographerWire` defines the JSON spelling a request body or reply takes between `steno`, the daemon and the app: snake_case keys and ISO-8601 dates. It is one definition, so the three ends of a relayed request cannot drift into three dialects; a `Date` added to a DTO decodes the same everywhere it travels.

It is a caseless enum with two factory functions. Each call returns a new `JSONEncoder` or `JSONDecoder` configured with the two strategies. The HTTP client and the app's preference push use it; the one deliberate exception is the provider registry push, which uses a default encoder (see the HTTP client recipe, [adhsdk.ingredient.foundation.stenographer.stenographer-http-client](cookbook:9c7c78d3-23ca-4ca6-a519-9968b440b8c6)).

