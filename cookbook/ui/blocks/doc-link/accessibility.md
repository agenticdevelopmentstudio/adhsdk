
- **Role**: The component renders a native HTML anchor element, which has an implicit link role in assistive technologies — but only while `href` is present; see the **missing-to-prop** edge case for the case where it is not.
- **Label**: Link text from `children` serves as the accessible label when non-empty; the caller is responsible for providing non-empty `children` or an `aria-label`; see the **null-or-undefined-children** edge case for the empty case.
- **Focus**: The anchor element receives keyboard focus by default in all browsers, provided `href` is set.
- **Keyboard navigation**: The link is keyboard-navigable via the Enter key following native anchor behavior (source: native `<a>` element).

