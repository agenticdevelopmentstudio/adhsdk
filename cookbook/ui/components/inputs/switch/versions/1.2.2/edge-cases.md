
- **Rapid clicks**: Each completed click or tap MUST toggle the state exactly once; see switch-014. Rapid successive clicks are not debounced or coalesced — N completed clicks produce N toggles.
- **Disabled + controlled**: A controlled Switch with `disabled={true}` and an external prop change MUST reflect the new prop value, including its color/position transition, even though user interaction is blocked; see switch-010.
- **Keyboard navigation in focus**: When focused via Tab, pressing Space (optionally Enter) MUST toggle the checked state if not disabled; see switch-011.
- **No label provided**: If the consumer does not provide an associated label or aria-label, the switch will lack semantic meaning for assistive technology; this is a consumer responsibility, not a component defect.
- **Small touch target on mobile**: The 36×20px dimensions are smaller than the 44×44pt touch-friendly target on mobile platforms; consumers SHOULD wrap the Switch or increase the interactive area.

