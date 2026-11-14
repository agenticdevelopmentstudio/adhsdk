
Not applicable — this is a headless DOM-mutation effect with no rendered
surface, corner radius, padding, or font of its own; it writes inline
`transform`/`color`/`filter` styles onto character spans the caller already
rendered (see **scale-formula**, **blur-floor**, and **colour-interpolation**
under Behavioral Requirements for the exact values it writes).

