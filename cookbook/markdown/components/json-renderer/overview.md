
A client React component that shows a stored JSON document, or a JSON Lines file, laid out for reading: two-space indents, one record after another, in the same code-block styling as a fenced json block rendered by `MarkdownRenderer`. Text that is neither JSON nor JSON Lines is shown exactly as written under a one-line note saying so, never silently reformatted. Documents larger than 512 KiB of characters skip syntax colouring so the page does not stall. Use it for a tool pane or file viewer that holds raw JSON text, such as an agent trajectory.

