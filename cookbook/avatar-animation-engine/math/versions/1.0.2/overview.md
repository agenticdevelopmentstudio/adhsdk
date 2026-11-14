
Avatar Engine Math is the numeric core shared by the Swift and TypeScript
avatar animation engines: four independent modules — `Color`, `Ease`, `Mat`,
and `Prng` — with no visual surface of their own. `Color` converts between
hex strings and OKLab for perceptual color mixing (`Color.swift`,
`color.ts`). `Ease` resolves a closed, GSAP-numerically-matching vocabulary of
24 named easing curves (`Ease.swift`, `ease.ts`). `Mat` composes 2x3 affine
transforms for the scene graph (`Mat.swift`, `mat.ts`). `Prng` is a seeded
xoshiro128** generator that both platforms must draw identically from
(`Prng.swift`, `prng.ts`). All four are pure, side-effect-free, and specified
down to the integer operation so that a Swift build and a TypeScript build
given the same inputs produce bit-for-bit (PRNG) or golden-tolerance (color,
easing, matrices) identical outputs.

