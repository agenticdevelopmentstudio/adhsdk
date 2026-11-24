
| State | Appearance change |
|-------|------------------|
| Default | Code is displayed with syntax highlighting applied or fallback `<pre><code>` if highlight pending |
| Copy button: "Copy" | Button text displays "Copy" |
| Copy button: "Copied" | Button text displays "Copied" for 1200ms after successful copy |
| Loading | Fallback `<pre><code>` renders with `aria-busy="true"` |
| Error (highlight failed) | Fallback `<pre><code>` renders without `aria-busy` |
| Hidden header | Header not rendered when both filename is falsy and showCopy is false |

