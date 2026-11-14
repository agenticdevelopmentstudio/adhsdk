
**Decision**: A translucent color is composited over its backdrop before contrast is measured, and `contrastRatio` does not check alpha.
**Rationale**: The source comments say a translucent color has no luminance or contrast on its own, only against what is behind it; the precondition is documented rather than enforced, and `ChatRoleDerivationTests` composites before measuring.
**Approved**: pending

**Decision**: `desaturated(by:)` uses Rec. 601 luma over encoded components, not `relativeLuminance`.
**Rationale**: The source comment explains that linear-light luminance fed into a display-encoded channel would darken every color it touched; luma keeps a phosphor green and its grey equally bright. `IdleStatusInkTests` pins this.
**Approved**: pending

**Decision**: `dimmed(towards:by:minContrast:)` steps down by 0.05 and falls back to `self` instead of solving for the exact amount or throwing.
**Rationale**: A coarse search is enough for text tones and always terminates; the caller gets legible text or the original color, never an error. The result can still be below `minContrast` when `self` already is.
**Approved**: pending

**Decision**: `relativeLuminance` linearizes with the threshold 0.03928.
**Rationale**: This is the value in the original WCAG 2.0 text; the current sRGB standard uses 0.04045. The source does not say why it chose one, so a port that must match its numbers keeps 0.03928.
**Approved**: pending

**Decision**: `isDark` is `relativeLuminance < 0.5`, and `hexStringRGB` is lower-case with no alpha.
**Rationale**: The 0.5 cut is the source's classifier for theme appearance (`ITermColorsParser` uses it to pick dark or light) and does not match its own "can host light text" comment for mid tones (see the open question on `is-dark-contract`). The lower-case six-digit form matches the terminal palette's color string, per the doc comment.
**Approved**: pending

