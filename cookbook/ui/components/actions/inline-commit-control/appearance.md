
- The control is trailing-aligned in the row/element it annotates, composed
  entirely from the shared `Button` (`ghost` / `destructive-ghost`,
  `icon-sm`) — no bespoke buttons.
- ✓ uses the primary accent color, ✕ the muted text tone, the armed trash the
  destructive tone. The web tokens are named in the React/Web Platform Note.
- The idle trash is invisible (`opacity-0`) until the hover scope is hovered
  or the button is focused; the reveal is an opacity transition.
- Armed-delete content is dimmed to 50% opacity with a strikethrough
  (`inlineCommitDeletingClass = "opacity-50 line-through"`).
- `InlineEditableText` renders as plain text (transparent field shell) that
  regains the field border on hover and the standard accent focus ring while
  editing.

