
- **Role/trait**: Trigger MUST be a button (delegated to AccordionPrimitive.Trigger). Panel MUST be a region (delegated to AccordionPrimitive.Panel).
- **Label requirements**: Trigger child content (text) serves as the accessible name for the accordion section. Screen readers announce this text when the trigger is focused.
- **State announcement**: The aria-expanded attribute on the trigger MUST reflect the panel's open/closed state and MUST be announced by screen readers.
- **Keyboard navigation**: Trigger MUST be keyboard accessible and respond to Enter and Space keys to toggle the panel (delegated to AccordionPrimitive.Trigger).
- **Minimum tap target**: Trigger touch target MUST be at least 24×24px (WCAG 2.2 SC 2.5.8, Level AA) — the level this ingredient commits to. Actual implementation depends on container padding and layout; current CSS (`py-3` plus `text-sm`'s line height) yields roughly a 44px-tall target, which also happens to satisfy the stricter 44×44px AAA target (WCAG 2.1 SC 2.5.5), though width is content-dependent since the trigger is `flex-1`.

