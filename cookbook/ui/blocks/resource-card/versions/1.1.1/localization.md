
Not applicable: ResourceCard renders content passed in via props (title, identifier, description, meta); it does not provide built-in localization. All text content is supplied by the parent and should be pre-localized. Note that the card's own layout is not locale-aware: **left-aligned-text** hardcodes `text-left` rather than the logical `text-start`, so the card does not mirror for right-to-left locales (see the `rtl-layout-support` compliance status below).

