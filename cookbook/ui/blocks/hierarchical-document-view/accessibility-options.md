
| Option | Behavior |
|--------|----------|
| Reduce Motion | Not handled: `DocNav`'s section chevron and `ViewSourceDisclosure`'s chevron both use `transition-transform` unconditionally, and the smooth-scrolling in `NavHeadings` and `DocTableOfContents` (`scrollIntoView({ behavior: "smooth" })`) runs regardless of `prefers-reduced-motion`; the source contains no such check. |
| Increase Contrast | Depends on the `--color-*` design tokens; the components themselves do no `prefers-contrast` handling. |
| Differentiate Without Color | `aria-current="page"` on the active nav link and breadcrumb, `aria-expanded` on the section/disclosure toggles, and the chevron's rotation all carry state independent of color, alongside the color-only accent bar and highlight. |

