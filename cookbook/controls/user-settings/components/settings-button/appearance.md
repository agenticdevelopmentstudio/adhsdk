
The component defines no inline styles. Appearance comes from the `aws-button` and `aws-button--{variant}` rules in the package stylesheet (`user-settings/styles.css`), and the library ships the three variant styles. These are the values:

- **Base (`aws-button`)**: inherited font family at `font-size: 0.875rem`; padding `0.5rem 0.95rem`; corner radius `0.375rem`; `1px` border, transparent unless the variant sets a color; pointer cursor; transitions on `filter`, `background` and `border-color` of 80ms.
- **Primary**: background and border `--aws-accent`; text `--aws-bg`.
- **Secondary**: background `--aws-surface`; border `--aws-border`; text inherited.
- **Destructive**: background `--aws-red-dim`; border and text `--aws-red`.
- **Shadow**: none.
- **Size**: about 35px tall at a 16px root font size (0.875rem text at normal line height, 0.5rem padding top and bottom, 1px border); width follows the content.
