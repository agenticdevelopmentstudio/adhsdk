The component has three user-facing strings of its own, each used as an
accessory button's accessibility label and tooltip: "Copy" (the copy
button), and "Show" and "Hide" (the eye button, while obscured and while
shown). They are localizable strings; the source currently sets them as
English literals, not through a localization lookup. The row's title comes
from the view model's title, a value the caller provides and localizes.
