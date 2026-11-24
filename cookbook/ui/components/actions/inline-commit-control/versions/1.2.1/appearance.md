
- The control is trailing-aligned in the row/element it annotates, composed
  entirely from the shared `Button` (`ghost` / `destructive-ghost`,
  `icon-sm`) — no bespoke buttons.
- ✓ uses the gold primary accent (`apt-gold`), ✕ the muted text tone
  (`apt-text-muted`), the armed trash the destructive red tone.
- The idle trash is invisible (`opacity-0`) until the hover scope is hovered
  or the button is focused; the reveal is an opacity transition.
- Armed-delete content is dimmed to 50% opacity with a strikethrough
  (`inlineCommitDeletingClass = "opacity-50 line-through"`).
- `InlineEditableText` renders as plain text (transparent field shell) that
  regains the field border on hover and the standard gold focus ring while
  editing.

