
`PartnerTurnQueue` holds the inbound events waiting for the partner's next turn, oldest first. An event whose `PartnerInbound.coalescingKey` matches one already queued replaces it in place, so a burst of identical timer ticks or idle notices becomes one entry holding the newest payload at the original position. A second entry point puts a notice ahead of everything queued without coalescing. It is a plain value type with no storage, no I/O and no timers; its owner, the partner controller, decides when to take the next event and starts a turn with it.

