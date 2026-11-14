
Component renders as a semantic HTML link element (`<a>`), which is inherently keyboard-accessible (Tab to focus, Enter to activate) and screen-reader-accessible. Link text is provided by the `children` prop; no additional `aria-label` or `aria-labelledby` attribute is applied by the component. If the link text is ambiguous, missing, or not descriptive, the parent code is responsible for providing accessible text via `children`.

