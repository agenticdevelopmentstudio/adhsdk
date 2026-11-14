
- **render-labelled-trigger**: The control MUST render a single `Button`
  trigger whose accessible name is `Markdown quick reference`, regardless of the
  visible trigger text.
- **start-closed**: The control MUST NOT render the reference content until
  the trigger is activated (the popover starts closed).
- **open-on-trigger**: The control MUST open the popover and reveal the
  reference content when the trigger is activated (click or keyboard).
- **list-common-syntax**: The open popover MUST list, at minimum, headings,
  bold, italic, inline code, fenced code block, bullet list, numbered list,
  link, and blockquote — each as a label paired with its literal markdown
  snippet.
- **dismiss-on-escape**: The control MUST close the popover when Escape is
  pressed while it is open.
- **dismiss-on-outside-click**: The control MUST close the popover when a
  pointer interaction occurs outside it.
- **restore-focus**: The control MUST return focus to the trigger when the
  popover closes.
- **honor-custom-trigger-label**: The control MUST render `triggerLabel` as
  the visible trigger text while keeping the fixed `Markdown quick reference`
  accessible name.

