
ToggleGroup does not implement dedicated Reduce Motion, Increase Contrast, or Differentiate
Without Color handling of its own. The rest/hover/pressed treatments in the source
(`hover:text-apt-text`, `data-[pressed]:bg-apt-gold`, `transition-colors`) are plain color and
transition utilities with no `prefers-reduced-motion` or `forced-colors` media query, so their
behavior under those OS settings is whatever the browser applies by default, not an
accommodation Base UI or the component makes.

