
- **render-section-per-phase**: The block MUST render one `<section>` per phase, headed by the phase title.
- **render-phase-count**: Each phase heading MUST show "`{done} / {total}`" computed by `countProgress` over that phase's items only, so stopped items are not in the total.
- **render-row-per-item**: Each phase MUST render a `<ul>` with one `<li>` per item showing the item text.
- **render-status-icon**: Each row MUST show a distinct icon per status (done, in progress, to do, stopped), marked `aria-hidden`.
- **name-status**: Each row MUST carry its status name ("done", "in progress", "to do", "stopped") as visually hidden text.
- **mute-stopped**: A stopped item's text MUST be struck through and use the dim text token.
- **forward-host-attributes**: The block MUST forward `className` and remaining host attributes to its root element.
