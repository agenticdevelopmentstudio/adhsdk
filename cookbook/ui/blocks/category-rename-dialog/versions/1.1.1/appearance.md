
- **Corner radius**: Deferred to Dialog component implementation.
- **Padding**: Input field uses standard form spacing; error text is displayed inline below the input.
- **Font**: Uses system default input font; error text uses a distinct error-colored variant.
- **Background**: Dialog content uses light/dark mode theme from Dialog component.
- **Foreground/Text**: Input text and dialog content use the `apt-text` foreground token, which resolves per active theme rather than a literal black/white value; error text uses the `apt-red` destructive/error token.
- **Border**: Input field uses standard form input border; dialog has no explicit border.
- **Shadow**: Dialog elevation/shadow deferred to Dialog component implementation.
- **Min/Max size**: Dialog content uses the `max-w-sm` utility — exactly 384px (24rem), not an approximation.

