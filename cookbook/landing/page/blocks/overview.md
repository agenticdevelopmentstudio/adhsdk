
This module is what every landing page layout shares: how one block of page data becomes a rendered component, and which rows the section index lists. The snap deck and the continuous flow both call it, so a block cannot render one way in a deck and another way in a flow. It exports three functions, `prose`, `renderBlock` and `indexRows`.

`renderBlock` takes one `LandingBlock` and returns the kit component for its `kind`: Lede, Trust, Cards (with Card children), Points, Code, Shot, Table, StatusPill, Rule, Stats, Versus, Chips, Checklist, Faq, Closer, Cta (with Btn children) or Roadmap. `prose` turns a list of paragraphs into `<p>` elements, because the kit styles a block body through its paragraph child. `indexRows` returns one link row per page section.

Every block it renders is a server component, and the module sits behind the server-safe barrel (a build check asserts the built `dist/index.js` stays free of the client-component directive). It holds no state and does no I/O.

