
1. **Decision**: Debounce the preview render by 300ms after the last content change.
   **Rationale**: `MarkdownRenderer` re-runs the full unified + Shiki syntax-highlighting pipeline on every content change; running that per keystroke would run the pipeline once per character instead of once per pause. 300ms is roughly eighteen frames at 60fps — long enough that the pipeline doesn't run on every character, short enough that the preview still feels responsive. The editor itself gives the author immediate visual feedback; the preview catches up once they pause or stop typing.
   **Approved**: pending

2. **Decision**: Use a per-platform split-layout breakpoint below which each pane would be too narrow for readable prose — 700pt on Apple, and web's inherited `(min-width: 64rem)` (1024px) `SplitViewControl` breakpoint, rather than a single 700-unit number on both platforms.
   **Rationale**: Below the breakpoint, a split view leaves each pane too narrow for readable prose (roughly 40–50 characters per column at typical font sizes), so tabbed layout is enforced instead of a technically-present-but-unusable split. The web breakpoint is `SplitViewControl`'s own shared threshold rather than a value this component chose independently, so it does not match Apple's 700pt figure.
   **Approved**: pending

3. **Decision**: On a layout change, restore the user's last deliberately chosen mode if it's still available in the new set; otherwise fall back to Edit.
   **Rationale**: This honors user intent — choosing Preview on a narrow viewport and then widening the window keeps Preview active rather than defaulting to Split — while giving one deterministic outcome (Edit) for the case where the preferred mode isn't available. Only an explicit user choice (clicking a toggle) updates the preference; a layout-driven fallback does not, which prevents mode "drift" across resizes. See **clamp-mode-to-available-set** and **preserve-layout-preference**.
   **Approved**: pending

4. **Decision**: Explicitly set `aria-live="off"` on the preview pane's content region.
   **Rationale**: Announcing the entire rendered document every 300ms would create constant, overwhelming screen-reader noise. Screen-reader users instead navigate the preview's content structure (headings, links, etc.) on demand, using standard document navigation techniques.
   **Approved**: pending

5. **Decision**: Render the optional `header` outside both panes, above the control strip.
   **Rationale**: Document identity fields (title, slug, categories, etc.) belong to the document, not to a particular view of its body.
   **Approved**: pending

6. **Decision**: Position the optional `overlay` inside the editor pane's positioning context.
   **Rationale**: This keeps a typeahead listbox or similar affordance positioned against the textarea, hides it automatically when the editor pane is hidden in tabbed mode, and scopes its z-order to the editor so it never overlaps the preview pane in split mode.
   **Approved**: pending

7. **Decision**: Default to fill-mode true, unlike the underlying editor component's own fill-mode-false default.
   **Rationale**: Both layouts (split and tabbed) are designed to fill their container height by construction; a fill-false override exists for hosts that need fixed-height sizing (e.g., the notebook's NoteFields component).
   **Approved**: pending

8. **Decision**: Apply a 14rem (224px) minimum height floor to the panes row in fill mode.
   **Rationale**: Without a floor, a container shorter than the editor's minimum needs would let the panes shrink to zero height, and all content would overflow. 14rem leaves the textarea roughly 10rem after the label and toolbar take their share — a body that's actually usable for writing. In fill-false mode, sizing follows the textarea's row count instead, so no floor is needed.
   **Approved**: pending

9. **Decision**: Guard programmatic content updates against no-op re-renders.
   **Rationale**: Prevents infinite loops when a host echoes the current value back to the component; a change to a genuinely different string still flows through and triggers the debounce as normal. See **skip-redundant-content-update**.
   **Approved**: pending

