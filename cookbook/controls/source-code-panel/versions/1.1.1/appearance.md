
- **Container**: Root div with class `scp-root`
- **Header**: Optional header element with class `scp-header`, displays only when filename or showCopy is true
- **Filename/Language span**: Class `scp-filename`, displays filename or language code
- **Copy button**: Class `scp-copy`, type="button", displays "Copy" or "Copied"
- **Body container**: Div with class `scp-body`, contains highlighted code or fallback
- **Highlighted code**: Div with class `scp-shiki`, receives Shiki-generated HTML
- **Fallback code**: `<pre>` with class `scp-fallback`, contains `<code>` child with plain text; may have `aria-busy` attribute during loading
- **Custom className**: Appended to root after `scp-root` if provided
- **Max height**: Applied as inline `max-height` CSS on body container if maxHeight prop is provided
- **Font**: Shiki theme controls font rendering in highlighted code; fallback uses browser default monospace
- **Colors**: Shiki theme controls syntax highlighting colors; fallback text color follows default foreground

