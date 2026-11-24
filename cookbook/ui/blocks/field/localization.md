
Field renders whatever caption, hint, and error text the caller provides — the
copy itself is localized by the caller and the form owning the field, not by
`Field`. The one thing `Field` itself does to that text is the caption's
uppercase treatment (`fieldCaptionClass`'s `uppercase`, and the equivalent
native transform on each platform). Casing is a locale-sensitive operation
(for example the German `ß`/`SS` expansion, or Turkish dotted/dotless `i`), so
that transform MUST use the user's current locale on every platform (**uppercase-caption-locale**) — never an
invariant- or culture-insensitive uppercase call — even though the transform
itself is applied by `Field`, not the caller. On the web, CSS `text-transform:
uppercase` follows the element's `lang` attribute, not the browser's locale, so
the host MUST set `lang` correctly on the document or an ancestor of `Field`.

