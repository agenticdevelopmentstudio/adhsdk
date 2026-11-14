
- **Overlay background**: Black with 70% opacity (`bg-black/70`)
- **Overlay layout**: Fixed position, full screen, flex row centered horizontally and top-aligned vertically, with auto scroll for tall content (`fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-6`)
- **Dialog container**: Rounded corners (12px), border, surface background, shadow, relative positioning, max width 3xl (48rem), top-aligned within the overlay (not vertically centered) with 32px (`my-8`) margin above and below so it can scroll alongside tall form content
- **Dialog padding**: 24px (p-6)
- **Header spacing**: Flex row, space-between alignment, 16px gap (gap-4) between heading and close button
- **Heading**: h2 element, base font size (16px), font-semibold weight, text color
- **Form section**: Rendered via `renderForm` callback
- **Error message**: No dedicated slot in this component; the `error` string is passed to `renderForm` as its third argument, and the callback owns rendering and positioning it
- **Footer**: Flex row, justify-end alignment, 8px gap (gap-2) between Cancel and Save buttons
- **Buttons**: Cancel uses ghost variant at default size; Save uses the default (primary) variant at default size; the close (×) button uses ghost variant at `icon-sm` size (28×28px, `size-7`)

