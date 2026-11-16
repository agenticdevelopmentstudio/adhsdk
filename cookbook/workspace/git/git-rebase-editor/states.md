
- **Valid**: the plan can run; Start Rebase is enabled with no tooltip.
- **Invalid**: every entry dropped, the first kept entry a squash or fixup, or a reword with an empty message; Start Rebase is disabled with the reason as its tooltip.
- **Finished**: after Start Rebase or Cancel, `onFinish` is gone and the buttons do nothing more.
