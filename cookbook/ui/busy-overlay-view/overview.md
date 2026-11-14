
The busy overlay is a layer laid over a whole host view while something the
host shows is being changed. It draws a blurred ground, a spinner, and an
optional single line saying what is happening, and it lets no pointer input
through to the controls beneath.

It is the counterpart of the Dismissible Overlay View with the opposite
manners. That overlay goes away on any press or on Escape. This one goes
away only when its owner calls `hide()`, because what it covers is about to
be redrawn and a click landing on the old layout would act on a row that is
moving. It blends in and out over the Dismissible Overlay View's
`fadeDuration` (0.2 seconds) so the two read as the same kind of surface.

