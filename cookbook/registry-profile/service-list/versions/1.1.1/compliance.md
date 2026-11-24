
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.semantic-markup](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/1569c175-c689-55bc-a13e-a08bdb7e91c6) | passed | Accessibility |
| [adc.check.accessibility.dynamic-type-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f3dbcab7-ac3d-5043-9379-0da07ceaa32b) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | failed | Internationalization |
| [adc.check.internationalization.locale-aware-formatting](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/c87ff1f1-9d77-5167-b0c4-f13f2aae5acb) | partial | Internationalization |
| [adc.check.user-safety.content-moderation](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f1e3ffdc-3e47-54d5-82c8-a1c266284959) | partial | User Safety |
| [adc.check.user-safety.reporting-mechanism](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/d7127c04-8ad0-5cdd-82f8-74e851f234b7) | partial | User Safety |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

Statuses rest on `ServiceList.tsx`: it renders only semantic HTML tags with no inline color or font-size overrides (semantic-markup passes; dynamic-type-support and contrast-ratio are partial because actual scaling and contrast depend on the CSS classes it references, not shown here); it hardcodes the "Services" heading and every pricing suffix as literal English strings and hardcodes the `en-US` locale inside `Intl.NumberFormat` (string-externalization fails; locale-aware-formatting is partial since it uses a locale-aware API but with a fixed locale); and it renders whatever `title`/`description` text it is given, submitted by registry members, with no moderation step or reporting affordance of its own (content-moderation and reporting-mechanism are partial, since either could be handled upstream of this component). `separation-of-concerns` passes because the `priceText` formatting logic is factored into its own pure function, separate from the rendering, and `unit-test-coverage` is partial because `ServiceList` has no test of its own — it is exercised only indirectly, through its parent `RegistryProfile`, in `RegistryProfile.test.tsx`'s empty-services and priced-service cases.

