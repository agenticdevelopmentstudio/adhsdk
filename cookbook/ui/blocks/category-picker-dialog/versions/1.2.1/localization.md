
None: `title`, `description`, `confirmLabel`, and `rootLabel` are host-supplied
strings, so the host controls their translation. But the source also carries its
own hardcoded English strings that are not run through any i18n mechanism: the
filter's placeholder ("Filter categories…") and `aria-label` ("Filter
categories"), and the two empty-state messages ("No categories yet." and `No
categories match "{filter}".`).

