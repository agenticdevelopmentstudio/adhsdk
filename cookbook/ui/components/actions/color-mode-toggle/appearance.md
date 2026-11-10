
- **Icon size**: 20×20px (`1.25rem`, set by the `.adh-color-mode-toggle > svg` CSS rule) for the Sun and Moon icons; size is controlled by CSS `width`/`height`, not by `strokeWidth`.
- **Stroke width**: 2 for Sun/Moon, 3 for the RefreshCw badge — a thicker line keeps the smaller badge glyph legible.
- **Auto-mode badge**: RefreshCw renders as a 10×10px (`0.625rem`) corner overlay, absolutely positioned at the bottom-right of the button and colored `var(--color-accent)`. It is shown only when `data-color-mode="auto"` is present on `<html>`, layered on top of whichever of Sun/Moon is currently visible; otherwise it is hidden.
- **Color**: Icons inherit the text color of the button's scope; determined by CSS based on `data-color-mode` or `.dark` class on document root
- **Padding**: None — component is a bare icon button with no internal spacing
- **Background**: None by default — host application supplies button styling via className
- **Border**: None by default
- **Corner radius**: None
- **Shadow**: None
- **Visibility logic**: CSS rules (`.adh-color-mode-toggle__*` selectors, in `styles/components.css`) determine which icon is visible based on the `data-color-mode` attribute on `<html>` and presence of `.dark` class. That stylesheet is a required runtime dependency — see Design Decisions.

