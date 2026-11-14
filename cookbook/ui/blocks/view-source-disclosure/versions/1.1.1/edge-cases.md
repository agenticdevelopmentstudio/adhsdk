
- **Empty source string**: If `source=""`, the component MUST render an empty `<pre>` element; the button remains functional and toggles the empty panel open/close.
- **Very long source**: If `source` contains many thousands of lines, all MUST be rendered in the `<pre>` without truncation or lazy loading; scrolling performance depends on browser capability.
- **Whitespace-only source**: If `source` contains only whitespace (spaces, tabs, newlines), it MUST be rendered exactly as provided within the `<pre>`.
- **Special characters in label**: If `label` is a string containing HTML special characters (e.g., `"<test>"`), it MUST be rendered as text, not parsed as HTML.
- **ReactNode label**: If `label` is a ReactNode (e.g., a component), it MUST be rendered as such within the button.
- **Multiple instances**: Multiple ViewSourceDisclosure components on the same page MUST each maintain independent open/close state via their own `useState` hook and `useId` hook for unique panel IDs.
- **State after unmount/remount**: The component is uncontrolled; if unmounted and remounted, it resets to `defaultOpen` state.

