
NavChrome provides semantic structure and class names for styling; visual appearance is the responsibility of the host CSS.

- **Classes for styling**:
  - `.lp-bar`: The fixed navigation bar containing burger and optional brand
  - `.lp-burger`: The burger menu button (also used for the close button with `.lp-drawer-close`)
  - `.lp-brand`: Optional brand/logo container
  - `.lp-drawer`: The modal navigation drawer
  - `.lp-drawer--open`: Class added to drawer when open (modifier)
  - `.lp-drawer-close`: Close button inside the drawer (inherits `.lp-burger`)
  - `.lp-scrim`: The overlay covering the page (not focusable, `aria-hidden="true"`)
  - `.lp-scrim--show`: Class added to scrim when drawer is open (modifier)
  - `.lp-nav`: Navigation anchor links inside the drawer
  - `.lp-foot`: Optional footer content container

- **CSS Custom Properties**:
  - `--lp-chrome-top`: Allows the host to offset the entire chrome (bar, scrim, drawer) below a site header; the component references this but does not set it

