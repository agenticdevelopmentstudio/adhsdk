
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | passed | Accessibility |
| [adc.check.accessibility.keyboard-navigable](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/56755f54-b31f-59aa-a77d-eeb0cd87731a) | passed | Accessibility |
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.plural-forms](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d24616b8-d1af-593d-ba01-f51ee4a91ea4) | failed | Internationalization |
| [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d) | partial | Internationalization |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | passed | Best Practices |

Statuses rest on the source: `aria-label`s and the `<nav>`/`<ol>`/`<li>`/`<button>` semantics support screen readers and keyboard use directly; `text-apt-gold`/`text-apt-text-muted` are opaque design tokens whose actual contrast the source cannot confirm, and `text-xs` is a rem-based Tailwind class that likely scales with type-size settings but the source does not prove it; the hardcoded English strings (`"Choose…"`, `"Type a …"`, etc.) and the binary `path`/`paths` construction are not externalized or locale-aware, and the flex/gap layout shows no RTL-specific handling; `category-field.tsx` composes `Field`/`Combobox`/`EntityChooser`/`CategoryRenameDialog` and delegates trail-walking to the `categoryTrails` helper in `category-tree`, keeping its own file to composition and event wiring (separation-of-concerns); and `categoryField.test.tsx` plus `categoryTree.test.ts` assert the combobox/browser/rename wiring and the trail-walking helper with meaningful assertions (unit-test-coverage).

