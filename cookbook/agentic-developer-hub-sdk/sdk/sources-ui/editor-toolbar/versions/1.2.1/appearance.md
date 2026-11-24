
- **Height**: 44pt (iOS), 32pt (macOS)
- **Layout**: Horizontal stack
- **Spacing**: 8pt between items
- **Padding**: 4pt vertical, 8pt horizontal (applied to stack edges)
- **Background**: Semantic palette `elevatedSurface` color
- **Mode control width**: Intrinsic (segment widths determined by mode label text)
- **Button size**: System button size (intrinsic height constrained by stack alignment to center)
- **Mode control segments**: System segmented control styling (texturedRounded on macOS)
- **Buttons**: System button styling (rounded bezel on macOS, system type on iOS)
- **Spacer**: Flexible space between mode control and buttons, expands to fill available width
- **Dynamic Type / larger accessibility text**: The bar's height (44pt/32pt) is fixed and does not grow with the system text-size setting; only the button and segment titles use system fonts that scale with the content size category. At larger accessibility sizes the labels are what adapts — by shrinking within their intrinsic sizing or, at extreme sizes, truncating — while the bar itself keeps its fixed height. Neither implementation adjusts the bar's height for content size category.

