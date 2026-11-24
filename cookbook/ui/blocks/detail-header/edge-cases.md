
- **Two claimants of a kind**: The later claimant holds the slot and the earlier renders nothing. See dh-007.
- **Closing pane**: When the claimant that holds a slot unmounts, the slot returns to the previous claimant, not to the fallback, as long as one remains. See dh-008.
- **Claimant mounted before the slot exists**: The slot is state, not a ref, so the provider re-renders when the slot element mounts and the portal then draws. See dh-019.
- **Outside any provider**: Portals render inline and the row draws disabled buttons; nothing throws. See dh-011 and dh-013.
- **No title**: An empty flexible spacer keeps the slots on the far right. See dh-016.
- **Empty actions**: Undefined, null and false draw no box; the number 0 and the empty string are not excluded by the check and draw an empty or text box.
- **Fallback help is null**: `fallbackHelp` of null or undefined falls through to the disabled help button, because the fallback uses nullish coalescing.
- **Unstable `actions` or `fallbackHelp`**: Both are in the provider's state memo, so a new element each render republishes the context to every consumer each render; hosts that care should keep them stable.
- **Same id claimed twice**: A repeated claim or release is a no-op and causes no render. See dh-020.
- **Concurrent access**: Claims are held in React state and updated by a functional update, so simultaneous claims and releases within one commit are applied in order and none is lost.
- **Error states and offline**: Not applicable: the block makes no network or storage calls; a claimed control's own errors belong to its claimant.

